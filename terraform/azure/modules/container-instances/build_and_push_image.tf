# Criar aplicação Python separadamente
resource "local_file" "python_app" {
  content = <<-EOF
from flask import Flask, jsonify
import os
import socket
import datetime

app = Flask(__name__)

@app.route("/")
def hello():
    return """
    <h1>🐍 Python App Running!</h1>
    <p><strong>Status:</strong> ✅ Healthy</p>
    <p><strong>Environment:</strong> Azure Container Instances</p>
    <p><strong>Hostname:</strong> {}</p>
    <p><strong>Time:</strong> {}</p>
    <p><strong>Version:</strong> 1.0</p>
    <hr>
    <p><small>Built with Terraform + ACR + ACI</small></p>
    """.format(socket.gethostname(), datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": "python-app",
        "version": "1.0",
        "timestamp": datetime.datetime.now().isoformat(),
        "hostname": socket.gethostname()
    })

@app.route("/info")
def info():
    return jsonify({
        "app": "Python Flask Application",
        "environment": os.getenv("ENV", "production"),
        "port": os.getenv("PORT", "8000"),
        "hostname": socket.gethostname(),
        "python_version": "3.11"
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    print(f"🚀 Starting Flask app on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
EOF

  filename = "${path.module}/temp_build/app.py"
}

# Criar Dockerfile separadamente
resource "local_file" "dockerfile" {
  content = <<-EOF
FROM python:3.11-alpine

WORKDIR /app

# Instalar dependências
RUN pip install --no-cache-dir flask

# Copiar aplicação
COPY app.py .

# Expor porta
EXPOSE 8000

# Comando para executar
CMD ["python", "app.py"]
EOF

  filename = "${path.module}/temp_build/Dockerfile"
}

# Build e Push da imagem para o ACR
# Build melhorado para Container Instances com tratamento de erros
resource "null_resource" "build_and_push_image" {
  depends_on = [
    var.acr_dependency,
    local_file.python_app,
    local_file.dockerfile
  ]
  
  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      echo "🐍 Building Python Application..."
      
      # Função para verificar pré-requisitos
      check_prerequisites() {
          echo "🔍 Verificando pré-requisitos..."
          
          # Verificar se Docker está rodando
          if ! docker info > /dev/null 2>&1; then
              echo "❌ Docker não está rodando ou não está instalado"
              echo "💡 Inicie o Docker Desktop e tente novamente"
              exit 1
          fi
          
          # Verificar se Azure CLI está instalado
          if ! command -v az &> /dev/null; then
              echo "❌ Azure CLI não está instalado"
              echo "💡 Instale o Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli"
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
      
      # Criar e navegar para diretório
      TARGET_DIR="modules/container-instances/temp_build"
      echo "📁 Criando/navegando para: $TARGET_DIR"
      mkdir -p "$TARGET_DIR"
      cd "$TARGET_DIR"
      
      echo "📋 Arquivos no diretório:"
      ls -la
      
      # Verificar se os arquivos essenciais existem
      if [ ! -f "app.py" ]; then
          echo "❌ app.py não encontrado"
          exit 1
      fi
      
      if [ ! -f "Dockerfile" ]; then
          echo "❌ Dockerfile não encontrado"
          exit 1
      fi
      
      # Verificar conteúdo dos arquivos
      echo "📄 Verificando conteúdo do app.py:"
      head -5 app.py
      
      echo "📄 Verificando conteúdo do Dockerfile:"
      head -5 Dockerfile
      
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
      
      # Build da imagem com mais detalhes
      echo "🔨 Building imagem Docker..."
      if ! docker build -t python-app:local . --progress=plain; then
          echo "❌ Falha no build da imagem Docker"
          echo "🔍 Verifique os logs acima para detalhes do erro"
          exit 1
      fi
      
      # Verificar se a imagem foi criada
      if ! docker images python-app:local --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep python-app; then
          echo "❌ Imagem não foi criada corretamente"
          exit 1
      fi
      
      echo "🏷️ Tagging imagem para ACR..."
      docker tag python-app:local ${var.acr_login_server}/python-app:latest
      
      # Push com retry
      echo "📤 Fazendo push para ACR..."
      for i in {1..3}; do
          if docker push ${var.acr_login_server}/python-app:latest; then
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
      if az acr repository show-tags --name "$ACR_NAME" --repository python-app --output table; then
          echo "✅ Imagem verificada no ACR"
      else
          echo "⚠️ Não foi possível verificar a imagem, mas push foi concluído"
      fi
      
      # Limpar apenas se tudo deu certo
      echo "🧹 Limpando imagens locais..."
      docker rmi python-app:local ${var.acr_login_server}/python-app:latest 2>/dev/null || echo "⚠️ Algumas imagens já foram removidas"
      
      echo "✅ Build e push concluídos com sucesso!"
      echo "🎯 Imagem disponível em: ${var.acr_login_server}/python-app:latest"
      
      # Mostrar estatísticas finais
      echo "📊 Repositórios no ACR:"
      az acr repository list --name "$ACR_NAME" --output table || echo "⚠️ Não foi possível listar repositórios"
    EOF
    
    working_dir = "."
  }

  # Triggers otimizados (sem timestamp para evitar rebuilds desnecessários)
  triggers = {
    acr_server     = var.acr_login_server
    python_app_md5 = local_file.python_app.content_md5
    dockerfile_md5 = local_file.dockerfile.content_md5
    # Removido timestamp para evitar rebuilds constantes
  }
}

# Adicionar um data source para verificar se o ACR existe
data "azurerm_container_registry" "acr_check" {
  name                = replace(var.acr_login_server, ".azurecr.io", "")
  resource_group_name = var.resource_group_name
}
