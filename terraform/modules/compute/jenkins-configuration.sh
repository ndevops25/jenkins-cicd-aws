#!/bin/bash

# Script completo: Instalação + Configuração Automática do Jenkins
# Para ser usado no user-data do Terraform

# Redirecionar saída para log
exec > >(tee /var/log/user-data-jenkins.log)
exec 2>&1

echo "=== Script de Instalação e Configuração do Jenkins ==="
echo "Data: $(date)"

# Variáveis de configuração
JENKINS_USER="JENKINS_USER"
JENKINS_PASS="JENKINS_PASS"  # MUDE ESTA SENHA!
GITHUB_USER="YOUR_GITHUB_USER"        # CONFIGURE SEU USUÁRIO
GITHUB_TOKEN="YOUR_GITHUB_TOKEN"         # CONFIGURE SEU TOKEN

# Função para verificar erro
check_error() {
    if [ $? -ne 0 ]; then
        echo "ERRO: $1"
        return 1
    fi
    return 0
}

# PARTE 1: INSTALAÇÃO
echo "=== PARTE 1: Instalação do Jenkins e Dependências ==="

# Aguardar cloud-init
cloud-init status --wait

# Atualizar sistema
apt-get update -y

# Instalar Java 17
apt-get install -y openjdk-17-jdk

# Instalar Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins

# Instalar Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar ferramentas adicionais
apt-get install -y git jq unzip

# Configurar permissões
usermod -aG docker ubuntu
usermod -aG docker jenkins

# Iniciar serviços
systemctl enable jenkins docker
systemctl start jenkins docker

# Aguardar Jenkins estar pronto
echo "=== Aguardando Jenkins iniciar ==="
while ! curl -s http://localhost:8080 > /dev/null; do
    sleep 10
done

# PARTE 2: CONFIGURAÇÃO AUTOMÁTICA
echo "=== PARTE 2: Configuração Automática do Jenkins ==="

JENKINS_HOME="/var/lib/jenkins"

# Desabilitar setup wizard
echo "JAVA_ARGS=\"-Djenkins.install.runSetupWizard=false\"" >> /etc/default/jenkins

# Criar diretórios necessários
mkdir -p $JENKINS_HOME/init.groovy.d
mkdir -p $JENKINS_HOME/casc_configs

# Script 1: Criar usuário admin e configurar segurança
cat > $JENKINS_HOME/init.groovy.d/01-security.groovy << EOF
#!groovy
import jenkins.model.*
import hudson.security.*
import hudson.model.User

def instance = Jenkins.getInstance()

// Criar usuário admin
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${JENKINS_USER}", "${JENKINS_PASS}")
instance.setSecurityRealm(hudsonRealm)

// Configurar estratégia de autorização
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("Segurança configurada")
EOF

# Script 2: Instalar plugins essenciais
cat > $JENKINS_HOME/init.groovy.d/02-plugins.groovy << 'EOF'
#!groovy
import jenkins.model.*
import hudson.model.*
import java.util.logging.Logger

def logger = Logger.getLogger("")
def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

// Atualizar centro de updates
uc.updateAllSites()

def plugins = [
    "git",
    "github",
    "workflow-aggregator",
    "docker-workflow",
    "docker-plugin",
    "credentials",
    "ssh-credentials",
    "github-branch-source",
    "pipeline-stage-view",
    "ansicolor",
    "timestamper",
    "configuration-as-code"
]

def availablePlugins = uc.getAvailables()

plugins.each { pluginName ->
    logger.info("Verificando plugin: ${pluginName}")
    if (!pm.getPlugin(pluginName)) {
        def plugin = availablePlugins.find { it.name == pluginName }
        if (plugin) {
            logger.info("Instalando: ${pluginName}")
            plugin.deploy(true)
        }
    }
}

instance.save()
logger.info("Plugins instalados")
EOF

# Script 3: Configurações básicas
cat > $JENKINS_HOME/init.groovy.d/03-settings.groovy << EOF
#!groovy
import jenkins.model.*
import hudson.model.*

def instance = Jenkins.getInstance()

// URL do Jenkins
def locationConfig = instance.getExtensionList(jenkins.model.JenkinsLocationConfiguration.class)[0]
locationConfig.setUrl("http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/")
locationConfig.save()

// Configurar executores
instance.setNumExecutors(2)
instance.setMode(hudson.model.Node.Mode.NORMAL)

// Mensagem do sistema
instance.setSystemMessage("Jenkins CI/CD - Configurado Automaticamente")

instance.save()
println("Configurações aplicadas")
EOF

# Script 4: Criar credenciais do GitHub
cat > $JENKINS_HOME/init.groovy.d/04-credentials.groovy << EOF
#!groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import hudson.util.Secret

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Credenciais do GitHub
def githubCreds = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-credentials",
    "GitHub credentials",
    "${GITHUB_USER}",
    "${GITHUB_TOKEN}"
)

store.addCredentials(domain, githubCreds)
println("Credenciais criadas")
EOF

# Criar configuração JCasC
cat > $JENKINS_HOME/casc_configs/jenkins.yaml << EOF
jenkins:
  systemMessage: "Jenkins CI/CD - CP2"
  numExecutors: 2
  
  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false
  
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "${JENKINS_USER}"
          password: "${JENKINS_PASS}"

  clouds:
    - docker:
        name: "docker"
        dockerApi:
          dockerHost:
            uri: "unix:///var/run/docker.sock"
        templates:
          - labelString: "docker-agent"
            dockerTemplateBase:
              image: "jenkins/agent:latest"
            remoteFs: "/home/jenkins/agent"

unclassified:
  location:
    url: "http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/"
  gitscm:
    globalConfigName: "Jenkins"
    globalConfigEmail: "jenkins@example.com"
EOF

# Ajustar permissões
chown -R jenkins:jenkins $JENKINS_HOME/

# Reiniciar Jenkins com as novas configurações
systemctl restart jenkins

# Aguardar reinicialização
echo "=== Aguardando Jenkins reiniciar ==="
sleep 60
while ! curl -s http://localhost:8080 > /dev/null; do
    sleep 10
done

# Criar arquivo de informações
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
cat > /home/ubuntu/jenkins_info.txt << EOL
=== Informações do Jenkins ===
URL: http://${PUBLIC_IP}:8080
Usuário: ${JENKINS_USER}
Senha: ${JENKINS_PASS}
GitHub User: ${GITHUB_USER}
Configurado em: $(date)

IMPORTANTE: Mude a senha padrão!
============================
EOL

chmod 600 /home/ubuntu/jenkins_info.txt
chown ubuntu:ubuntu /home/ubuntu/jenkins_info.txt

echo "=== Instalação e Configuração Concluídas ==="
echo "Jenkins URL: http://${PUBLIC_IP}:8080"
echo "Usuário: ${JENKINS_USER}"
echo "Veja mais informações em: /home/ubuntu/jenkins_info.txt"