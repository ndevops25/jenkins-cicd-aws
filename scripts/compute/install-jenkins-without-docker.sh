# Instalar Jenkins - Script Simplificado
sudo apt update
sudo apt install -y openjdk-17-jdk
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 1. Verificar status
sudo systemctl status jenkins

# 2. Ver se está escutando na porta
sudo netstat -tlnp | grep 8080

# 3. Obter senha
sudo cat /var/lib/jenkins/secrets/initialAdminPassword