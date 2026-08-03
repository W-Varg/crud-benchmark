# CRUD Benchmark Multi-Lenguaje: Go vs Rust vs Python vs Bun/Elysia vs NestJS

Comparación de rendimiento (CPU, memoria, almacenamiento y throughput) entre 5 implementaciones equivalentes de un CRUD conectado a MySQL, containerizadas y desplegadas en un clúster Kubernetes local (k3d), gestionadas con k9s.

**Estado actual: 4 de 5 servicios corriendo en el clúster. Falta NestJS.**

---

## 1. Arquitectura general

Todos los servicios comparten:

- **Mismo modelo de datos** (`Product`: `id`, `name`, `price`, `stock`, `created_at`, `updated_at`)
- **Misma base de datos**: MySQL 8, corriendo directamente en el host (`127.0.0.1:3306`), base `crud_benchmark`
- **Mismas 5 rutas CRUD**: `POST /products`, `GET /products`, `GET /products/:id`, `PUT /products/:id`, `DELETE /products/:id`, más `GET /health`
- **Swagger montado en `/api`** en los 5 servicios
- **Misma variable de entorno** de conexión: `ENV_URL_MYSQL_DB=mysql://root:my-secret-pw@127.0.0.1:3306/crud_benchmark` (adaptada a `host.k3d.internal` dentro del clúster)

## 2. Stack por lenguaje

| # | Lenguaje | Framework | ORM/Driver | Puerto | Imagen Docker | Estado |
|---|----------|-----------|------------|--------|----------------|--------|
| 1 | Go | Gin | GORM | 8081 | `go_crud:latest` (31.6 MB) | ✅ Corriendo |
| 2 | Rust | Axum | sqlx | 8082 | `rust_crud:latest` (101 MB) | ✅ Corriendo |
| 3 | Python | FastAPI | SQLAlchemy async + aiomysql | 8083 | `python_crud:latest` (261 MB) | ✅ Corriendo |
| 4 | Bun | Elysia | Drizzle ORM + mysql2 | 8084 | `bun_crud:latest` (292 MB) | ✅ Corriendo |
| 5 | Node.js | NestJS + Fastify | Prisma | 8085 | `nestjs_crud` (pendiente) | ⏳ Pendiente |

**Primer dato de benchmark ya disponible sin cargar tráfico:** tamaño de imagen en reposo — Go es ~9x más liviano que Bun y ~8x más liviano que Python, incluso antes de correr una sola prueba de estrés.

## 3. Estructura de carpetas local

```
crud-benchmark/
├── go-gin-crud/            # Go + Gin + GORM
├── rust-axum-crud/         # Rust + Axum + sqlx
├── fastapi-crud/           # Python + FastAPI + SQLAlchemy
├── elysia-crud/            # Bun + Elysia + Drizzle
├── nestjs-fastify-crud/    # NestJS + Fastify + Prisma (pendiente de desplegar)
└── k8s-manifests/
    ├── 00-namespace.yaml
    ├── 01-go-crud.yaml
    ├── 02-rust-crud.yaml
    ├── 03-python-crud.yaml
    ├── 04-bun-crud.yaml
    └── README.md
```

Cada carpeta de servicio incluye: código fuente, `.env`, `.gitignore`, `Dockerfile` y `README.md` propio con sus comandos `curl` de prueba.

## 4. Infraestructura de contenedores/orquestación

- **Docker** 29.4.1 — build de las 4 imágenes ya generadas.
- **k3d** v5.9.0 (k3s v1.35.5-k3s1) — clúster Kubernetes local llamado `crud-benchmark`, con:
  - 1 nodo server + 1 nodo agent
  - Puertos 8081–8085 mapeados al host vía el *loadbalancer* de k3d (`-p "8081-8085:8081-8085@loadbalancer"`)
- **kubectl** v1.36.2 — contexto activo: `k3d-crud-benchmark` (namespace `crud-benchmark`)
- **k9s** v0.51.0 — gestión visual de pods/deployments/services

> **Nota de convivencia de clústeres:** este equipo también tiene configurado un contexto institucional (`oidc-cluster-prod` sobre `k0s-cluster`). k3d agregó su propio contexto sin tocar el existente; buena práctica seguida en este proyecto: verificar `kubectl config current-context` antes de aplicar o borrar cualquier recurso.

## 5. Pasos ya ejecutados

1. Se construyeron las 4 imágenes Docker (`go_crud`, `rust_crud`, `python_crud`, `bun_crud`).
2. Se resolvió un conflicto de puertos: contenedores sueltos de pruebas previas (`docker run -p 808X:808X`) ocupaban los mismos puertos que necesitaba el *loadbalancer* de k3d — se detuvieron antes de crear el clúster.
3. Se creó el clúster k3d `crud-benchmark` con los puertos 8081–8085 expuestos al host.
4. Se importaron las 4 imágenes al clúster con `k3d image import`.
5. Se aplicaron los manifiestos (`Namespace` + `Deployment` + `Service` por cada lenguaje) en el namespace `crud-benchmark`.
6. Se verificó el estado con `kubectl get pods -n crud-benchmark`: los 4 pods están `Running`, `1/1 READY`, `0 RESTARTS`.

```
NAME                           READY   STATUS    RESTARTS   AGE
bun-crud-85bf6c5895-p9c9x      1/1     Running   0          2d13h
go-crud-86f86cf785-9nfbm       1/1     Running   0          2d13h
python-crud-68d55c49d7-5cktw   1/1     Running   0          2d13h
rust-crud-6ddfd795cb-v9gqw     1/1     Running   0          2d13h
```

## 6. Comandos de referencia rápida

```bash
# Ver contexto activo (SIEMPRE antes de aplicar/borrar algo)
kubectl config current-context

# Estado del clúster
kubectl get pods -n crud-benchmark
kubectl get deployments -n crud-benchmark
kubectl get services -n crud-benchmark

# Gestión visual
k9s -n crud-benchmark

# Probar que cada servicio responde
curl http://localhost:8081/health   # Go
curl http://localhost:8082/health   # Rust
curl http://localhost:8083/health   # Python
curl http://localhost:8084/health   # Bun/Elysia

# Escalar réplicas (para la demo)
kubectl scale deployment go-crud --replicas=3 -n crud-benchmark

# Reconstruir y actualizar una imagen ya desplegada
docker build -t go_crud:latest ./go-gin-crud
k3d image import go_crud:latest -c crud-benchmark
kubectl rollout restart deployment go-crud -n crud-benchmark

# Limpiar todo al terminar el proyecto
kubectl delete namespace crud-benchmark
k3d cluster delete crud-benchmark
```

## 7. Pendiente / próximos pasos

- [ ] Construir la imagen `nestjs_crud` y desplegarla (`05-nestjs-crud.yaml`, puerto 8085).
- [ ] Instalar `metrics-server` en el clúster para poder usar `kubectl top pods` (k3d no lo trae por defecto).
- [ ] Sembrar datos de prueba iguales en los 5 servicios (mismo dataset, mismo número de filas).
- [ ] Definir y correr los scripts de prueba de estrés con **k6** contra cada puerto.
- [ ] Levantar **Prometheus + Grafana + cAdvisor** para monitoreo de CPU/memoria en vivo durante las pruebas.
- [ ] Documentar resultados finales (RPS, latencia p95/p99, memoria pico, CPU %) para la exposición.

## 8. Credenciales y configuración de referencia

```dotenv
# Fuera del clúster (local, .env de cada proyecto)
ENV_URL_MYSQL_DB=mysql://root:my-secret-pw@127.0.0.1:3306/crud_benchmark

# Dentro del clúster k3d (usado en los manifiestos de Kubernetes)
ENV_URL_MYSQL_DB=mysql://root:my-secret-pw@host.k3d.internal:3306/crud_benchmark
```

| Servicio | Puerto | Swagger |
|---|---|---|
| Go + Gin | 8081 | http://localhost:8081/api |
| Rust + Axum | 8082 | http://localhost:8082/api |
| Python + FastAPI | 8083 | http://localhost:8083/api |
| Bun + Elysia | 8084 | http://localhost:8084/api |
| NestJS + Fastify | 8085 | http://localhost:8085/api *(pendiente)* |

# replicas 


Tienes dos formas de hacerlo: comando rápido (imperativo, para ajustes en caliente durante la demo) o editando los manifiestos (declarativo, para que quede fijo y reproducible). Te recomiendo lo segundo como base, y el comando rápido para cuando quieras cambiar en vivo frente a la audiencia.
Opción A — Comando rápido (cambio inmediato, no se guarda en el archivo)
bashkubectl scale deployment go-crud --replicas=2 -n crud-benchmark
kubectl scale deployment rust-crud --replicas=2 -n crud-benchmark
kubectl scale deployment bun-crud --replicas=3 -n crud-benchmark
kubectl scale deployment python-crud --replicas=4 -n crud-benchmark
Verifica:
bashkubectl get deployments -n crud-benchmark

⚠️ Ojo: si algún día vuelves a correr kubectl apply -f 01-go-crud.yaml (por ejemplo, tras cambiar la imagen), el archivo va a pisar ese replicas: 2 con lo que diga el YAML (que sigue en 1). Por eso, para que quede persistente, actualizo los archivos.

Opción B — Editar los manifiestos (persistente)
Actualizo tus 4 archivos ya generados con las réplicas que pediste:Edited 4 files, ran 2 commands, read a fileEdited 4 files, ran 2 commands, read a fileQué archivos toqué
ArchivoCambio01-go-crud.yamlreplicas: 1 → 202-rust-crud.yamlreplicas: 1 → 203-python-crud.yamlreplicas: 1 → 404-bun-crud.yamlreplicas: 1 → 3
Aplicar los cambios en tu equipo
Descomprime encima de tu carpeta k8s-manifests existente (o solo copia el contenido) y aplica:
bashcd k8s-manifests

`kubectl apply -f 01-go-crud.yaml
kubectl apply -f 02-rust-crud.yaml
kubectl apply -f 03-python-crud.yaml
kubectl apply -f 04-bun-crud.yaml`
Verificar
bashkubectl get pods -n crud-benchmark
kubectl get deployments -n crud-benchmark
Deberías ver algo como:
`NAME          READY   UP-TO-DATE   AVAILABLE
go-crud       2/2     2            2
rust-crud     2/2     2            2
python-crud   4/4     4            4
bun-crud      3/3     3            3`

visualizar 

`k9s -n -n crud-benchmark`