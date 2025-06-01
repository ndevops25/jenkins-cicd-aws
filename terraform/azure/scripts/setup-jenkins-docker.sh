#!/bin/bash

# Script de Instalação Jenkins para Azure
# Versão corrigida para resolver problemas de Groovy/Plugin
echo "=== Instalação Jenkins Azure - $(date) ===" | tee /var/log/jenkins-install.log

# Aguardar rede estar pronta
sleep 10

# Atualizar sistema
echo "Atualizando sistema..." | tee -a /var/log/jenkins-install.log
apt-get update -y >> /var/log/jenkins-install.log 2>&1

# Instalar Docker
echo "Instalando Docker..." | tee -a /var/log/jenkins-install.log
apt-get install -y apt-transport-https ca-certificates curl software-properties-common >> /var/log/jenkins-install.log 2>&1
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - >> /var/log/jenkins-install.log 2>&1
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> /var/log/jenkins-install.log 2>&1
apt-get update -y >> /var/log/jenkins-install.log 2>&1
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose >> /var/log/jenkins-install.log 2>&1

# Iniciar Docker
systemctl enable docker >> /var/log/jenkins-install.log 2>&1
systemctl start docker >> /var/log/jenkins-install.log 2>&1
usermod -aG docker ubuntu >> /var/log/jenkins-install.log 2>&1

# Criar diretórios para Jenkins
echo "Criando diretórios..." | tee -a /var/log/jenkins-install.log
mkdir -p /opt/jenkins/data
chmod 777 /opt/jenkins/data

# Criar Docker Compose com configurações otimizadas
echo "Criando configuração Docker Compose..." | tee -a /var/log/jenkins-install.log
cat > /opt/jenkins/docker-compose.yml << 'EOL'
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /opt/jenkins/data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=true -Dhudson.remoting.ClassFilter=java.lang.Exception,hudson.remoting.Channel -Dhudson.security.csrf.DefaultCrumbIssuer.EXCLUDE_SESSION_ID=true
      - JENKINS_OPTS=--httpPort=8080
    networks:
      - jenkins-net

networks:
  jenkins-net:
    driver: bridge
EOL

# Iniciar Jenkins
echo "Iniciando Jenkins..." | tee -a /var/log/jenkins-install.log
cd /opt/jenkins
docker-compose up -d >> /var/log/jenkins-install.log 2>&1

# Aguardar Jenkins inicializar completamente
echo "Aguardando Jenkins inicializar..." | tee -a /var/log/jenkins-install.log
sleep 30

# Aguardar arquivo de senha ser criado
for i in {1..30}; do
  if [ -f /opt/jenkins/data/secrets/initialAdminPassword ]; then
    echo "Jenkins inicializado com sucesso!" | tee -a /var/log/jenkins-install.log
    break
  else
    echo "Aguardando inicialização... ($i/30)" | tee -a /var/log/jenkins-install.log
    sleep 10
  fi
done

# Verificar se Jenkins está rodando
if docker ps | grep -q jenkins; then
  echo "Container Jenkins está rodando!" | tee -a /var/log/jenkins-install.log
else
  echo "ERRO: Container Jenkins não está rodando!" | tee -a /var/log/jenkins-install.log
  docker logs jenkins >> /var/log/jenkins-install.log 2>&1
fi

# Obter informações
if [ -f /opt/jenkins/data/secrets/initialAdminPassword ]; then
  JENKINS_PASSWORD=$(cat /opt/jenkins/data/secrets/initialAdminPassword)
  IP_PUBLICO=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
  
  # Salvar informações
  cat > /home/ubuntu/jenkins-info.txt << EOF
=== Jenkins Instalado com Sucesso ===
URL: http://$IP_PUBLICO:8080
Senha inicial: $JENKINS_PASSWORD
Data da instalação: $(date)

Comandos úteis:
- Ver logs: docker logs -f jenkins
- Reiniciar: cd /opt/jenkins && docker-compose restart
- Parar: cd /opt/jenkins && docker-compose down
- Iniciar: cd /opt/jenkins && docker-compose up -d

Localização dos dados: /opt/jenkins/data
=========================================
EOF

  chown ubuntu:ubuntu /home/ubuntu/jenkins-info.txt
  chmod 600 /home/ubuntu/jenkins-info.txt

  echo "" | tee -a /var/log/jenkins-install.log
  echo "=== JENKINS INSTALADO COM SUCESSO! ===" | tee -a /var/log/jenkins-install.log
  echo "URL: http://$IP_PUBLICO:8080" | tee -a /var/log/jenkins-install.log
  echo "Senha inicial: $JENKINS_PASSWORD" | tee -a /var/log/jenkins-install.log
  echo "Informações salvas em: /home/ubuntu/jenkins-info.txt" | tee -a /var/log/jenkins-install.log
  echo "=======================================" | tee -a /var/log/jenkins-install.log
else
  echo "ERRO: Não foi possível obter a senha inicial!" | tee -a /var/log/jenkins-install.log
  echo "Verifique os logs: docker logs jenkins" | tee -a /var/log/jenkins-install.log
fi

# Configurar reinicialização automática após reboot
cat > /etc/systemd/system/jenkins-startup.service << 'EOL'
[Unit]
Description=Jenkins Docker Startup
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/jenkins
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOL

systemctl enable jenkins-startup.service >> /var/log/jenkins-install.log 2>&1

echo "=== Script finalizado - $(date) ===" | tee -a /var/log/jenkins-install.log