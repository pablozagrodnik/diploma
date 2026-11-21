#!/bin/bash

echo "=== Weryfikacja środowiska hosta (Fedora / TTY) ==="

SWAP_ACTIVE=$(swapon --show | wc -l)
if [ "$SWAP_ACTIVE" -gt 0 ]; then
    echo "Aktywny Swap/zRAM"
fi

if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
    BOOST_VAL=$(cat /sys/devices/system/cpu/cpufreq/boost)
    echo "Stan AMD Core Performance Boost: $BOOST_VAL (0=wyłączony, 1=aktywny)"
fi

minikube start --driver=kvm2 --cpus=2 --memory=8192

export KUBECONFIG=~/.kube/config
kubectl config use-context minikube

podman-compose -f ../apps/docker-compose.yml down
podman-compose down

rm -rf targets.json
touch targets.json
echo "[]" > targets.json

podman-compose -f ../apps/docker-compose.yml up -d
podman-compose up -d

echo "Waiting for Prometheus..."
while ! curl -s -f http://localhost:9090/-/ready > /dev/null 2>&1; do
    sleep 2
done
sleep 5
echo "Monitoring ready"

RUNTIMES=("go" "java-jit" "java-native")
SCENARIOS=("db_stress" "cpu_stress" "cpu_constant" "cpu_linear" "cpu_spike" "db_constant" "db_linear" "db_spike" "idle")

for RUNTIME in "${RUNTIMES[@]}"; do
    echo "=== Budowanie obrazu: $RUNTIME ==="
    IMAGE_NAME="localhost/thesis/${RUNTIME}:latest"

    if [ "$RUNTIME" == "go" ]; then
        podman build -t ${IMAGE_NAME} ../apps/go-app
    elif [ "$RUNTIME" == "java-jit" ]; then
        podman build -t ${IMAGE_NAME} ../apps/java-app
    elif [ "$RUNTIME" == "java-native" ]; then
        podman build -f ../apps/java-app/Dockerfile.native -t ${IMAGE_NAME} ../apps/java-app
    fi

    echo "Ładowanie obrazu $RUNTIME do Minikube..."
    podman save -o ${RUNTIME}.tar ${IMAGE_NAME}
    minikube image load ${RUNTIME}.tar
    rm -f ${RUNTIME}.tar
done

NODE_IP=$(minikube ip)

for SCENARIO in "${SCENARIOS[@]}"; do
    for RUNTIME in "${RUNTIMES[@]}"; do
        echo "--- Runtime: $RUNTIME | Scenario: $SCENARIO ---"

        KUBECONFIG=~/.kube/config helm uninstall thesis-api --ignore-not-found --wait
        KUBECONFIG=~/.kube/config kubectl delete svc thesis-api --ignore-not-found --wait

        KUBECONFIG=~/.kube/config helm upgrade --install thesis-api ../k8s/thesis-api \
            -f ../k8s/thesis-api/values-local.yaml \
            --set image.repository=localhost/thesis/${RUNTIME} \
            --set image.tag=latest \
            --set image.pullPolicy=Never \
            --set service.type=NodePort

        KUBECONFIG=~/.kube/config kubectl rollout status deployment/thesis-api --timeout=240s

        NODE_PORT=$(KUBECONFIG=~/.kube/config kubectl get svc thesis-api -o jsonpath="{.spec.ports[0].nodePort}")
        APP_URL="${NODE_IP}:${NODE_PORT}"

        for ITER in {1..8}; do
            echo "--- $RUNTIME : $SCENARIO : iter $ITER ---"

            KUBECONFIG=~/.kube/config kubectl rollout restart deployment thesis-api

            KUBECONFIG=~/.kube/config kubectl rollout status deployment thesis-api --timeout=240s

            ./run_test_local.sh "$APP_URL" "$RUNTIME" "$SCENARIO" "$ITER"
        done
    done
done

echo "=== Sprzątanie ==="
minikube delete
podman-compose down
podman-compose -f ../apps/docker-compose.yml down
