#!/bin/bash

# Script Mínimo para Garantir Conexão SSH
echo "=== User Data Script Iniciando - $(date) ===" > /var/log/user-data.log 2>&1

# Aguardar rede estar pronta
sleep 10

# Atualizar sistema (mínimo necessário)
apt-get update -y >> /var/log/user-data.log 2>&1

# Instalar apenas o essencial para SSH funcionar
apt-get install -y openssh-server >> /var/log/user-data.log 2>&1

# Garantir que SSH está rodando
systemctl enable ssh >> /var/log/user-data.log 2>&1
systemctl start ssh >> /var/log/user-data.log 2>&1

# Criar arquivo de teste para verificar se script rodou
echo "User data executado em: $(date)" > /home/ubuntu/userdata-test.txt
chown ubuntu:ubuntu /home/ubuntu/userdata-test.txt

echo "=== User Data Script Concluído - $(date) ===" >> /var/log/user-data.log 2>&1