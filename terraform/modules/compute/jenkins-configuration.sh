#!/bin/bash

# Redirecionar saída para log
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Iniciando User Data Script ==="
echo "Data: $(date)"

# Função para verificar erro
check_error() {
    if [ $? -ne 0 ]; then
        echo "ERRO: $1"
        exit 1
    fi
}

# Aguardar cloud-init terminar
cloud-init status --wait
check_error "Esperando cloud-init"

# Atualizar sistema
echo "=== Atualizando Sistema ==="
apt-get update -y
check_error "apt-get update"

# Remover Java antigo se existir
echo "=== Removendo Java antigo ==="
apt-get remove -y openjdk-11-* || true

# Instalar Java 17
echo "=== Instalando Java 17 ==="
apt-get install -y openjdk-17-jdk
check_error "Instalação do Java 17"

# Verificar versão do Java
java -version

# Adicionar chave do Jenkins
echo "=== Configurando Repositório Jenkins ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
check_error "Adicionar chave Jenkins"

# Adicionar repositório
sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
check_error "Adicionar repositório Jenkins"

# Atualizar novamente
apt-get update -y
check_error "apt-get update após repo"

# Instalar Jenkins
echo "=== Instalando Jenkins ==="
apt-get install -y jenkins
check_error "Instalação do Jenkins"

# Instalar Docker
echo "=== Instalando Docker ==="
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Adicionar chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Adicionar repositório Docker
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Instalar Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
check_error "Instalação do Docker"

# Instalar outras ferramentas necessárias
echo "=== Instalando ferramentas adicionais ==="
apt-get install -y git curl wget unzip jq
check_error "Instalação de ferramentas"

# Configurar permissões
echo "=== Configurando Permissões ==="
usermod -aG docker ubuntu
usermod -aG docker jenkins

# Configurar Docker para iniciar no boot
systemctl enable docker
systemctl start docker

# Configurar Jenkins
echo "=== Configurando Jenkins ==="
# Ajustar configurações do Jenkins se necessário
# sed -i 's/JENKINS_PORT=8080/JENKINS_PORT=8080/g' /etc/default/jenkins

# Habilitar e iniciar Jenkins
systemctl enable jenkins
systemctl start jenkins

# Aguardar Jenkins iniciar completamente
echo "=== Aguardando Jenkins iniciar ==="
for i in {1..30}; do
    if systemctl is-active --quiet jenkins; then
        echo "Jenkins está ativo"
        break
    fi
    echo "Aguardando Jenkins... tentativa $i/30"
    sleep 10
done

# Verificar se Jenkins está rodando
if ! systemctl is-active --quiet jenkins; then
    echo "ERRO: Jenkins não iniciou corretamente"
    systemctl status jenkins
    journalctl -u jenkins -n 50
else
    echo "Jenkins iniciado com sucesso"
fi

# Instalar Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar || true

# Verificar status final
echo "=== Status dos Serviços ==="
systemctl status jenkins --no-pager
systemctl status docker --no-pager

# Mostrar informações importantes
echo "=== Informações Importantes ==="
echo "IP Público: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

# Mostrar senha inicial do Jenkins
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "Senha inicial do Jenkins:"
    cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Arquivo de senha inicial ainda não criado. Verifique mais tarde em:"
    echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

echo "=== User Data Script Concluído ==="
echo "Logs salvos em: /var/log/user-data.log"