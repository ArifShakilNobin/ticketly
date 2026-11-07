#!/usr/bin/env bash
# Starts the whole Ticketly platform on the host (infrastructure stays in Docker).
# Use this for fast iteration: `make dev`, `make stop`.
set -euo pipefail

cd "$(dirname "$0")/.."

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export JWT_SECRET="${JWT_SECRET:-ticketly-dev-secret-key-change-me-32-characters-min}"
export KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9094}"

# Postgres is published on 5433 by docker-compose (5432 may already be taken by a
# system PostgreSQL), so host-run services must be pointed at it explicitly.
POSTGRES_HOST_PORT="${POSTGRES_HOST_PORT:-5433}"

SERVICES=(
  user-service
  voice-nlp-service
  cost-optimization-service
  aggregator-service
  booking-payment-service
  notification-service
  api-gateway
)

PORTS=(
  8081
  8082
  8084
  8083
  8085
  8086
  8080
)

mkdir -p .run

# Per-service database overrides (Spring relaxed binding beats any yml default).
declare -A DB_URLS=(
  [user-service]="jdbc:postgresql://localhost:${POSTGRES_HOST_PORT}/ticketly_user"
  [cost-optimization-service]="jdbc:postgresql://localhost:${POSTGRES_HOST_PORT}/ticketly_offers"
  [booking-payment-service]="jdbc:postgresql://localhost:${POSTGRES_HOST_PORT}/ticketly_booking"
)

for svc in "${SERVICES[@]}"; do
  jar="services/$svc/target/$svc-0.1.0.jar"
  if [[ ! -f "$jar" ]]; then
    echo "Missing $jar — run 'make build' first." >&2
    exit 1
  fi
  if [[ -f ".run/$svc.pid" ]] && kill -0 "$(cat ".run/$svc.pid")" 2>/dev/null; then
    echo "$svc already running (pid $(cat ".run/$svc.pid"))"
    continue
  fi
  if [[ -n "${DB_URLS[$svc]:-}" ]]; then
    export SPRING_DATASOURCE_URL="${DB_URLS[$svc]}"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-ticketly}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-ticketly}"
  else
    unset SPRING_DATASOURCE_URL SPRING_DATASOURCE_USERNAME SPRING_DATASOURCE_PASSWORD || true
  fi
  echo "Starting $svc ..."
  nohup java -jar "$jar" > ".run/$svc.log" 2>&1 &
  echo $! > ".run/$svc.pid"
done

echo "Waiting for health endpoints ..."
for port in "${PORTS[@]}"; do
  ok=""
  for _ in $(seq 1 60); do
    if curl -fsS "http://localhost:$port/actuator/health" >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 1
  done
  if [[ -z "$ok" ]]; then
    echo "Port $port did not become healthy in 60s — check .run/*.log" >&2
    exit 1
  fi
  echo "  :$port healthy"
done

echo
echo "Platform is up:"
echo "  gateway  http://localhost:8080"
echo "  logs     tail -f .run/<service>.log"
