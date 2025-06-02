#!/bin/bash
set -e

echo "🚀 Iniciando Monitoring Stack..."

# Função de cleanup
cleanup() {
    echo "🛑 Parando serviços..."
    if [ ! -z "$PROMETHEUS_PID" ]; then
        kill $PROMETHEUS_PID 2>/dev/null || true
    fi
    if [ ! -z "$GRAFANA_PID" ]; then
        kill $GRAFANA_PID 2>/dev/null || true
    fi
    wait 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Verificar se os arquivos de configuração existem
if [ ! -f "/etc/prometheus/prometheus.yml" ]; then
    echo "❌ Arquivo de configuração do Prometheus não encontrado"
    exit 1
fi

# Iniciar Prometheus em background
echo "🔥 Iniciando Prometheus..."
prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --web.listen-address=0.0.0.0:9090 \
    --log.level=info \
    --web.enable-lifecycle &

PROMETHEUS_PID=$!
echo "Prometheus PID: $PROMETHEUS_PID"

# Aguardar Prometheus estar pronto
echo "⏳ Aguardando Prometheus..."
for i in {1..30}; do
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo "✅ Prometheus está rodando!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout: Prometheus não iniciou"
        exit 1
    fi
    sleep 2
done

# Iniciar Grafana
echo "📈 Iniciando Grafana..."
/run.sh &

GRAFANA_PID=$!
echo "Grafana PID: $GRAFANA_PID"

# Aguardar Grafana estar pronto
echo "⏳ Aguardando Grafana..."
for i in {1..60}; do
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Grafana está rodando!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Timeout: Grafana não iniciou"
        exit 1
    fi
    sleep 2
done

echo "🎉 Monitoring Stack iniciado com sucesso!"
echo "📊 Grafana: http://localhost:3000 (admin/admin)"
echo "🔥 Prometheus: http://localhost:9090"
echo "🔍 Health Grafana: http://localhost:3000/api/health"
echo "🔍 Health Prometheus: http://localhost:9090/-/healthy"

# Manter o script rodando
wait $PROMETHEUS_PID $GRAFANA_PID
