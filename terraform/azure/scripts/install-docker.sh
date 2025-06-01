#!/bin/bash

# Atualizar pacotes
sudo apt-get update
sudo apt-get upgrade -y

# Instalar pré-requisitos
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar a chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Adicionar o repositório do Docker aos sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Atualizar o banco de dados de pacotes
sudo apt-get update

# Instalar a versão mais recente do Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Adicionar o usuário ao grupo Docker para não precisar usar sudo
sudo usermod -aG docker ${USER}
sudo usermod -aG docker ubuntu

# Habilitar o serviço Docker para iniciar na inicialização do sistema
sudo systemctl enable docker
sudo systemctl start docker

# Confirmar a instalação
docker --version
docker-compose --version

echo "Docker instalado com sucesso!"