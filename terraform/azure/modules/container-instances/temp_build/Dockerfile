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
