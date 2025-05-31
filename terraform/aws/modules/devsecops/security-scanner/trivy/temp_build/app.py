from flask import Flask, render_template, request, jsonify
import subprocess
import json
import os
import datetime
from pathlib import Path

app = Flask(__name__)

# Configurações
TRIVY_CACHE_DIR = "/tmp/trivy-cache"
REPORTS_DIR = "/app/reports"

# Criar diretórios necessários
Path(TRIVY_CACHE_DIR).mkdir(parents=True, exist_ok=True)
Path(REPORTS_DIR).mkdir(parents=True, exist_ok=True)

@app.route("/")
def dashboard():
    """Dashboard principal com lista de scans"""
    reports = []
    try:
        for file in os.listdir(REPORTS_DIR):
            if file.endswith('.json'):
                file_path = os.path.join(REPORTS_DIR, file)
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    reports.append({
                        'filename': file,
                        'image': data.get('ArtifactName', 'Unknown'),
                        'timestamp': datetime.datetime.fromtimestamp(os.path.getmtime(file_path)),
                        'vulnerabilities': len(data.get('Results', [{}])[0].get('Vulnerabilities', [])) if data.get('Results') else 0
                    })
    except Exception as e:
        print(f"Error reading reports: {e}")
    
    return render_template('dashboard.html', reports=reports)

@app.route("/scan", methods=['POST'])
def scan_image():
    """Endpoint para escanear uma imagem"""
    data = request.get_json()
    image = data.get('image', '')
    
    if not image:
        return jsonify({'error': 'Image name required'}), 400
    
    try:
        # Nome do arquivo de report
        safe_image_name = image.replace('/', '_').replace(':', '_')
        report_file = f"{REPORTS_DIR}/{safe_image_name}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        # Executar scan do Trivy
        cmd = [
            'trivy', 'image',
            '--format', 'json',
            '--output', report_file,
            '--cache-dir', TRIVY_CACHE_DIR,
            image
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': f'Scan completed for {image}',
                'report_file': os.path.basename(report_file)
            })
        else:
            return jsonify({
                'success': False,
                'error': f'Trivy scan failed: {result.stderr}'
            }), 500
            
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': 'Scan timeout'}), 408
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route("/report/<filename>")
def view_report(filename):
    """Visualizar um report específico"""
    try:
        file_path = os.path.join(REPORTS_DIR, filename)
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # Processar dados para exibição
        vulnerabilities = []
        if data.get('Results'):
            for result in data.get('Results', []):
                for vuln in result.get('Vulnerabilities', []):
                    vulnerabilities.append({
                        'id': vuln.get('VulnerabilityID', 'N/A'),
                        'severity': vuln.get('Severity', 'UNKNOWN'),
                        'package': vuln.get('PkgName', 'N/A'),
                        'version': vuln.get('InstalledVersion', 'N/A'),
                        'fixed_version': vuln.get('FixedVersion', 'N/A'),
                        'title': vuln.get('Title', 'N/A'),
                        'description': vuln.get('Description', 'N/A')[:200] + '...' if vuln.get('Description', '') else 'N/A'
                    })
        
        return render_template('report.html', 
                             image=data.get('ArtifactName', 'Unknown'),
                             vulnerabilities=vulnerabilities,
                             filename=filename)
                             
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'trivy-dashboard',
        'version': '1.0'
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
