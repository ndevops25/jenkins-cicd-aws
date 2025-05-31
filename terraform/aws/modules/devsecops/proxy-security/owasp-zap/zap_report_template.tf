# OWASP ZAP Security Testing Module
# Implementa OWASP ZAP com dashboard web para testes de segurança de aplicações web

# Template HTML para relatórios ZAP
resource "local_file" "zap_report_template" {
  content = <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🕷️ ZAP Security Report - {{ target }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); color: white; padding: 2rem; text-align: center; }
        .container { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
        .card { background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin: 1rem 0; padding: 1.5rem; }
        .alert-item { border-left: 4px solid #ddd; margin: 1rem 0; padding: 1rem; background: #f9f9f9; }
        .risk-High { border-left-color: #e74c3c; background: #ffeaea; }
        .risk-Medium { border-left-color: #f39c12; background: #fff8e1; }
        .risk-Low { border-left-color: #27ae60; background: #e8f5e8; }
        .risk-Informational { border-left-color: #3498db; background: #e3f2fd; }
        .risk-badge { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 4px; color: white; font-size: 0.8rem; margin-right: 0.5rem; }
        .risk-High { background: #e74c3c; }
        .risk-Medium { background: #f39c12; }
        .risk-Low { background: #27ae60; }
        .risk-Informational { background: #3498db; }
        .btn { padding: 0.75rem 1.5rem; background: #e74c3c; color: white; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; display: inline-block; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; text-align: center; }
        .stat { padding: 1rem; background: white; border-radius: 8px; }
        .stat-number { font-size: 1.5rem; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🕷️ Security Report</h1>
        <h2>{{ target }}</h2>
        <p>Scan Type: {{ scan_type|title }}</p>
        <a href="/" class="btn">⬅️ Back to Dashboard</a>
    </div>
    
    <div class="container">
        <div class="card">
            <h2>📊 Security Summary</h2>
            <div class="stats">
                {% set risk_counts = {} %}
                {% for alert in alerts %}
                    {% set risk = alert.risk.split(' ')[0] %}
                    {% set _ = risk_counts.update({risk: risk_counts.get(risk, 0) + 1}) %}
                {% endfor %}
                
                {% for risk in ['High', 'Medium', 'Low', 'Informational'] %}
                <div class="stat">
                    <div class="stat-number risk-{{ risk }}">{{ risk_counts.get(risk, 0) }}</div>
                    <div>{{ risk }} Risk</div>
                </div>
                {% endfor %}
                
                <div class="stat">
                    <div class="stat-number">{{ alerts|length }}</div>
                    <div>TOTAL ALERTS</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>🚨 Security Alerts ({{ alerts|length }})</h2>
            {% if alerts %}
                {% for alert in alerts %}
                {% set risk = alert.risk.split(' ')[0] %}
                <div class="alert-item risk-{{ risk }}">
                    <div>
                        <span class="risk-badge risk-{{ risk }}">{{ alert.risk }}</span>
                        <strong>{{ alert.name }}</strong>
                        <span style="color: #666;">({{ alert.instances }} instance{{ 's' if alert.instances != 1 else '' }})</span>
                    </div>
                    <p><strong>Confidence:</strong> {{ alert.confidence }}</p>
                    <p><strong>Description:</strong> {{ alert.description }}</p>
                    <p><strong>Solution:</strong> {{ alert.solution }}</p>
                </div>
                {% endfor %}
            {% else %}
                <p>✅ No security alerts found! This application appears to be secure.</p>
            {% endif %}
        </div>
    </div>
</body>
</html>
EOF

  filename = "${path.module}/temp_build/templates/zap_report.html"
}