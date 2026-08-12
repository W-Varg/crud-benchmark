#!/bin/bash

# Array of services, ports, and names
services=(
  "go-crud:8091:Go (Gin)"
  "rust-crud:8092:Rust (Axum)"
  "python-crud:8093:Python (FastAPI)"
  "bun-crud:8094:Bun (Elysia)"
  "nest-fastify:8095:NestJS (Fastify)"
  "java-crud:8096:Java (Spring Boot)"
  "net-crud:8098:C# (.NET Minimal API)"
)

echo "=== INICIANDO BENCHMARK DE MICROSERVICIOS ==="
echo ""

# Get idle memory
echo "--- MEMORIA EN REPOSO (IDLE) ---"
kubectl top pods -n l-namespace
echo ""

for item in "${services[@]}"; do
  IFS=":" read -r pod_prefix port label <<< "$item"
  
  echo "=========================================="
  echo "Prueba de carga -> $label (Puerto: $port)"
  echo "=========================================="
  
  # Start wrk in background
  wrk -t4 -c1000 -d30s "http://localhost:$port/health" > "/tmp/wrk_$port.txt" &
  WRK_PID=$!
  
  # Wait 8 seconds to let the load stabilize
  sleep 8
  
  # Capture CPU/Memory during load
  kubectl top pods -n l-namespace | grep "$pod_prefix"
  
  # Wait for wrk to complete
  wait $WRK_PID
  
  # Display wrk results
  cat "/tmp/wrk_$port.txt"
  echo ""
done

echo "=== BENCHMARK FINALIZADO ==="

