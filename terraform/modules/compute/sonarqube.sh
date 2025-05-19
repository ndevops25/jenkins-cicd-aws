#!/bin/bash

# Script para Instalação do SonarQube com inicialização automática garantida
# Redirecionar toda a saída para log detalhado
exec > >(tee /var/log/user-data-sonarqube.log)
exec 2>&1

echo "=== Iniciando instalação do SonarQube: $(date) ==="

# Atualizar sistema
apt-get update && apt-get upgrade -y

# Configurar limites do sistema
cat > /etc/security/limits.d/99-sonarqube.conf << EOF
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF

# Configurar parâmetros sysctl
cat > /etc/sysctl.d/99-sonarqube.conf << EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

# Aplicar configurações de sysctl
sysctl --system

# Instalar dependências
echo "=== Instalando dependências ==="
apt-get install -y openjdk-17-jdk unzip wget curl jq

# Verificar instalação do Java
java -version

# Instalar PostgreSQL
echo "=== Instalando PostgreSQL ==="
apt-get install -y postgresql postgresql-contrib

# Verificar instalação do PostgreSQL
systemctl status postgresql --no-pager
psql --version

# Configurar banco de dados PostgreSQL
echo "=== Configurando PostgreSQL ==="
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar';"
sudo -u postgres psql -c "CREATE DATABASE sonar OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonar TO sonar;"
sudo -u postgres psql -c "ALTER USER sonar CREATEDB;"

# Verificar configuração do PostgreSQL
sudo -u postgres psql -c "\l" | grep sonar
sudo -u postgres psql -c "\du" | grep sonar

# Criar usuário SonarQube
echo "=== Criando usuário SonarQube ==="
useradd -m -d /opt/sonarqube -s /bin/bash sonarqube || echo "Usuário sonarqube já existe"

# Limpar instalações anteriores se existirem
echo "=== Removendo instalações antigas ==="
systemctl stop sonarqube || true
systemctl disable sonarqube || true
rm -f /etc/systemd/system/sonarqube.service
rm -rf /opt/sonarqube

# Baixar e instalar SonarQube
echo "=== Baixando SonarQube ==="
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.1.69595.zip -O /tmp/sonarqube.zip
unzip -q /tmp/sonarqube.zip -d /tmp
mv /tmp/sonarqube-9.9.1.69595 /opt/sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube
rm /tmp/sonarqube.zip

# Verificar a instalação
echo "=== Verificando instalação do SonarQube ==="
ls -la /opt/sonarqube
ls -la /opt/sonarqube/bin || echo "Diretório bin não encontrado"

# Definir SONAR_SH para facilitar referência
SONAR_SH="/opt/sonarqube/bin/linux-x86-64/sonar.sh"

# Verificar script de inicialização
if [ ! -f "$SONAR_SH" ]; then
  echo "ERRO: Script de inicialização não encontrado. Verificando diretórios..."
  find /opt/sonarqube -name "sonar.sh"
  # Tentar encontrar o caminho correto
  SONAR_SH=$(find /opt/sonarqube -name "sonar.sh" | head -1)
  if [ -z "$SONAR_SH" ]; then
    echo "ERRO CRÍTICO: sonar.sh não encontrado! Abortando."
    exit 1
  else
    echo "Encontrado script em: $SONAR_SH"
  fi
fi

# Tornar o script executável
chmod +x "$SONAR_SH"
chown sonarqube:sonarqube "$SONAR_SH"

# Configurar SonarQube
echo "=== Configurando SonarQube ==="
cat > /opt/sonarqube/conf/sonar.properties << EOF
# Configurações do Banco de Dados
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
sonar.jdbc.maxActive=60
sonar.jdbc.maxIdle=5
sonar.jdbc.minIdle=2
sonar.jdbc.maxWait=5000

# Configurações da Web
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaOpts=-Xmx1G -Xms512m -XX:+HeapDumpOnOutOfMemoryError

# Configurações de Diretórios
sonar.path.data=/opt/sonarqube/data
sonar.path.temp=/opt/sonarqube/temp
sonar.path.logs=/opt/sonarqube/logs

# Configurações do ElasticSearch
sonar.search.javaOpts=-Xmx1G -Xms512m -XX:MaxDirectMemorySize=512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
EOF

# Criar um script wrapper para executar como usuário sonarqube
cat > /usr/local/bin/start-sonarqube << EOF
#!/bin/bash
sudo -u sonarqube $SONAR_SH start
EOF

chmod +x /usr/local/bin/start-sonarqube

# Criar serviço systemd aprimorado
cat > /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target postgresql.service
Wants=postgresql.service

[Service]
Type=forking
ExecStart=/usr/local/bin/start-sonarqube
ExecStop=/bin/bash -c "sudo -u sonarqube $SONAR_SH stop"
User=root
Group=root
Restart=always
RestartSec=10
LimitNOFILE=131072
LimitNPROC=8192
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

# Recarregar configurações do systemd
systemctl daemon-reload

# Habilitar e iniciar serviço
echo "=== Habilitando e iniciando o serviço SonarQube ==="
systemctl enable sonarqube
systemctl start sonarqube

# Aguardar o serviço iniciar (tempo aumentado para 2 minutos)
echo "Aguardando o SonarQube iniciar (pode levar alguns minutos)..."
for i in {1..24}; do
  sleep 5
  if curl -s http://localhost:9000 > /dev/null; then
    echo "SonarQube está no ar!"
    break
  else
    echo "Aguardando SonarQube iniciar... ${i}/24"
    
    # A cada 20 segundos, verificar status do serviço
    if [ $((i % 4)) -eq 0 ]; then
      echo "Status do serviço:"
      systemctl status sonarqube --no-pager
    fi
  fi
done

# Verificar se o serviço está rodando
if ! systemctl is-active --quiet sonarqube; then
  echo "ALERTA: Serviço sonarqube não está ativo. Tentando iniciar novamente..."
  systemctl restart sonarqube
  sleep 30
  
  # Verificar logs para diagnóstico
  echo "=== Últimas linhas dos logs do SonarQube ==="
  tail -n 50 /opt/sonarqube/logs/sonar.log || echo "Logs não encontrados"
fi

# Instalar Nginx como proxy reverso
apt-get install -y nginx

# Configurar Nginx
cat > /etc/nginx/sites-available/sonarqube << EOF
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
EOF

ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube || true
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Criar script de monitoramento e reinicialização
cat > /usr/local/bin/check-sonarqube << EOF
#!/bin/bash
# Script para verificar e reiniciar SonarQube se necessário
if ! curl -s http://localhost:9000 > /dev/null; then
  echo "\$(date) - SonarQube não está respondendo. Reiniciando..." >> /var/log/sonarqube-monitor.log
  systemctl restart sonarqube
else
  echo "\$(date) - SonarQube está operacional" >> /var/log/sonarqube-monitor.log
fi
EOF

chmod +x /usr/local/bin/check-sonarqube

# Adicionar ao crontab para verificar a cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check-sonarqube") | crontab -

# Configurar reinicialização na inicialização
cat > /etc/rc.local << EOF
#!/bin/bash
# Garantir que SonarQube inicie no boot
systemctl start sonarqube
exit 0
EOF

chmod +x /etc/rc.local

# Obter informações de acesso
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Verificar status final
echo "=== Verificação final ==="
systemctl status sonarqube --no-pager
curl -I http://localhost:9000 || echo "SonarQube ainda não está respondendo na porta 9000"

echo ""
echo "=== Resumo da instalação do SonarQube ==="
echo "Data de conclusão: $(date)"
echo "SonarQube URL: http://$PUBLIC_IP"
echo "URL Alternativa: http://$PUBLIC_IP:9000 (acesso direto)"
echo "Usuário: admin"
echo "Senha: admin"
echo ""
echo "IMPORTANTE: Para acessar, use as credenciais padrão:"
echo "  - Login: admin"
echo "  - Senha: admin"
echo "Você deverá alterar a senha no primeiro login!"
echo ""
echo "Para verificar o status do serviço: sudo systemctl status sonarqube"
echo "Para ver os logs: sudo tail -f /opt/sonarqube/logs/sonar.log"
echo "Para reiniciar manualmente: sudo systemctl restart sonarqube"
echo ""
echo "Um monitor de verificação foi configurado para reiniciar o serviço automaticamente se necessário."
echo "=== Instalação Concluída ==="

# Criar um arquivo com as credenciais para fácil referência
cat > /home/ubuntu/sonarqube-credentials.txt << EOF
SonarQube URL: http://$PUBLIC_IP
Usuário: admin
Senha: admin

Para verificar o status: sudo systemctl status sonarqube
Para ver os logs: sudo tail -f /opt/sonarqube/logs/sonar.log
Para reiniciar: sudo systemctl restart sonarqube
EOF

chown ubuntu:ubuntu /home/ubuntu/sonarqube-credentials.txt
chmod 600 /home/ubuntu/sonarqube-credentials.txt