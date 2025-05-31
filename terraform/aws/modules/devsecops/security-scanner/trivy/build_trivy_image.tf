# Trivy Security Scanner Module
# Implementa Trivy Server com dashboard web para visualização de vulnerabilidades

# Build e Push da imagem Trivy para o ACR
resource "null_resource" "build_trivy_image" {
  depends_on = [
    var.acr_dependency,
    local_file.trivy_dashboard_app,
    local_file.trivy_dashboard_template,
    local_file.trivy_report_template,
    local_file.trivy_dockerfile
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      echo "🛡️ Building Trivy Dashboard image..."
      
      # Verificar pré-requisitos
      if ! docker info > /dev/null 2>&1; then
          echo "❌ Docker não está rodando"
          exit 1
      fi
      
      # Navegar para o diretório correto na nova estrutura
      cd modules/devsecops/security-scanner/trivy/temp_build
      
      echo "📋 Arquivos no diretório:"
      ls -la
      
      # Verificar se os arquivos necessários existem
      if [ ! -f "Dockerfile" ] || [ ! -f "app.py" ]; then
          echo "❌ Arquivos necessários não encontrados"
          echo "Conteúdo do diretório:"
          find . -type f
          exit 1
      fi
      
      # Login no ACR
      echo "🔑 Login no ACR..."
      az acr login --name ${replace(var.acr_login_server, ".azurecr.io", "")}
      
      # Build com mais verbose
      echo "🔨 Building Trivy dashboard..."
      docker build -t trivy-dashboard:local . --no-cache
      
      # Tag
      echo "🏷️ Tagging para ACR..."
      docker tag trivy-dashboard:local ${var.acr_login_server}/trivy-dashboard:latest
      
      # Push
      echo "📤 Push para ACR..."
      docker push ${var.acr_login_server}/trivy-dashboard:latest
      
      # Verificar
      echo "🔍 Verificando imagem no ACR..."
      az acr repository show-tags --name ${replace(var.acr_login_server, ".azurecr.io", "")} --repository trivy-dashboard --output table || echo "⚠️ Verificação falhou, mas push pode ter funcionado"
      
      # Limpar
      echo "🧹 Limpeza..."
      docker rmi trivy-dashboard:local ${var.acr_login_server}/trivy-dashboard:latest || true
      
      echo "✅ Trivy dashboard image criada com sucesso!"
    EOF
    working_dir = "."
  }

  # Triggers APENAS para mudanças reais nos arquivos
  triggers = {
    acr_server     = var.acr_login_server
    app_md5        = local_file.trivy_dashboard_app.content_md5
    dockerfile_md5 = local_file.trivy_dockerfile.content_md5
    # timestamp     = timestamp() - timestamp removido! ← Esta era a causa do problema de recriação dos recursos
  }
}