# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Dockerfile para stack completa (Grafana + Prometheus)
resource "local_file" "monitoring_stack_dockerfile" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/Dockerfile"
  content  = <<-EOF
# Grafana + Prometheus Monitoring Stack
FROM grafana/grafana:10.2.0

# Mudar para usuário root temporariamente
USER root

# Instalar dependências usando apk (Alpine Linux)
RUN apk update && apk add --no-cache \
    curl \
    wget \
    bash \
    tar \
    gzip

# Baixar e instalar Prometheus
ENV PROMETHEUS_VERSION=2.45.0
RUN wget https://github.com/prometheus/prometheus/releases/download/v$${PROMETHEUS_VERSION}/prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && tar -xzf prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && mv prometheus-$${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/ \
    && mv prometheus-$${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/ \
    && rm -rf prometheus-$${PROMETHEUS_VERSION}.linux-amd64* \
    && mkdir -p /etc/prometheus /var/lib/prometheus

# Criar diretórios
RUN mkdir -p /etc/grafana/provisioning/datasources \
    /etc/grafana/provisioning/dashboards \
    /var/lib/grafana/dashboards \
    /var/log/grafana \
    /var/log/prometheus

# Copiar configurações
COPY prometheus.yml /etc/prometheus/
COPY grafana-datasources.yml /etc/grafana/provisioning/datasources/
COPY grafana-dashboards.yml /etc/grafana/provisioning/dashboards/
COPY start-monitoring.sh /usr/local/bin/

# Ajustar permissões
RUN chmod +x /usr/local/bin/start-monitoring.sh \
    && chown -R grafana:root /etc/grafana /var/lib/grafana /var/log/grafana \
    && chown -R root:root /etc/prometheus /var/lib/prometheus /var/log/prometheus

# Voltar para usuário grafana
USER grafana

# Expor portas
EXPOSE 3000 9090

# Variáveis de ambiente (sem dados sensíveis)
ENV GF_SECURITY_ADMIN_USER=admin
ENV GF_PATHS_PROVISIONING=/etc/grafana/provisioning

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Comando de inicialização
CMD ["/usr/local/bin/start-monitoring.sh"]
EOF
}