# YugabyteDB 3-Node Cluster Deployment

Ansible playbook для развертывания YugabyteDB кластера из 3 нод через Docker.

## Архитектура кластера

- **3 ноды**: каждая нода запускает master + tserver
- **Replication Factor**: 3 (данные реплицируются на все 3 ноды)
- **High Availability**: кластер продолжит работу даже если 1 нода упадет

## IP адреса нод

- Node 1: `80.208.229.107` (Литва)
- Node 2: `80.209.239.227` (Литва)
- Node 3: `212.24.98.67` (Литва)

## Порты

Каждая нода использует:
- `7000` - Master WebUI
- `7100` - Master RPC
- `9000` - TServer WebUI
- `9100` - TServer RPC
- `5433` - PostgreSQL (YSQL)
- `9042` - Cassandra (YCQL)
- `13000` - YSQL metrics

## Запуск деплоя

### 1. Проверка доступности нод

```bash
cd /Users/dmitriyignatyev/projects/ansible-yb/yugabyte-deploy
ansible all -i inventory.ini -m ping
```

### 2. Запуск playbook

```bash
ansible-playbook -i inventory.ini deploy_cluster.yml
```

Playbook выполнит:
1. Установку Docker на всех нодах
2. Создание директорий для данных
3. Генерацию docker-compose.yml с правильной конфигурацией кластера
4. Запуск YugabyteDB контейнеров (master + tserver на каждой ноде)
5. Создание баз данных `soap` и `soap2`
6. Создание пользователей `superuser` и `rls_app_user`

## Подключение к кластеру

### PostgreSQL (YSQL)

Подключиться можно к **любой** из трех нод:

```bash
# Node 1
psql -h 80.208.229.107 -p 5433 -U yugabyte

# Node 2
psql -h 80.209.239.227 -p 5433 -U yugabyte

# Node 3
psql -h 212.24.98.67 -p 5433 -U yugabyte
```

С пользователем rls_app_user:
```bash
psql -h 80.208.229.107 -p 5433 -U rls_app_user -d soap
# Password: password
```

### Web UI

Master UI (любая нода):
- http://80.208.229.107:7000
- http://80.209.239.227:7000
- http://212.24.98.67:7000

TServer UI (любая нода):
- http://80.208.229.107:9000
- http://80.209.239.227:9000
- http://212.24.98.67:9000

## Проверка статуса кластера

### Проверка контейнеров на всех нодах

```bash
ansible all -i inventory.ini -m shell -a "docker ps --filter name=yb-"
```

### Проверка статуса кластера через ysqlsh

```bash
docker run --rm --network host yugabytedb/yugabyte:2024.2.6.0-b94 \
  bin/ysqlsh -h 80.208.229.107 -p 5433 -U yugabyte -c "
    SELECT host, port, num_live_tablet_servers
    FROM yb_servers();"
```

Должно показать 3 активных tablet servers.

## Управление кластером

### Остановка кластера

```bash
ansible all -i inventory.ini -m shell -a "cd /opt/yb-compose && docker compose down"
```

### Запуск кластера

```bash
ansible all -i inventory.ini -m shell -a "cd /opt/yb-compose && docker compose up -d"
```

### Полное удаление (включая данные)

```bash
ansible all -i inventory.ini -m shell -a "cd /opt/yb-compose && docker compose down -v"
ansible all -i inventory.ini -m shell -a "rm -rf /var/yugabyte/*"
```

## Troubleshooting

### Логи контейнеров

```bash
# На конкретной ноде
ssh root@80.208.229.107
docker logs yb-master
docker logs yb-tserver
```

### Проверка сетевой связности между нодами

```bash
ansible all -i inventory.ini -m shell -a "nc -zv 80.208.229.107 7100"
ansible all -i inventory.ini -m shell -a "nc -zv 80.209.239.227 7100"
ansible all -i inventory.ini -m shell -a "nc -zv 212.24.98.67 7100"
```

### Если ноды не видят друг друга

1. Проверьте firewall на всех нодах
2. Убедитесь что порты 7100, 9100 открыты
3. Проверьте что Docker использует `network_mode: host`

## Конфигурационные файлы

- `inventory.ini` - список нод кластера
- `deploy_cluster.yml` - основной playbook
- `/opt/yb-compose/docker-compose.yml` - генерируется на каждой ноде

## Изменение версии YugabyteDB

Отредактируйте `inventory.ini`:

```ini
[yugabyte_cluster:vars]
yb_version=2024.2.7.0-b1  # новая версия
```

Затем перезапустите playbook.

# Все мастера 
curl -s http://80.208.229.107:7000/api/v1/masters


#  Все Tservers нужно обязательно использовать апи мастера
curl -s http://80.208.229.107:7000/api/v1/tablet-servers | jq '.[""] | keys'
