#!/bin/bash

echo "========================================="
echo "YugabyteDB Cluster Status Check"
echo "========================================="
echo

# Проверка Masters через API
echo "=== MASTER NODES STATUS ==="
for ip in 80.208.229.107 80.209.239.227 212.24.98.67; do
  echo
  echo "Master on $ip:"
  curl -s http://$ip:7000/api/v1/masters | jq -r '.masters[] | "\(.instance_id.permanent_uuid): \(.registration.private_rpc_addresses[0].host):\(.registration.private_rpc_addresses[0].port) - Role: \(.role)"'
done

echo
echo
echo "=== TABLET SERVERS STATUS ==="
# Проверка TServers
curl -s http://80.208.229.107:7000/api/v1/tablet-servers | jq -r '.[""] | to_entries[] | "\(.key): Status=\(.value.status), RAM=\(.value.ram_used), Tablets=\(.value.active_tablets)"'

echo
echo
echo "=== DATABASES ==="
docker run --rm --network host yugabytedb/yugabyte:2024.2.6.0-b94 \
  bin/ysqlsh -h 80.208.229.107 -p 5433 -U yugabyte -c "\l"

echo
echo "=== USERS/ROLES ==="
docker run --rm --network host yugabytedb/yugabyte:2024.2.6.0-b94 \
  bin/ysqlsh -h 80.208.229.107 -p 5433 -U yugabyte -c "\du"
