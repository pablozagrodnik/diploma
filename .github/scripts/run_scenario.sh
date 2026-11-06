#!/usr/bin/env bash
set -euo pipefail

gcloud container clusters get-credentials "$CLUSTER_NAME" --zone=europe-central2-a
gcloud config set storage/parallel_composite_upload_enabled False
REPO=$(echo "$GITHUB_REPO" | tr '[:upper:]' '[:lower:]')
ITERATIONS=5

for RUNTIME in java-jit java-native go; do
  echo "--- Runtime: $RUNTIME | Scenario: $TEST_TYPE ---"

  helm uninstall thesis-api --ignore-not-found --wait
  kubectl delete svc thesis-api --ignore-not-found --wait

  helm upgrade --install thesis-api ./k8s/thesis-api \
    --set image.repository="ghcr.io/$REPO/thesis-api-$RUNTIME" \
    --set image.tag=latest \
    --set env.DB_HOST="$DB_IP" \
    --set env.DB_USER=postgres \
    --set env.DB_PASSWORD="$DB_PASS"

  APP_IP=""
  while [ -z "$APP_IP" ]; do
    sleep 6
    APP_IP=$(kubectl get svc -l app.kubernetes.io/instance=thesis-api -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  done

  gcloud compute ssh runner@tools-vm --quiet --zone=europe-central2-a --tunnel-through-iap \
    --command="while ! curl -s -o /dev/null -w '%{http_code}' http://$APP_IP/health | grep -q '200'; do echo 'Waiting for LoadBalancer...'; sleep 5; done"

  for i in $(seq 1 $ITERATIONS); do
    echo "--- $RUNTIME : $TEST_TYPE : iter $i ---"

    kubectl rollout restart deployment thesis-api
    kubectl rollout status deployment thesis-api --timeout=240s

    gcloud compute ssh runner@tools-vm --quiet --zone=europe-central2-a --tunnel-through-iap \
      --command="bash ~/tools/run_test.sh $APP_IP $RUNTIME $TEST_TYPE ${i}"

    gcloud compute scp \
      "runner@tools-vm:~/tools/results/${TEST_TYPE}_iter_${i}_k6.csv.gz" \
      "runner@tools-vm:~/tools/results/${TEST_TYPE}_iter_${i}.json" \
      . --zone=europe-central2-a --tunnel-through-iap

    gcloud storage cp \
      "${TEST_TYPE}_iter_${i}_k6.csv.gz" \
      "${TEST_TYPE}_iter_${i}.json" \
      "gs://thesis-test-results/run-${RUN_ID}/${RUNTIME}/${TEST_TYPE}/"
  done
done