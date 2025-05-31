# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Configuração de dashboards do Grafana
resource "local_file" "grafana_dashboards" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/grafana-dashboards.yml"
  content  = <<-EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF
}