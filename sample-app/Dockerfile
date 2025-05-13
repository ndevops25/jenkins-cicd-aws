FROM python:3.9-slim

WORKDIR /app

# Instalar Flask diretamente primeiro
RUN pip install Flask==2.3.2 gunicorn==21.2.0

# Copiar apenas o app.py
COPY app.py .

# Teste simples
RUN python -c "import flask; print('Flask OK')"

# Executar direto com Python
CMD ["python", "app.py"]