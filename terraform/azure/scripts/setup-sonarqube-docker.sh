#!/bin/bash
# Script SonarQube para Azure VM (baseado no que funciona na AWS)

echo "=== Iniciando instalação SonarQube - $(date) ===" > /var/log/sonarqube-install.log 2>&1

# Aguardar rede estar pronta
sleep 10

# Atualizar sistema
apt-get update -y >> /var/log/sonarqube-install.log 2>&1

# Instalar Docker se não estiver instalado
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..." >> /var/log/sonarqube-install.log 2>&1
    apt-get install -y docker.io >> /var/log/sonarqube-install.log 2>&1
    systemctl enable --now docker >> /var/log/sonarqube-install.log 2>&1
fi

# Configurar kernel para SonarQube (essencial!)
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p >> /var/log/sonarqube-install.log 2>&1

# Parar qualquer serviço SonarQube existente
docker stop sonarqube sonar-postgres 2>/dev/null || true
docker rm sonarqube sonar-postgres 2>/dev/null || true

# Remover volumes antigos se necessário (cuidado com dados!)
# docker volume rm sonar-postgres-data sonar-data sonar-logs sonar-extensions 2>/dev/null || true

# Verificar/criar rede para o PostgreSQL e SonarQube
docker network create sonarnet 2>/dev/null || true

# Executar PostgreSQL
echo "Iniciando PostgreSQL via Docker..." >> /var/log/sonarqube-install.log 2>&1
docker run -d \
    --name sonar-postgres \
    --network sonarnet \
    --restart unless-stopped \
    -e POSTGRES_USER=sonar \
    -e POSTGRES_PASSWORD=sonar \
    -e POSTGRES_DB=sonar \
    -v sonar-postgres-data:/var/lib/postgresql/data \
    postgres:15 >> /var/log/sonarqube-install.log 2>&1

# Aguardar PostgreSQL inicializar
echo "Aguardando PostgreSQL inicializar..." >> /var/log/sonarqube-install.log 2>&1
sleep 15

# Verificar se PostgreSQL está rodando
docker logs sonar-postgres >> /var/log/sonarqube-install.log 2>&1

# Executar SonarQube (Versão LTS atual)
echo "Iniciando SonarQube via Docker..." >> /var/log/sonarqube-install.log 2>&1
docker run -d \
    --name sonarqube \
    --network sonarnet \
    --restart unless-stopped \
    -p 9000:9000 \
    -e SONAR_JDBC_URL=jdbc:postgresql://sonar-postgres:5432/sonar \
    -e SONAR_JDBC_USERNAME=sonar \
    -e SONAR_JDBC_PASSWORD=sonar \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    -e SONAR_WEB_CONTEXT= \
    -e SONAR_WEB_PORT=9000 \
    -v sonar-data:/opt/sonarqube/data \
    -v sonar-logs:/opt/sonarqube/logs \
    -v sonar-extensions:/opt/sonarqube/extensions \
    sonarqube:9.9-community >> /var/log/sonarqube-install.log 2>&1

# Aguardar SonarQube inicializar
echo "Aguardando SonarQube inicializar..." >> /var/log/sonarqube-install.log 2>&1
sleep 30

# Verificar logs do SonarQube
echo "=== Logs do SonarQube ===" >> /var/log/sonarqube-install.log 2>&1
docker logs sonarqube >> /var/log/sonarqube-install.log 2>&1

# Instalar nginx como proxy (opcional, mas recomendado)
apt-get install -y nginx >> /var/log/sonarqube-install.log 2>&1

# Configurar nginx
cat > /etc/nginx/sites-available/sonarqube << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF

ln -sf /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx >> /var/log/sonarqube-install.log 2>&1

# Criar script para garantir que os containers iniciem no boot
cat > /usr/local/bin/start-sonarqube-docker << 'EOF'
#!/bin/bash
docker start sonar-postgres
sleep 15
docker start sonarqube
EOF

chmod +x /usr/local/bin/start-sonarqube-docker

# Configurar para iniciar no boot
cat > /etc/systemd/system/sonarqube-docker.service << 'EOF'
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
EOF

systemctl daemon-reload
systemctl enable sonarqube-docker.service >> /var/log/sonarqube-install.log 2>&1

# Obter IP da VM Azure (diferente da AWS)
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo "" >> /var/log/sonarqube-install.log 2>&1
echo "=== SonarQube Instalação Concluída ===" >> /var/log/sonarqube-install.log 2>&1
echo "URL Interna: http://$PRIVATE_IP:9000" >> /var/log/sonarqube-install.log 2>&1
echo "Login: admin" >> /var/log/sonarqube-install.log 2>&1
echo "Senha: admin" >> /var/log/sonarqube-install.log 2>&1
echo "" >> /var/log/sonarqube-install.log 2>&1
echo "Para verificar status:" >> /var/log/sonarqube-install.log 2>&1
echo "docker ps" >> /var/log/sonarqube-install.log 2>&1
echo "docker logs sonarqube" >> /var/log/sonarqube-install.log 2>&1
echo "" >> /var/log/sonarqube-install.log 2>&1

# Exibir informações no console também
echo ""
echo "=== SonarQube Instalação Concluída ==="
echo "URL: http://$PRIVATE_IP:9000"
echo "Login: admin"
echo "Senha: admin"
echo ""
echo "Aguarde alguns minutos para o SonarQube inicializar completamente"
echo "Verifique os logs com: docker logs sonarqube"
echo ""