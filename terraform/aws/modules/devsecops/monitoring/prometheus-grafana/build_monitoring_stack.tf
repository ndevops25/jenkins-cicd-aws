# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Script de inicialização melhorado
resource "local_file" "monitoring_start_script" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/start-monitoring.sh"
  content  = <<-EOF
#!/bin/bash
set -e

echo "🚀 Iniciando Monitoring Stack..."

# Função de cleanup
cleanup() {
    echo "🛑 Parando serviços..."
    if [ ! -z "$PROMETHEUS_PID" ]; then
        kill $PROMETHEUS_PID 2>/dev/null || true
    fi
    if [ ! -z "$GRAFANA_PID" ]; then
        kill $GRAFANA_PID 2>/dev/null || true
    fi
    wait 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Verificar se os arquivos de configuração existem
if [ ! -f "/etc/prometheus/prometheus.yml" ]; then
    echo "❌ Arquivo de configuração do Prometheus não encontrado"
    exit 1
fi

# Iniciar Prometheus em background
echo "🔥 Iniciando Prometheus..."
prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --web.listen-address=0.0.0.0:9090 \
    --log.level=info \
    --web.enable-lifecycle &

PROMETHEUS_PID=$!
echo "Prometheus PID: $PROMETHEUS_PID"

# Aguardar Prometheus estar pronto
echo "⏳ Aguardando Prometheus..."
for i in {1..30}; do
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo "✅ Prometheus está rodando!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout: Prometheus não iniciou"
        exit 1
    fi
    sleep 2
done

# Iniciar Grafana
echo "📈 Iniciando Grafana..."
/run.sh &

GRAFANA_PID=$!
echo "Grafana PID: $GRAFANA_PID"

# Aguardar Grafana estar pronto
echo "⏳ Aguardando Grafana..."
for i in {1..60}; do
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Grafana está rodando!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Timeout: Grafana não iniciou"
        exit 1
    fi
    sleep 2
done

echo "🎉 Monitoring Stack iniciado com sucesso!"
echo "📊 Grafana: http://localhost:3000 (admin/admin)"
echo "🔥 Prometheus: http://localhost:9090"
echo "🔍 Health Grafana: http://localhost:3000/api/health"
echo "🔍 Health Prometheus: http://localhost:9090/-/healthy"

# Manter o script rodando
wait $PROMETHEUS_PID $GRAFANA_PID
EOF
}

# Build e Push da stack de monitoramento
resource "null_resource" "build_monitoring_stack" {
  depends_on = [
    var.acr_dependency,
    local_file.grafana_datasources,
    local_file.grafana_dashboards,
    local_file.prometheus_config,
    local_file.monitoring_start_script,
    local_file.monitoring_stack_dockerfile
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      echo "📊 Building Monitoring Stack (Grafana + Prometheus)..."
      
      # Verificar pré-requisitos
      if ! docker info > /dev/null 2>&1; then
          echo "❌ Docker não está rodando"
          exit 1
      fi
      
      if ! command -v az &> /dev/null; then
          echo "❌ Azure CLI não está instalado"
          exit 1
      fi
      
      echo "✅ Pré-requisitos OK"
      
      TARGET_DIR="modules/devsecops/monitoring/prometheus-grafana/temp_build"
      
      echo "📁 Navegando para: $TARGET_DIR"
      cd "$TARGET_DIR"
      
      echo "📋 Verificando arquivos necessários:"
      
      REQUIRED_FILES=("Dockerfile" "prometheus.yml" "grafana-datasources.yml" "start-monitoring.sh")
      
      for file in "$${REQUIRED_FILES[@]}"; do
          if [ ! -f "$file" ]; then
              echo "❌ Arquivo obrigatório não encontrado: $file"
              ls -la
              exit 1
          else
              echo "✅ $file encontrado"
          fi
      done
      
      echo "📋 Arquivos finais para build:"
      ls -la
      
      # Login no ACR
      echo "🔑 Login no ACR..."
      az acr login --name ${replace(var.acr_login_server, ".azurecr.io", "")}
      
      # Build
      echo "🔨 Building monitoring stack..."
      docker build -t monitoring-stack:local . --progress=plain
      
      # Tag
      echo "🏷️ Tagging para ACR..."
      docker tag monitoring-stack:local ${var.acr_login_server}/monitoring-stack:latest
      
      # Push
      echo "📤 Push para ACR..."
      docker push ${var.acr_login_server}/monitoring-stack:latest
      
      # Verificar
      echo "🔍 Verificando imagem no ACR..."
      az acr repository show-tags --name ${replace(var.acr_login_server, ".azurecr.io", "")} --repository monitoring-stack --output table || echo "⚠️ Verificação falhou, mas push concluído"
      
      # Limpar
      echo "🧹 Limpeza..."
      docker rmi monitoring-stack:local ${var.acr_login_server}/monitoring-stack:latest || true
      
      echo "✅ Monitoring stack image criada com sucesso!"
      echo "🎯 Imagem disponível em: ${var.acr_login_server}/monitoring-stack:latest"
    EOF
    working_dir = "."
  }

  triggers = {
    acr_server      = var.acr_login_server
    prometheus_md5  = local_file.prometheus_config.content_md5
    grafana_ds_md5  = local_file.grafana_datasources.content_md5
    grafana_db_md5  = local_file.grafana_dashboards.content_md5
    script_md5      = local_file.monitoring_start_script.content_md5
    dockerfile_md5  = local_file.monitoring_stack_dockerfile.content_md5
  }
}