from flask import Flask, render_template, request, jsonify, send_file
import subprocess
import json
import os
import datetime
import time
import threading
from pathlib import Path

app = Flask(__name__)

# Configurações
ZAP_HOME = "/zap"
REPORTS_DIR = "/app/reports"
ZAP_PORT = 8090
ZAP_API_KEY = "zap-api-key-123"

# Criar diretórios necessários
Path(REPORTS_DIR).mkdir(parents=True, exist_ok=True)

# Status global do ZAP
zap_status = {"running": False, "scanning": False}

def start_zap_daemon():
    """Iniciar ZAP em modo daemon"""
    global zap_status
    try:
        cmd = [
            "/zap/zap.sh", "-daemon",
            "-host", "0.0.0.0",
            "-port", str(ZAP_PORT),
            "-config", f"api.key={ZAP_API_KEY}",
            "-config", "api.addrs.addr.name=.*",
            "-config", "api.addrs.addr.regex=true"
        ]
        
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(10)  # Aguardar inicialização
        zap_status["running"] = True
        print(f"✅ ZAP daemon started on port {ZAP_PORT}")
    except Exception as e:
        print(f"❌ Failed to start ZAP daemon: {e}")

# Iniciar ZAP quando o app iniciar
threading.Thread(target=start_zap_daemon, daemon=True).start()

@app.route("/")
def dashboard():
    """Dashboard principal com lista de scans"""
    reports = []
    try:
        for file in os.listdir(REPORTS_DIR):
            if file.endswith('.json'):
                file_path = os.path.join(REPORTS_DIR, file)
                with open(file_path, 'r') as f:
                    try:
                        data = json.load(f)
                        reports.append({
                            'filename': file,
                            'target': data.get('target', 'Unknown'),
                            'timestamp': datetime.datetime.fromtimestamp(os.path.getmtime(file_path)),
                            'alerts': len(data.get('site', [{}])[0].get('alerts', [])) if data.get('site') else 0,
                            'high_alerts': len([a for a in data.get('site', [{}])[0].get('alerts', []) if a.get('riskdesc', '').startswith('High')])
                        })
                    except json.JSONDecodeError:
                        continue
    except Exception as e:
        print(f"Error reading reports: {e}")
    
    return render_template('zap_dashboard.html', reports=reports, zap_status=zap_status)

@app.route("/scan", methods=['POST'])
def scan_target():
    """Endpoint para escanear uma aplicação web"""
    global zap_status
    
    if not zap_status["running"]:
        return jsonify({'error': 'ZAP daemon not running'}), 500
        
    if zap_status["scanning"]:
        return jsonify({'error': 'Another scan is already running'}), 400
    
    data = request.get_json()
    target_url = data.get('target', '')
    scan_type = data.get('scan_type', 'quick')  # quick, full, api
    
    if not target_url:
        return jsonify({'error': 'Target URL required'}), 400
    
    try:
        zap_status["scanning"] = True
        
        # Nome do arquivo de report
        safe_target_name = target_url.replace('://', '_').replace('/', '_').replace(':', '_')
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        report_file = f"{REPORTS_DIR}/zap_{safe_target_name}_{timestamp}.json"
        
        # Executar scan do ZAP em thread separada
        def run_zap_scan():
            try:
                # Spider scan
                spider_cmd = [
                    'curl', '-s',
                    f'http://localhost:{ZAP_PORT}/JSON/spider/action/scan/',
                    '-d', f'apikey={ZAP_API_KEY}',
                    '-d', f'url={target_url}'
                ]
                subprocess.run(spider_cmd, timeout=30)
                
                # Aguardar spider
                time.sleep(30)
                
                # Active scan (se não for quick)
                if scan_type != 'quick':
                    active_cmd = [
                        'curl', '-s',
                        f'http://localhost:{ZAP_PORT}/JSON/ascan/action/scan/',
                        '-d', f'apikey={ZAP_API_KEY}',
                        '-d', f'url={target_url}'
                    ]
                    subprocess.run(active_cmd, timeout=30)
                    time.sleep(60)  # Active scan demora mais
                
                # Gerar relatório
                report_cmd = [
                    'curl', '-s',
                    f'http://localhost:{ZAP_PORT}/JSON/core/view/alerts/',
                    '-d', f'apikey={ZAP_API_KEY}',
                    '-o', report_file
                ]
                subprocess.run(report_cmd, timeout=30)
                
                # Adicionar metadados ao relatório
                with open(report_file, 'r') as f:
                    report_data = json.load(f)
                
                report_data['target'] = target_url
                report_data['scan_type'] = scan_type
                report_data['timestamp'] = datetime.datetime.now().isoformat()
                
                with open(report_file, 'w') as f:
                    json.dump(report_data, f, indent=2)
                
            except Exception as e:
                print(f"Scan error: {e}")
            finally:
                zap_status["scanning"] = False
        
        threading.Thread(target=run_zap_scan, daemon=True).start()
        
        return jsonify({
            'success': True,
            'message': f'Scan started for {target_url}',
            'scan_type': scan_type,
            'report_file': os.path.basename(report_file)
        })
        
    except Exception as e:
        zap_status["scanning"] = False
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route("/report/<filename>")
def view_report(filename):
    """Visualizar um report específico"""
    try:
        file_path = os.path.join(REPORTS_DIR, filename)
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # Processar alertas para exibição
        alerts = []
        if data.get('alerts'):
            for alert in data.get('alerts', []):
                alerts.append({
                    'name': alert.get('name', 'Unknown'),
                    'risk': alert.get('riskdesc', 'Unknown'),
                    'confidence': alert.get('confidence', 'Unknown'),
                    'description': alert.get('description', 'N/A')[:300] + '...' if alert.get('description', '') else 'N/A',
                    'solution': alert.get('solution', 'N/A')[:200] + '...' if alert.get('solution', '') else 'N/A',
                    'instances': len(alert.get('instances', []))
                })
        
        return render_template('zap_report.html', 
                             target=data.get('target', 'Unknown'),
                             alerts=alerts,
                             filename=filename,
                             scan_type=data.get('scan_type', 'unknown'))
                             
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'owasp-zap-dashboard',
        'version': '1.0',
        'zap_running': zap_status["running"],
        'zap_scanning': zap_status["scanning"]
    })

@app.route("/status")
def status():
    """Status do ZAP"""
    return jsonify(zap_status)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
