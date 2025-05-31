# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Arquivos de configuração do Prometheus
resource "local_file" "prometheus_config" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/prometheus.yml"
  content  = <<-EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'grafana'
    static_configs:
      - targets: ['localhost:3000']
EOF
}