# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Criar o Dockerfile do monitoring stack com verificações
resource "local_file" "monitoring_stack_dockerfile" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/Dockerfile"
  content  = <<-EOF
# Multi-stage build para otimizar tamanho
FROM prom/prometheus:latest AS prometheus
FROM grafana/grafana:latest

# Definir usuário como root para configurações
USER root

# Instalar dependências necessárias
RUN apt-get update && \
    apt-get install -y curl procps && \
    rm -rf /var/lib/apt/lists/*

# Instalar Prometheus no container do Grafana
COPY --from=prometheus /bin/prometheus /usr/local/bin/prometheus
COPY --from=prometheus /etc/prometheus /etc/prometheus

# Verificar e criar usuário grafana se não existir
RUN id grafana || (groupadd -r grafana && useradd -r -g grafana grafana)

# Criar diretórios necessários com permissões corretas
RUN mkdir -p /var/lib/prometheus \
    /etc/grafana/provisioning/datasources \
    /etc/grafana/provisioning/dashboards \
    /var/lib/grafana/dashboards \
    /var/log/grafana && \
    chown -R grafana:grafana /var/lib/prometheus \
    /etc/grafana \
    /var/lib/grafana \
    /var/log/grafana && \
    chmod -R 755 /var/lib/prometheus \
    /etc/grafana/provisioning \
    /var/lib/grafana

# Copiar configurações
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY grafana-datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY dashboard.json /var/lib/grafana/dashboards/dashboard.json
COPY start-monitoring.sh /start-monitoring.sh

# Configurar dashboards provisioning
RUN echo 'apiVersion: 1' > /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo 'providers:' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '  - name: "default"' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    orgId: 1' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    folder: ""' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    type: file' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    disableDeletion: false' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    updateIntervalSeconds: 10' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    allowUiUpdates: true' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '    options:' >> /etc/grafana/provisioning/dashboards/dashboards.yml && \
    echo '      path: /var/lib/grafana/dashboards' >> /etc/grafana/provisioning/dashboards/dashboards.yml

# Dar permissões corretas aos arquivos
RUN chmod +x /start-monitoring.sh && \
    chown grafana:grafana /start-monitoring.sh \
    /etc/prometheus/prometheus.yml \
    /etc/grafana/provisioning/datasources/datasources.yml \
    /var/lib/grafana/dashboards/dashboard.json \
    /etc/grafana/provisioning/dashboards/dashboards.yml

# Expor portas
EXPOSE 3000 9090

# Comando padrão
CMD ["/start-monitoring.sh"]
EOF
}