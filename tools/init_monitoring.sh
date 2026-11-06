#!/bin/bash
cd ~/tools

echo "[]" > targets.json

sudo docker-compose pull --quiet
sudo docker-compose up -d

echo "Waiting for Prometheus..."
while ! curl -s -f http://localhost:9090/-/ready > /dev/null 2>&1; do
  sleep 2
done
sleep 5
echo "Monitoring ready"