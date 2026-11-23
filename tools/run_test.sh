#!/bin/bash
APP_IP=$1
RUNTIME=$2
TEST_TYPE=$3
ITER=$4

mkdir -p ~/tools/results
rm -f ~/tools/results/*
chmod 777 ~/tools/results
cd ~/tools

echo "[{\"targets\": [\"${APP_IP}:80\"]}]" > targets.json

sleep 2

curl -s -X POST http://${APP_IP}/reset

if [ "${RUNTIME}" = "java-jit" ] && [[ "${TEST_TYPE}" != *"spike"* ]]; then
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

sleep 5

METRICS="process_cpu_usage|system_cpu_usage|jvm_memory_used_bytes|jvm_memory_committed_bytes|hikaricp_connections_active|hikaricp_connections_pending|process_cpu_seconds_total|go_memstats_alloc_bytes|pgxpool_acquired_conns|pgxpool_empty_acquire_count|jvm_threads_live_threads|jvm_threads_virtual_active|go_goroutines|jvm_gc_pause_seconds_max|go_gc_duration_seconds|go_memstats_sys_bytes"
gzip -f ~/tools/results/${TEST_TYPE}_iter_${ITER}_k6.csv
curl -s -g "http://localhost:9090/api/v1/query_range?query={__name__=~\"${METRICS}\"}&start=${START_TIME}&end=${END_TIME}&step=1s" > ~/tools/results/${TEST_TYPE}_iter_${ITER}.json

curl -s -X POST http://${APP_IP}/teardown

sleep 15