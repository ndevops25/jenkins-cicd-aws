# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Configuração de datasources do Grafana
resource "local_file" "grafana_datasources" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/grafana-datasources.yml"
  content  = <<-EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF
}