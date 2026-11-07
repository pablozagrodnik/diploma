#!/bin/bash

APP_IP=$1
RUNTIME=$2
TEST_TYPE=$3
ITER=$4

# 1. Tworzenie osobnego katalogu dla każdego środowiska
RESULTS_DIR="$(pwd)/results/${RUNTIME}/${TEST_TYPE}"
mkdir -p "$RESULTS_DIR"
chmod 777 "$RESULTS_DIR"

echo "[{\"targets\": [\"${APP_IP}\"]}]" > targets.json
sleep 2

curl -s -X POST http://${APP_IP}/reset

if [ "${RUNTIME}" = "java-jit" ] && [[ "${TEST_TYPE}" != *"spike"* ]]; then
  echo "JVM Warmup"
  podman-compose run --rm -e API_URL=http://${APP_IP} k6 run /scripts/warmup.js
  curl -s -X POST http://${APP_IP}/reset
fi

START_TIME=$(date +%s)

# 2. Flaga :z przy /results naprawiająca problem z uprawnieniami (SELinux) na Fedorze
podman-compose run --rm \
  -v "${RESULTS_DIR}:/results:z" \
  -e API_URL=http://${APP_IP} \
  -e K6_PROMETHEUS_RW_SERVER_URL=http://prometheus:9090/api/v1/write \
  k6 run -o experimental-prometheus-rw --out csv=/results/${TEST_TYPE}_iter_${ITER}_k6.csv /scripts/${TEST_TYPE}.js

END_TIME=$(date +%s)

# 3. Dajemy Prometheusowi czas na przetworzenie zdalnych metryk (Remote Write) z k6
sleep 5

METRICS="process_cpu_usage|system_cpu_usage|jvm_memory_used_bytes|jvm_memory_committed_bytes|hikaricp_connections_active|hikaricp_connections_pending|process_cpu_seconds_total|go_memstats_alloc_bytes|pgxpool_acquired_conns|pgxpool_empty_acquire_count|jvm_threads_live_threads|go_goroutines|jvm_gc_pause_seconds_max|go_gc_duration_seconds|go_memstats_sys_bytes"

# 4. Bezpieczna kompresja - tylko jeśli plik faktycznie powstał
if [ -f "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}_k6.csv" ]; then
    gzip -f "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}_k6.csv"
else
    echo "BŁĄD: Plik CSV z wynikami k6 nie został wygenerowany!"
fi

curl -s -g "http://localhost:9090/api/v1/query_range?query={__name__=~\"${METRICS}\"}&start=${START_TIME}&end=${END_TIME}&step=1s" > "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}.json"

curl -s -X POST http://${APP_IP}/teardown
sleep 15