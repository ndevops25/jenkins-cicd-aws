# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Dockerfile para Grafana customizado
resource "local_file" "grafana_dockerfile" {
  content = <<-EOF
FROM grafana/grafana:latest

# Usar root temporariamente
USER root

# Instalar plugins necessários
RUN grafana-cli plugins install grafana-azure-monitor-datasource
RUN grafana-cli plugins install prometheus-datasource

# Copiar configurações personalizadas
COPY datasources.yml /etc/grafana/provisioning/datasources/
COPY dashboard.json /var/lib/grafana/dashboards/
COPY grafana.ini /etc/grafana/

# Criar diretório para dashboards
RUN mkdir -p /var/lib/grafana/dashboards

# Configurar permissões
RUN chown -R grafana:grafana /var/lib/grafana /etc/grafana

# Voltar para usuário grafana
USER grafana

# Expor porta
EXPOSE 3000

# Variáveis de ambiente
ENV GF_SECURITY_ADMIN_PASSWORD=admin
ENV GF_USERS_ALLOW_SIGN_UP=false
ENV GF_INSTALL_PLUGINS=grafana-azure-monitor-datasource

# Comando padrão
CMD ["/run.sh"]
EOF

  filename = "${path.module}/temp_build/Dockerfile"
}