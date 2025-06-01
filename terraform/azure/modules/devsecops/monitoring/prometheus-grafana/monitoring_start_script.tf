# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Script de inicialização melhorado
resource "local_file" "monitoring_start_script" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/start-monitoring.sh"
  content  = <<-EOF
#!/bin/bash
set -e

echo "🚀 Iniciando Monitoring Stack..."

# Função de cleanup
cleanup() {
    echo "🛑 Parando serviços..."
    if [ ! -z "$PROMETHEUS_PID" ]; then
        kill -TERM $PROMETHEUS_PID 2>/dev/null || true
    fi
    if [ ! -z "$GRAFANA_PID" ]; then
        kill -TERM $GRAFANA_PID 2>/dev/null || true
    fi
    # Aguardar um pouco para os processos terminarem graciosamente
    sleep 3
    # Forçar kill se ainda estiverem rodando
    if [ ! -z "$PROMETHEUS_PID" ]; then
        kill -KILL $PROMETHEUS_PID 2>/dev/null || true
    fi
    if [ ! -z "$GRAFANA_PID" ]; then
        kill -KILL $GRAFANA_PID 2>/dev/null || true
    fi
    wait 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Verificar se os arquivos de configuração existem
echo "🔍 Verificando arquivos de configuração..."
if [ ! -f "/etc/prometheus/prometheus.yml" ]; then
    echo "❌ Arquivo de configuração do Prometheus não encontrado"
    exit 1
fi

if [ ! -f "/etc/grafana/provisioning/datasources/datasources.yml" ]; then
    echo "❌ Arquivo de configuração do datasource do Grafana não encontrado"
    exit 1
fi

# Criar diretórios se não existirem e definir permissões
echo "📁 Preparando diretórios..."
mkdir -p /var/lib/prometheus /var/lib/grafana /var/log/grafana

# Verificar se usuário grafana existe antes de usar chown
if id grafana >/dev/null 2>&1; then
    echo "👤 Configurando permissões para usuário grafana..."
    chown -R grafana:grafana /var/lib/grafana /var/lib/prometheus /var/log/grafana
else
    echo "⚠️ Usuário grafana não encontrado, usando permissões padrão..."
    chmod -R 777 /var/lib/prometheus /var/lib/grafana /var/log/grafana
fi

# Iniciar Prometheus em background
echo "🔥 Iniciando Prometheus..."
prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --web.listen-address=0.0.0.0:9090 \
    --log.level=info \
    --web.enable-lifecycle \
    --web.enable-admin-api \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.console.templates=/etc/prometheus/consoles > /var/log/prometheus.log 2>&1 &

PROMETHEUS_PID=$!
echo "Prometheus PID: $PROMETHEUS_PID"

# Aguardar Prometheus estar pronto
echo "⏳ Aguardando Prometheus iniciar..."
for i in {1..30}; do
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo "✅ Prometheus está rodando!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout: Prometheus não iniciou após 60 segundos"
        echo "📋 Últimas linhas do log do Prometheus:"
        tail -10 /var/log/prometheus.log 2>/dev/null || echo "Log não disponível"
        kill $PROMETHEUS_PID 2>/dev/null || true
        exit 1
    fi
    echo "Tentativa $i/30... (aguardando Prometheus)"
    sleep 2
done

# Configurar variáveis do Grafana
export GF_SECURITY_ADMIN_PASSWORD=admin
export GF_USERS_ALLOW_SIGN_UP=false
export GF_INSTALL_PLUGINS=""
export GF_PATHS_DATA=/var/lib/grafana
export GF_PATHS_LOGS=/var/log/grafana
export GF_PATHS_PLUGINS=/var/lib/grafana/plugins
export GF_PATHS_PROVISIONING=/etc/grafana/provisioning

# Iniciar Grafana
echo "📈 Iniciando Grafana..."
if id grafana >/dev/null 2>&1; then
    # Se usuário grafana existe, usar su
    su grafana -c "/run.sh" > /var/log/grafana/grafana.log 2>&1 &
else
    # Se não existe, rodar diretamente
    /run.sh > /var/log/grafana.log 2>&1 &
fi

GRAFANA_PID=$!
echo "Grafana PID: $GRAFANA_PID"

# Aguardar Grafana estar pronto
echo "⏳ Aguardando Grafana iniciar..."
for i in {1..60}; do
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Grafana está rodando!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Timeout: Grafana não iniciou após 120 segundos"
        echo "📋 Últimas linhas do log do Grafana:"
        tail -10 /var/log/grafana.log 2>/dev/null || echo "Log do Grafana não disponível"
        kill $PROMETHEUS_PID $GRAFANA_PID 2>/dev/null || true
        exit 1
    fi
    echo "Tentativa $i/60... (aguardando Grafana)"
    sleep 2
done

echo ""
echo "🎉 Monitoring Stack iniciado com sucesso!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Grafana:    http://localhost:3000"
echo "   Usuário:    admin"
echo "   Senha:      admin"
echo ""
echo "🔥 Prometheus: http://localhost:9090"
echo ""
echo "🔍 Health Checks:"
echo "   Grafana:    http://localhost:3000/api/health"
echo "   Prometheus: http://localhost:9090/-/healthy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "👀 Logs disponíveis em:"
echo "   Prometheus: /var/log/prometheus.log"
echo "   Grafana:    /var/log/grafana.log"
echo ""
echo "🔄 Para parar os serviços, pressione Ctrl+C"

# Função para mostrar status periodicamente
show_status() {
    while true; do
        sleep 300  # A cada 5 minutos
        echo "📊 Status $(date): Prometheus (PID: $PROMETHEUS_PID) | Grafana (PID: $GRAFANA_PID)"
    done
}

# Iniciar status em background
show_status &
STATUS_PID=$!

# Manter o script rodando e aguardar os processos
wait $PROMETHEUS_PID $GRAFANA_PID

# Limpar processo de status
kill $STATUS_PID 2>/dev/null || true
EOF
}