#!/bin/bash
# Script corrigido para configurar Jenkins com Docker
# Versão 2.0 - Com correção de permissões

set -e  # Parar execução em caso de erro

echo "=== Configurando Jenkins com Docker ==="

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker não encontrado. Instalando Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
    echo "Docker instalado com sucesso!"
fi

# Parar o serviço Jenkins nativo (se estiver rodando)
echo "Parando serviço Jenkins nativo..."
sudo systemctl stop jenkins || true
sudo systemctl disable jenkins || true
echo "Serviço Jenkins parado e desabilitado."

# Criar diretórios para dados do Jenkins
echo "Criando diretórios para o Jenkins..."
mkdir -p ~/jenkins_home
sudo chmod 777 ~/jenkins_home

# Remover container Jenkins existente (se existir)
echo "Removendo containers existentes..."
docker rm -f jenkins 2>/dev/null || true

# Criar rede dedicada para o Jenkins
docker network create jenkins-network 2>/dev/null || true

# Iniciar o Jenkins com Docker - usando imagem especial para DinD
echo "Iniciando Jenkins com Docker..."
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --network jenkins-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v ~/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  --group-add $(getent group docker | cut -d: -f3) \
  jenkins/jenkins:lts-jdk17

# Aguardar Jenkins iniciar (ajustado para ser mais confiável)
echo "Aguardando Jenkins iniciar..."
for i in {1..30}; do
  if docker logs jenkins 2>&1 | grep -q "Jenkins is fully up and running"; then
    echo "Jenkins iniciado com sucesso!"
    break
  elif [ $i -eq 30 ]; then
    echo "Tempo limite excedido. Verificando logs:"
    docker logs --tail 50 jenkins
  else
    echo "Ainda iniciando Jenkins... ($i/30)"
    sleep 10
  fi
done

# Obter senha inicial do Jenkins
echo "Obtendo senha inicial do Jenkins..."
sleep 5
JENKINS_PASSWORD=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword || echo "Não foi possível obter a senha. Tente: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword")

# Instalar plugins essenciais via CLI
echo "Instalando plugins essenciais..."
docker exec jenkins jenkins-plugin-cli --plugins \
  aws-credentials \
  amazon-ecr \
  pipeline-aws \
  docker-workflow \
  pipeline-stage-view \
  blueocean || echo "Aviso: Falha ao instalar plugins. Você pode instalá-los manualmente pela interface web."

# Verificar se o Docker funciona dentro do container
echo "Verificando acesso ao Docker..."
docker exec jenkins sh -c "docker version || echo 'Aviso: Docker não disponível dentro do container. Use o host Docker em pipelines.'"

# Obter IP público
IP_PUBLICO=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Mostrar informações
echo ""
echo "=== Jenkins Configurado com Sucesso! ==="
echo "URL do Jenkins: http://$IP_PUBLICO:8080"
echo "Senha inicial: $JENKINS_PASSWORD"
echo ""
echo "IMPORTANTE: Para usar Docker nos pipelines, adicione o seguinte no seu Jenkinsfile:"
echo "pipeline {"
echo "  agent {"
echo "    docker {"
echo "      image 'seu-container'"
echo "      args '-v /var/run/docker.sock:/var/run/docker.sock'"
echo "    }"
echo "  }"
echo "}"
echo ""
echo "Para visualizar logs: docker logs -f jenkins"
echo "Para reiniciar: docker restart jenkins"
echo "Para parar: docker stop jenkins"
echo "==================================="

# Salvar informações em um arquivo
cat > ~/jenkins_info.txt << EOF
=== Informações do Jenkins ===
URL: http://$IP_PUBLICO:8080
Senha inicial: $JENKINS_PASSWORD
Configurado em: $(date)

Comandos úteis:
* Ver logs: docker logs -f jenkins
* Reiniciar: docker restart jenkins
* Parar: docker stop jenkins
* Iniciar: docker start jenkins
============================
EOF

chmod 600 ~/jenkins_info.txt
echo "Informações salvas em ~/jenkins_info.txt"