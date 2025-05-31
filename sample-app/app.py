from flask import Flask, jsonify, render_template_string, request
import os
import sys
import platform
import datetime

app = Flask(__name__)

# Porta configurável via variável de ambiente
PORT = int(os.environ.get('PORT', 5000))
VERSION = os.environ.get('APP_VERSION', '1.24')

# Template HTML para uma interface mais amigável
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thunderbolts Sample App Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f7fa;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 20px;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #4a6ee0;
        }
        .version {
            background-color: #4a6ee0;
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 14px;
        }
        .status {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 4px;
            font-weight: bold;
        }
        .status.healthy {
            background-color: #e3fcef;
            color: #0d8050;
        }
        .status.unhealthy {
            background-color: #ffe2e2;
            color: #d13212;
        }
        .card {
            background-color: #f9f9f9;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 15px;
        }
        .card h3 {
            margin-top: 0;
            border-bottom: 1px solid #eee;
            padding-bottom: 8px;
            color: #555;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .endpoints {
            margin-top: 20px;
        }
        .endpoint {
            background-color: #f0f4ff;
            border-left: 4px solid #4a6ee0;
            padding: 10px;
            margin-bottom: 10px;
            font-family: monospace;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #888;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">Sample App</div>
            <div class="version">v{{ version }}</div>
        </div>
        
        <div class="card">
            <h3>Status</h3>
            <div class="status healthy">● Healthy</div>
            <p>The application is running normally on port {{ port }}</p>
        </div>
        
        <div class="info-grid">
            <div class="card">
                <h3>Environment</h3>
                <p><strong>Mode:</strong> {{ environment }}</p>
                <p><strong>Server Time:</strong> {{ server_time }}</p>
                <p><strong>Host:</strong> {{ hostname }}</p>
            </div>
            
            <div class="card">
                <h3>System</h3>
                <p><strong>Python:</strong> {{ python_version }}</p>
                <p><strong>Platform:</strong> {{ platform }}</p>
                <p><strong>Client IP:</strong> {{ client_ip }}</p>
            </div>
        </div>
        
        <div class="endpoints">
            <h3>API Endpoints</h3>
            <div class="endpoint">GET /health - Health check endpoint</div>
            <div class="endpoint">GET /info - Application information</div>
            <div class="endpoint">GET /api - JSON API data</div>
        </div>
        
        <div class="footer">
            Running on Flask | Sample CI/CD Pipeline Demo | © 2025
        </div>
    </div>
</body>
</html>
'''

@app.route('/')
def home():
    return render_template_string(HTML_TEMPLATE, 
        version=VERSION,
        port=PORT,
        environment=os.environ.get('ENVIRONMENT', 'development'),
        python_version=sys.version.split()[0],
        platform=platform.platform(),
        hostname=platform.node(),
        server_time=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        client_ip=request.remote_addr
    )

@app.route('/api')
def api():
    return jsonify({
        'message': 'Hello from Sample App!',
        'version': VERSION,
        'port': PORT,
        'python_version': sys.version
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'version': VERSION
    }), 200

@app.route('/info')
def info():
    return jsonify({
        'app_name': 'GS DevSecOps CI/CD com Terraform, Azure, Jenkins Pipeline, SonarQube, Trivy, OWASP-ZAP, Prometheus e Grafana.',
        'version': VERSION,
        'environment': os.environ.get('ENVIRONMENT', 'development'),
        'port': PORT
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=False)