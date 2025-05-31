# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Configuração customizada do Grafana
resource "local_file" "grafana_config" {
  content = <<-EOF
[analytics]
reporting_enabled = false

[security]
admin_user = admin
admin_password = admin
disable_gravatar = true

[users]
allow_sign_up = false
allow_org_create = false

[auth.anonymous]
enabled = false

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/dashboard.json

[panels]
disable_sanitize_html = false

[log]
mode = console
level = info

[metrics]
enabled = true

[server]
http_port = 3000
domain = localhost
root_url = http://localhost:3000
EOF

  filename = "${path.module}/temp_build/grafana.ini"
}