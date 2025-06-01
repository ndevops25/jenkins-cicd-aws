# Arquivo requirements.txt
resource "local_file" "zap_requirements" {
  filename = "modules/devsecops/proxy-security/owasp-zap/temp_build/requirements.txt"
  content  = <<-EOF
flask==2.3.3
requests==2.31.0
jinja2==3.1.2
werkzeug==2.3.7
markupsafe==2.1.3
itsdangerous==2.1.2
click==8.1.7
EOF
}


# Build e Push da imagem OWASP ZAP para o ACR
resource "null_resource" "build_zap_image" {
  depends_on = [
    var.acr_dependency,
    local_file.zap_dashboard_app,
    local_file.zap_dashboard_template,
    local_file.zap_report_template,
    local_file.zap_dockerfile,
    local_file.zap_requirements  # NOVO: dependência do requirements.txt
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      echo "🕷️ Building OWASP ZAP Dashboard image..."
      
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
      
      TARGET_DIR="modules/devsecops/proxy-security/owasp-zap/temp_build"
      
      echo "📁 Navegando para: $TARGET_DIR"
      cd "$TARGET_DIR"
      
      echo "📋 Verificando arquivos necessários:"
      
      # Lista de arquivos obrigatórios
      REQUIRED_FILES=("Dockerfile" "app.py" "requirements.txt")
      
      for file in "$${REQUIRED_FILES[@]}"; do
          if [ ! -f "$file" ]; then
              echo "❌ Arquivo obrigatório não encontrado: $file"
              echo "📂 Conteúdo atual do diretório:"
              ls -la
              exit 1
          else
              echo "✅ $file encontrado"
          fi
      done
      
      # Verificar se templates existe
      if [ ! -d "templates" ]; then
          echo "⚠️  Diretório templates não encontrado, criando..."
          mkdir -p templates
      fi
      
      echo "📋 Arquivos finais para build:"
      ls -la
      echo ""
      
      # Login no ACR
      echo "🔑 Login no ACR..."
      az acr login --name ${replace(var.acr_login_server, ".azurecr.io", "")}
      
      # Build
      echo "🔨 Building OWASP ZAP dashboard..."
      echo "🔍 Contexto do build: $(pwd)"
      
      docker build -t owasp-zap-dashboard:local . --progress=plain
      
      # Tag
      echo "🏷️ Tagging para ACR..."
      docker tag owasp-zap-dashboard:local ${var.acr_login_server}/owasp-zap-dashboard:latest
      
      # Push
      echo "📤 Push para ACR..."
      docker push ${var.acr_login_server}/owasp-zap-dashboard:latest
      
      # Verificar
      echo "🔍 Verificando imagem no ACR..."
      az acr repository show-tags --name ${replace(var.acr_login_server, ".azurecr.io", "")} --repository owasp-zap-dashboard --output table || echo "⚠️ Verificação falhou, mas push concluído"
      
      # Limpar
      echo "🧹 Limpeza local..."
      docker rmi owasp-zap-dashboard:local ${var.acr_login_server}/owasp-zap-dashboard:latest || true
      
      echo "✅ OWASP ZAP dashboard image criada com sucesso!"
      echo "🎯 Imagem disponível em: ${var.acr_login_server}/owasp-zap-dashboard:latest"
    EOF
    
    working_dir = "."
  }

  triggers = {
    acr_server      = var.acr_login_server
    app_md5         = local_file.zap_dashboard_app.content_md5
    dockerfile_md5  = local_file.zap_dockerfile.content_md5
    template_md5    = local_file.zap_dashboard_template.content_md5
    requirements_md5 = local_file.zap_requirements.content_md5  # NOVO trigger
  }
}