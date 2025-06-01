# Trivy Security Scanner Module
# Implementa Trivy Server com dashboard web para visualização de vulnerabilidades

# Dockerfile para o Trivy Dashboard
resource "local_file" "trivy_dockerfile" {
  content = <<-EOF
FROM aquasec/trivy:latest

# Instalar Python e Flask como root, contornando o problema de ambiente gerenciado
USER root

# Instalar Python e dependências do sistema
RUN apk add --no-cache python3 python3-dev py3-pip

# Contornar o problema de ambiente Python gerenciado
RUN python3 -m pip install --break-system-packages flask jinja2

# Criar usuário não-root
RUN adduser -D -s /bin/sh trivyuser

# Criar diretórios de trabalho
WORKDIR /app
RUN mkdir -p /app/templates /app/reports /tmp/trivy-cache
RUN chown -R trivyuser:trivyuser /app /tmp/trivy-cache

# Copiar aplicação
COPY app.py .
COPY templates/ templates/

# Mudar para usuário não-root
USER trivyuser

# Expor porta
EXPOSE 8080

# Comando de inicialização
CMD ["python3", "app.py"]
EOF

  filename = "${path.module}/temp_build/Dockerfile"
}