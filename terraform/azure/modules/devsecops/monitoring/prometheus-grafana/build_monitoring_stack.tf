# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Build e Push da stack de monitoramento
# Build melhorado com verificações e tratamento de erros
resource "null_resource" "build_monitoring_stack" {
  depends_on = [
    var.acr_dependency,
    local_file.grafana_datasources,
    local_file.grafana_dashboard_json,
    local_file.prometheus_config,
    local_file.monitoring_start_script,
    local_file.monitoring_stack_dockerfile
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      echo "📊 Building Monitoring Stack (Grafana + Prometheus)..."
      
      # Função para verificar pré-requisitos
      check_prerequisites() {
          echo "🔍 Verificando pré-requisitos..."
          
          # Verificar se Docker está rodando
          if ! docker info > /dev/null 2>&1; then
              echo "❌ Docker não está rodando ou não está acessível"
              echo "💡 Verifique se:"
              echo "   - Docker Desktop está iniciado"
              echo "   - O usuário atual tem permissão para usar Docker"
              echo "   - O socket do Docker está acessível"
              
              # Tentar iniciar Docker (Linux)
              if command -v systemctl &> /dev/null; then
                  echo "🔄 Tentando iniciar serviço Docker..."
                  sudo systemctl start docker 2>/dev/null || true
                  sleep 5
                  if docker info > /dev/null 2>&1; then
                      echo "✅ Docker iniciado com sucesso"
                  else
                      exit 1
                  fi
              else
                  exit 1
              fi
          fi
          
          # Verificar Azure CLI
          if ! command -v az &> /dev/null; then
              echo "❌ Azure CLI não está instalado"
              echo "💡 Instale com: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
              exit 1
          fi
          
          # Verificar se está logado no Azure
          if ! az account show > /dev/null 2>&1; then
              echo "❌ Não logado no Azure CLI"
              echo "💡 Execute: az login"
              exit 1
          fi
          
          echo "✅ Pré-requisitos OK"
      }
      
      # Verificar pré-requisitos
      check_prerequisites
      
      TARGET_DIR="modules/devsecops/monitoring/prometheus-grafana/temp_build"
      
      echo "📁 Preparando diretório: $TARGET_DIR"
      mkdir -p "$TARGET_DIR"
      cd "$TARGET_DIR"
      
      echo "📋 Verificando arquivos necessários..."
      
      REQUIRED_FILES=("Dockerfile" "prometheus.yml" "grafana-datasources.yml" "start-monitoring.sh" "dashboard.json")
      
      for file in "$${REQUIRED_FILES[@]}"; do
          if [ ! -f "$file" ]; then
              echo "❌ Arquivo obrigatório não encontrado: $file"
              echo "📂 Arquivos disponíveis:"
              ls -la
              exit 1
          else
              file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "unknown")
              echo "✅ $file encontrado ($file_size bytes)"
          fi
      done
      
      # Verificar conteúdo dos arquivos críticos
      if [ ! -s "dashboard.json" ]; then
          echo "❌ dashboard.json está vazio"
          exit 1
      fi
      
      if [ ! -s "Dockerfile" ]; then
          echo "❌ Dockerfile está vazio"
          exit 1
      fi
      
      echo "📋 Resumo dos arquivos:"
      ls -lah
      
      # Dar permissões corretas
      chmod +x start-monitoring.sh
      
      # Login no ACR com retry
      echo "🔑 Fazendo login no ACR..."
      ACR_NAME="${replace(var.acr_login_server, ".azurecr.io", "")}"
      
      for i in {1..3}; do
          if az acr login --name "$ACR_NAME"; then
              echo "✅ Login no ACR realizado com sucesso"
              break
          else
              echo "⚠️ Tentativa $i de login falhou, tentando novamente..."
              sleep 5
              if [ $i -eq 3 ]; then
                  echo "❌ Falha no login após 3 tentativas"
                  exit 1
              fi
          fi
      done
      
      # Build com mais detalhes e tratamento de erro
      echo "🔨 Building monitoring stack..."
      echo "📝 Conteúdo do Dockerfile:"
      head -20 Dockerfile
      echo "..."
      
      if ! docker build -t monitoring-stack:local . --progress=plain --no-cache; then
          echo "❌ Falha no build da imagem"
          echo "🔍 Conteúdo completo do Dockerfile:"
          cat Dockerfile
          echo ""
          echo "🔍 Arquivos no diretório:"
          ls -la
          exit 1
      fi
      
      # Verificar se a imagem foi criada
      if ! docker images monitoring-stack:local --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"; then
          echo "❌ Imagem não foi criada corretamente"
          exit 1
      fi
      
      # Tag
      echo "🏷️ Tagging para ACR..."
      docker tag monitoring-stack:local ${var.acr_login_server}/monitoring-stack:latest
      
      # Push com retry
      echo "📤 Push para ACR..."
      for i in {1..3}; do
          if docker push ${var.acr_login_server}/monitoring-stack:latest; then
              echo "✅ Push realizado com sucesso"
              break
          else
              echo "⚠️ Tentativa $i de push falhou, tentando novamente..."
              sleep 10
              if [ $i -eq 3 ]; then
                  echo "❌ Falha no push após 3 tentativas"
                  exit 1
              fi
          fi
      done
      
      # Verificar se a imagem foi enviada
      echo "🔍 Verificando imagem no ACR..."
      if az acr repository show-tags --name "$ACR_NAME" --repository monitoring-stack --output table; then
          echo "✅ Imagem verificada no ACR com sucesso"
      else
          echo "⚠️ Não foi possível verificar a imagem, mas push foi concluído"
      fi
      
      # Limpar imagens locais
      echo "🧹 Limpeza de imagens locais..."
      docker rmi monitoring-stack:local ${var.acr_login_server}/monitoring-stack:latest 2>/dev/null || echo "⚠️ Algumas imagens já foram removidas"
      
      echo "✅ Monitoring stack criada com sucesso!"
      echo "🎯 Imagem disponível em: ${var.acr_login_server}/monitoring-stack:latest"
      echo "📊 Acesse Grafana em: http://localhost:3000 (admin/admin)"
      echo "🔥 Acesse Prometheus em: http://localhost:9090"
    EOF
    working_dir = "."
  }

  # Triggers para rebuild quando arquivos mudarem
  triggers = {
    acr_server      = var.acr_login_server
    prometheus_md5  = local_file.prometheus_config.content_md5
    grafana_ds_md5  = local_file.grafana_datasources.content_md5
    dashboard_md5   = local_file.grafana_dashboard_json.content_md5
    script_md5      = local_file.monitoring_start_script.content_md5
    dockerfile_md5  = local_file.monitoring_stack_dockerfile.content_md5
    timestamp       = timestamp()
  }
}