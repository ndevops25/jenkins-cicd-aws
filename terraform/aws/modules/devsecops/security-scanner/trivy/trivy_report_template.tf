# Trivy Security Scanner Module
# Implementa Trivy Server com dashboard web para visualização de vulnerabilidades

# Template HTML para visualização de reports
resource "local_file" "trivy_report_template" {
  content = <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🛡️ Trivy Report - {{ image }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; text-align: center; }
        .container { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
        .card { background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin: 1rem 0; padding: 1.5rem; }
        .vuln-item { border-left: 4px solid #ddd; margin: 1rem 0; padding: 1rem; background: #f9f9f9; }
        .severity-CRITICAL { border-left-color: #8b0000; background: #ffe6e6; }
        .severity-HIGH { border-left-color: #e74c3c; background: #ffeaea; }
        .severity-MEDIUM { border-left-color: #f39c12; background: #fff8e1; }
        .severity-LOW { border-left-color: #27ae60; background: #e8f5e8; }
        .severity-UNKNOWN { border-left-color: #95a5a6; background: #f0f0f0; }
        .severity-badge { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 4px; color: white; font-size: 0.8rem; margin-right: 0.5rem; }
        .btn { padding: 0.75rem 1.5rem; background: #667eea; color: white; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; display: inline-block; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; text-align: center; }
        .stat { padding: 1rem; background: white; border-radius: 8px; }
        .stat-number { font-size: 1.5rem; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Security Report</h1>
        <h2>{{ image }}</h2>
        <a href="/" class="btn">⬅️ Back to Dashboard</a>
    </div>
    
    <div class="container">
        <div class="card">
            <h2>📊 Summary</h2>
            <div class="stats">
                {% set severity_counts = {} %}
                {% for vuln in vulnerabilities %}
                    {% set _ = severity_counts.update({vuln.severity: severity_counts.get(vuln.severity, 0) + 1}) %}
                {% endfor %}
                
                {% for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'UNKNOWN'] %}
                <div class="stat">
                    <div class="stat-number">{{ severity_counts.get(severity, 0) }}</div>
                    <div>{{ severity }}</div>
                </div>
                {% endfor %}
                
                <div class="stat">
                    <div class="stat-number">{{ vulnerabilities|length }}</div>
                    <div>TOTAL</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>🚨 Vulnerabilities ({{ vulnerabilities|length }})</h2>
            {% if vulnerabilities %}
                {% for vuln in vulnerabilities %}
                <div class="vuln-item severity-{{ vuln.severity }}">
                    <div>
                        <span class="severity-badge severity-{{ vuln.severity }}">{{ vuln.severity }}</span>
                        <strong>{{ vuln.id }}</strong> - {{ vuln.title }}
                    </div>
                    <p><strong>Package:</strong> {{ vuln.package }} ({{ vuln.version }})</p>
                    {% if vuln.fixed_version != 'N/A' %}
                    <p><strong>Fixed Version:</strong> {{ vuln.fixed_version }}</p>
                    {% endif %}
                    <p><strong>Description:</strong> {{ vuln.description }}</p>
                </div>
                {% endfor %}
            {% else %}
                <p>✅ No vulnerabilities found! This image is secure.</p>
            {% endif %}
        </div>
    </div>
</body>
</html>
EOF

  filename = "${path.module}/temp_build/templates/report.html"
}
