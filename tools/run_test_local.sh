#!/bin/bash

APP_IP=$1
RUNTIME=$2
TEST_TYPE=$3
ITER=$4

RESULTS_DIR="$(pwd)/results/${RUNTIME}/${TEST_TYPE}"
mkdir -p "$RESULTS_DIR"
chmod 777 "$RESULTS_DIR"

HEALTH_CSV="${RESULTS_DIR}/system_health_summary.csv"
if [ ! -f "$HEALTH_CSV" ]; then
    echo "iter,timestamp,temp_start_c,temp_end_c,ram_used_start_mb,ram_used_end_mb,swap_used_mb,oom_detected" > "$HEALTH_CSV"
fi

get_cpu_temp() {
    local temp=$(sensors 2>/dev/null | awk '/Tctl:/ {gsub(/[+°C]/,"",$2); print $2; exit}')
    if [ -z "$temp" ]; then
        for f in /sys/class/hwmon/hwmon*/temp1_input; do
            if [ -f "$f" ]; then
                temp=$(awk '{printf "%.1f", $1/1000}' "$f" 2>/dev/null)
                break
            fi
        done
    fi
    echo "${temp:-0}"
}

get_ram_used() {
    free -m | awk '/Mem:/ {print $3}'
}

get_swap_used() {
    free -m | awk '/Swap:/ {print $3}'
}

TEMP_START=$(get_cpu_temp)
RAM_START=$(get_ram_used)
SWAP_START=$(get_swap_used)
DMESG_LINES_BEFORE=$(dmesg | wc -l)

echo "[SANITY] Iter $ITER Start -> CPU: ${TEMP_START}°C | RAM: ${RAM_START}MB | Swap: ${SWAP_START}MB"

echo "[{\"targets\": [\"${APP_IP}\"]}]" > targets.json
sleep 2

curl -s -X POST http://${APP_IP}/reset

if [ "${RUNTIME}" = "java-jit" ] && [[ "${TEST_TYPE}" != *"spike"* ]]; then
  echo "JVM Warmup"
  podman-compose run --rm -e API_URL=http://${APP_IP} k6 run /scripts/warmup.js
  curl -s -X POST http://${APP_IP}/reset
fi

START_TIME=$(date +%s)

podman-compose run --rm \
  -v "${RESULTS_DIR}:/results:z" \
  -e API_URL=http://${APP_IP} \
  -e K6_PROMETHEUS_RW_SERVER_URL=http://prometheus:9090/api/v1/write \
  k6 run -o experimental-prometheus-rw --out csv=/results/${TEST_TYPE}_iter_${ITER}_k6.csv /scripts/${TEST_TYPE}.js

END_TIME=$(date +%s)

TEMP_END=$(get_cpu_temp)
RAM_END=$(get_ram_used)

OOM_LOGS=$(dmesg | tail -n +"$((DMESG_LINES_BEFORE + 1))" | grep -i -E "oom[-_]killer|out of memory|killed process")
OOM_DETECTED=0

if [ -n "$OOM_LOGS" ]; then
    OOM_DETECTED=1
    echo "!!! ALARM: Wykryto zdarzenie OOM Killer w dmesg podczas iteracji $ITER !!!"
    echo "$OOM_LOGS" > "${RESULTS_DIR}/oom_error_iter_${ITER}.log"
fi

echo "${ITER},$(date +%Y-%m-%d_%H:%M:%S),${TEMP_START},${TEMP_END},${RAM_START},${RAM_END},${SWAP_START},${OOM_DETECTED}" >> "$HEALTH_CSV"
echo "[SANITY] Iter $ITER Koniec -> CPU: ${TEMP_END}°C | RAM: ${RAM_END}MB | OOM: ${OOM_DETECTED}"

sleep 5

METRICS="process_cpu_usage|system_cpu_usage|jvm_memory_used_bytes|jvm_memory_committed_bytes|hikaricp_connections_active|hikaricp_connections_pending|process_cpu_seconds_total|go_memstats_alloc_bytes|pgxpool_acquired_conns|pgxpool_empty_acquire_count|jvm_threads_live_threads|jvm_threads_virtual_active|go_goroutines|jvm_gc_pause_seconds_max|go_gc_duration_seconds|go_memstats_sys_bytes"

if [ -f "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}_k6.csv" ]; then
    gzip -f "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}_k6.csv"
else
    echo "BŁĄD: Plik CSV z wynikami k6 nie został wygenerowany!"
fi

curl -s -g "http://localhost:9090/api/v1/query_range?query={__name__=~\"${METRICS}\"}&start=${START_TIME}&end=${END_TIME}&step=1s" > "${RESULTS_DIR}/${TEST_TYPE}_iter_${ITER}.json"

curl -s -X POST http://${APP_IP}/teardown

echo "Schładzanie CPU przed kolejną iteracją..."
COOL_TIMEOUT=30
COOL_START=$(date +%s)
while true; do
    CURR_TEMP=$(get_cpu_temp | cut -d'.' -f1)
    ELAPSED=$(( $(date +%s) - COOL_START ))

    if [ "$CURR_TEMP" -le 68 ] 2>/dev/null && [ "$ELAPSED" -ge 15 ]; then
        echo "CPU ustabilizowany (${CURR_TEMP}°C po ${ELAPSED}s)."
        break
    fi

    if [ "$ELAPSED" -ge "$COOL_TIMEOUT" ]; then
        echo "Limit czasu chłodzenia osiągnięty (${ELAPSED}s, aktualnie: ${CURR_TEMP}°C)."
        break
    fi
    sleep 3
done
