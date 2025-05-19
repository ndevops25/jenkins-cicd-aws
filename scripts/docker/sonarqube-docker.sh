#!/bin/bash
# Implementar SonarQube via Docker (versão LTS mais recente)

# Instalar Docker se não estiver instalado
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
fi

# Parar qualquer serviço SonarQube existente
docker stop sonarqube sonar-postgres || true
docker rm sonarqube sonar-postgres || true

# Verificar/criar rede para o PostgreSQL e SonarQube
docker network create sonarnet || true

# Executar PostgreSQL
echo "Iniciando PostgreSQL via Docker..."
docker run -d \
    --name sonar-postgres \
    --network sonarnet \
    -e POSTGRES_USER=sonar \
    -e POSTGRES_PASSWORD=sonar \
    -e POSTGRES_DB=sonar \
    -v sonar-postgres-data:/var/lib/postgresql/data \
    postgres:15

# Aguardar PostgreSQL inicializar
echo "Aguardando PostgreSQL inicializar..."
sleep 10

# Executar SonarQube (Versão LTS atual)
echo "Iniciando SonarQube via Docker..."
docker run -d \
    --name sonarqube \
    --network sonarnet \
    -p 9000:9000 \
    -e SONAR_JDBC_URL=jdbc:postgresql://sonar-postgres:5432/sonar \
    -e SONAR_JDBC_USERNAME=sonar \
    -e SONAR_JDBC_PASSWORD=sonar \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    -v sonar-data:/opt/sonarqube/data \
    -v sonar-logs:/opt/sonarqube/logs \
    -v sonar-extensions:/opt/sonarqube/extensions \
    sonarqube:10.5.1-community

# Configurar nginx como proxy
sudo apt-get install -y nginx

sudo bash -c 'cat > /etc/nginx/sites-available/sonarqube << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'

sudo ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Criar script para garantir que os containers iniciem no boot
sudo bash -c 'cat > /usr/local/bin/start-sonarqube-docker << EOF
#!/bin/bash
docker start sonar-postgres
sleep 10
docker start sonarqube
EOF'

sudo chmod +x /usr/local/bin/start-sonarqube-docker

# Configurar para iniciar no boot
sudo bash -c 'cat > /etc/systemd/system/sonarqube-docker.service << EOF
[Unit]
Description=SonarQube Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/start-sonarqube-docker
ExecStop=docker stop sonarqube sonar-postgres

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable sonarqube-docker.service

# Obter IP público e exibir informações
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo ""
echo "=== SonarQube via Docker ==="
echo "URL: http://$PUBLIC_IP"
echo "Login: admin"
echo "Senha: admin"
echo ""
echo "Para verificar status dos containers:"
echo "docker ps"
echo ""