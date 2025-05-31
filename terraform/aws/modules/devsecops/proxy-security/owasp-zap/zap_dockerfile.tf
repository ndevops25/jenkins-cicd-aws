# OWASP ZAP Security Testing Module
# Implementa OWASP ZAP com dashboard web para testes de segurança de aplicações web

# Dockerfile para OWASP ZAP
resource "local_file" "zap_dockerfile" {
  filename = "modules/devsecops/proxy-security/owasp-zap/temp_build/Dockerfile"
  content  = <<-EOF
# OWASP ZAP Dashboard - Dockerfile
FROM python:3.9-slim

# Evitar prompts interativos
ENV DEBIAN_FRONTEND=noninteractive

# Atualizar e instalar dependências essenciais
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Criar diretório de trabalho
WORKDIR /app

# Instalar dependências Python primeiro (melhor cache)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar aplicação
COPY app.py .
COPY templates/ ./templates/

# Criar diretórios necessários
RUN mkdir -p /app/reports /app/logs

# Expor porta da aplicação
EXPOSE 5000

# Variáveis de ambiente
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Comando para iniciar
CMD ["flask", "run"]
EOF
}