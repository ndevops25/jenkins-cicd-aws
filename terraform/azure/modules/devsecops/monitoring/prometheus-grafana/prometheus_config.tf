# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Arquivos de configuração do Prometheus
resource "local_file" "prometheus_config" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/prometheus.yml"
  content  = <<-EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'grafana'
    static_configs:
      - targets: ['localhost:3000']
    scrape_interval: 15s
    metrics_path: /metrics

  # Exemplo para monitorar aplicações externas
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']
    scrape_interval: 15s

  # Monitoramento de containers Docker (se disponível)
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
    scrape_interval: 30s
EOF
}