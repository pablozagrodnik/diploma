#!/bin/bash
APP_IP=$1
RUNTIME=$2
TEST_TYPE=$3
ITER=$4

mkdir -p ~/tools/results
chmod 777 ~/tools/results
cd ~/tools

echo "[{\"targets\": [\"${APP_IP}:80\"]}]" > targets.json
sudo docker-compose up -d

curl -s -X POST http://${APP_IP}/reset

if [ "${RUNTIME}" = "java-jit" ]; then
  echo "JVM Warmup"
  sudo docker-compose run --rm -e API_URL=http://${APP_IP} k6 run /scripts/warmup.js

  curl -s -X POST http://${APP_IP}/reset
fi

START_TIME=$(date +%s)

sudo docker-compose run --rm \
  -v /home/runner/tools/results:/results \
  -e API_URL=http://${APP_IP} \
  -e K6_PROMETHEUS_RW_SERVER_URL=http://prometheus:9090/api/v1/write \
  k6 run -o experimental-prometheus-rw --out csv=/results/${TEST_TYPE}_iter_${ITER}_k6.csv /scripts/${TEST_TYPE}.js

END_TIME=$(date +%s)
METRICS="process_cpu_usage|system_cpu_usage|jvm_memory_used_bytes|hikaricp_connections_active|process_cpu_seconds_total|go_memstats_alloc_bytes|pgxpool_acquired_conns"

curl -s -g "http://localhost:9090/api/v1/query_range?query={__name__=~\"${METRICS}\"}&start=${START_TIME}&end=${END_TIME}&step=5s" > ~/tools/results/${TEST_TYPE}_iter_${ITER}.json