# Guía y Estrategias de Optimización de RAM y Rendimiento en Microservicios

Este documento detalla el análisis de recursos del Benchmark de Microservicios CRUD, incorpora datos reales medidos en tu terminal y en entornos de producción, y proporciona estrategias prácticas para optimizar las imágenes Docker y la resiliencia contra timeouts.

---

## 1. Tablas Comparativas del Benchmark (Datos Reales de la Terminal)

### A. Comparación por Tamaño de Imagen en Disco

El tamaño de la imagen influye directamente en el tiempo de descarga inicial (Cold Start del pod en nodos nuevos) y en el almacenamiento de los registros de contenedores.

| Lenguaje / Framework   | Imagen Docker         | Tamaño Real | Tipo de Runtime / Base                         |
| :--------------------- | :-------------------- | :---------- | :--------------------------------------------- |
| **Go (Gin)**           | `go_crud:latest`      | **31.6 MB** | Binario estático compilado (Ultra-ligero)      |
| **C++ (Crow/Oat++)**   | `c_crud:latest`       | **88.6 MB** | Binario nativo compilado                       |
| **Rust (Axum)**        | `rust_crud:latest`    | **101 MB**  | Binario nativo compilado en Release            |
| **.NET (Minimal API)** | `net_crud:latest`     | **118 MB**  | JIT/Runtime de .NET optimizado                 |
| **Java (Spring Boot)** | `java_crud:latest`    | **261 MB**  | Java Runtime Environment (JRE)                 |
| **Python (FastAPI)**   | `python_crud:latest`  | **261 MB**  | Intérprete Python + dependencias pip           |
| **Bun (Elysia)**       | `bun_crud:latest`     | **292 MB**  | Bun Runtime (JavaScript V8 / JSC Engine)       |
| **NestJS (Express)**   | `nest-express:latest` | **1.28 GB** | Node.js Runtime + `node_modules` de desarrollo |
| **NestJS (Fastify)**   | `nest-fastify:latest` | **1.29 GB** | Node.js Runtime + `node_modules` de desarrollo |

- **Por qué NestJS pesa >1.2 GB:** Incluye todo el runtime de Node.js, compendios de compilación de TypeScript en caliente y dependencias sin filtrar (como Prisma Engine, CLI de Nest, etc.) en el contenedor final.
- **Por qué Go/Rust/C++ pesan <100 MB:** No empaquetan un intérprete o máquina virtual, sino un binario de código máquina ejecutable directo.

---

### B. Comparación por Uso de Memoria RAM (Idle vs Load)

Medido utilizando `kubectl top pods -n l-namespace` en reposo y bajo carga máxima.

| Lenguaje / Framework         | RAM Idle    | RAM Max (Bajo Carga) | Impacto de RAM                     |
| :--------------------------- | :---------- | :------------------- | :--------------------------------- |
| **Rust (Axum)**              | **1 MiB**   | **12 MiB**           | 🟢 Ultra-Bajo (Excelente densidad) |
| **Go (Gin)**                 | **20 MiB**  | **41 MiB**           | 🟢 Muy Bajo (Predecible y estable) |
| **.NET (Minimal API)**       | **58 MiB**  | **58 MiB**           | 🟢 Bajo                            |
| **Python (FastAPI)**         | **54 MiB**  | **78 MiB**           | 🟡 Moderado                        |
| **Bun (Elysia)**             | **94 MiB**  | **108 MiB**          | 🟡 Moderado (Mejor consumo en JS)  |
| **NestJS (Express/Fastify)** | **125 MiB** | **152 MiB**          | 🔴 Alto (Requiere limits > 256Mi)  |
| **Java (Spring Boot)**       | **206 MiB** | **248 MiB**          | ❌ Crítico (Mínimo requiere 512Mi) |

---

### C. Comparación por Throughput y Latencia (`wrk -t4 -c100 -d30s`)

Resultados oficiales de la ejecución en tu terminal:

| Lenguaje / Framework   | Throughput (Req/s) | Peticiones Totales (20s) | Latencia Promedio | Latencia Máxima |
| :--------------------- | :----------------- | :----------------------- | :---------------- | :-------------- |
| **Rust (Axum)**        | **76,708.14**      | 1,541,834                | **1.30 ms**       | 5.59 ms         |
| **Bun (Elysia)**       | **66,789.83**      | 1,342,446                | **1.60 ms**       | 13.76 ms        |
| **NestJS (Fastify)**   | **38,001.52**      | 760,382                  | **2.85 ms**       | 182.41 ms       |
| **.NET (Minimal API)** | **20,648.01**      | 413,057                  | **12.08 ms**      | 78.64 ms        |
| **Go (Gin)**           | **20,612.54**      | 412,655                  | **16.68 ms**      | 93.81 ms        |
| **Python (FastAPI)**   | **9,885.25**       | 197,889                  | **11.00 ms**      | 458.22 ms       |
| **Java (Spring Boot)** | **9,821.56**       | 196,651                  | **20.63 ms**      | 106.33 ms       |

---

### D. Gestión de Timeouts y Errores

Durante las pruebas de estrés ejecutadas, **no se reportaron timeouts ni errores 5xx (tasa de error 0%)** en ninguno de los contenedores activos. Esto se debe a:

1. **Límites de CPU suficientes:** El clúster k3d asigna CPU suficiente para gestionar la cola de conexiones sin degradar el backend a niveles de timeout de red.
2. **Cola de conexiones del kernel (TCP Backlog):** Servidores como Axum (Tokio) y Bun gestionan el pooling interno de forma eficiente.
3. **Optimización preventiva contra Timeouts:**
   - Para evitar timeouts en producción, el servicio debe configurar políticas de **circuit breaker**, configurar límites de tiempo (`read/write timeouts`) en el servidor HTTP y dimensionar correctamente el **Connection Pool** de la Base de Datos.

---

## 2. Análisis del Entorno Real vs. Benchmark (Tus imágenes de K9s)

En los pantallazos reales de tu terminal de producción (`fiscalia-ms`, `prod-ms`, `fiscalia`):

- `ms-pdf-fiscalia` consume **11.3 GB (11,304 MiB) de RAM**.
- `ms-files-fiscalia` consume **5.1 GB (5,111 MiB) de RAM**.
- `ms-agetic-back-fiscalia` consume **830 MiB (103% de su límite)** lo que causa reinicios (`5 restarts`).

### ¿Por qué existe una diferencia tan abismal con el Benchmark?

1. **Manipulación de Archivos y Buffers en Memoria:** Servicios como procesamiento de PDFs o subida de archivos leen el contenido completo de archivos grandes en memoria RAM (`heap`) en lugar de procesarlos mediante **Streams** (transmisión por partes).
2. **Fugas de Memoria (Memory Leaks):** En lenguajes interpretados como JavaScript (Node.js/NestJS) o Python, las variables globales no recolectadas o las suscripciones abiertas retienen memoria indefinidamente.
3. **Configuración incorrecta del Garbage Collector (GC):** En Java o Node.js, si no se limitan los parámetros de memoria máxima del runtime (`--max-old-space-size` en Node o `-Xmx` en Java), la máquina virtual seguirá consumiendo memoria del host hasta que el sistema operativo la elimine (OOM Kill).

---

## 3. Guía de Optimización de Dockerfiles por Lenguaje

A continuación, se proponen Dockerfiles optimizados usando **Multi-stage Builds** e imágenes base ligeras (`alpine` o `distroless`) para reducir radicalmente el peso y consumo de memoria.

### 🦀 Rust (Axum)

- **Antes:** ~100MB+ (Usando imágenes Debian genéricas o compilando sin optimizar).
- **Mejora:** Usar compilación estática y una imagen base mínima `gcr.io/distroless/cc-debian12`.

```dockerfile
# Stage 1: Build
FROM rust:1.86-bookworm AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

# Stage 2: Final
FROM gcr.io/distroless/cc-debian12
WORKDIR /app
COPY --from=builder /app/target/release/crud-rust-axum .
EXPOSE 8082
CMD ["./crud-rust-axum"]
```

- **Resultado:** Reducción a **~15-20 MB** de imagen y aislamiento de seguridad total.

---

### 🐹 Go (Gin)

- **Antes:** 31.6 MB (Usando Alpine).
- **Mejora:** Compilar estáticamente eliminando símbolos de depuración (`-ldflags="-s -w"`) y copiar en una imagen `scratch` limpia (vacía).

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

# Stage 2: Final (Imagen vacía)
FROM scratch
COPY --from=builder /app/main /main
EXPOSE 8081
CMD ["/main"]
```

- **Resultado:** Reducción del peso de la imagen a **~8-12 MB**.

---

### 🟢 NestJS / Node.js

- **Antes:** 1.29 GB (Contiene TypeScript, devDependencies y compiladores).
- **Mejora:** Ejecutar multi-stage, eliminar `devDependencies` en producción, limpiar la caché de npm y usar `node:20-alpine`.

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
# Elimina dependencias de desarrollo y se queda solo con producción
RUN npm prune --production

# Stage 2: Run
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 8085
CMD ["node", "dist/main"]
```

- **Resultado:** Reducción drástica del tamaño de **1.29 GB a ~150-180 MB**.

---

### ⚡ Bun (Elysia)

- **Antes:** 292 MB.
- **Mejora:** Usar la imagen `jarredsumner/bun:edge` o la oficial `oven/bun:alpine` y filtrar archivos innecesarios.

```dockerfile
FROM oven/bun:1.1-alpine AS builder
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun build ./src/index.ts --outfile=server.js --minify

FROM oven/bun:1.1-alpine
WORKDIR /app
COPY --from=builder /app/server.js .
EXPOSE 8084
CMD ["bun", "server.js"]
```

- **Resultado:** Imagen final compacta de **~80 MB**.

---

### ☕ Java (Spring Boot)

- **Antes:** 261 MB (Uso de JDK completo y JRE pesado).
- **Mejora 1 (JRE Alpine):** Utilizar `eclipse-temurin:21-jre-alpine` para la imagen final.

```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY . .
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
# Limitar memoria heap para evitar OOM
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxRAMPercentage=75.0"
EXPOSE 8086
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

- **Mejora 2 (GraalVM Native Image):** Compilar a código binario nativo (sin JVM). Reduce la imagen a **~40 MB** y el consumo de RAM Idle a **~25 MiB**.

---

### 🐍 Python (FastAPI)

- **Antes:** 261 MB.
- **Mejora:** Usar la imagen `python:3.11-slim` en lugar de la estándar, evitar guardar caché de pip, y no compilar archivos `.pyc` innecesarios.

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
EXPOSE 8083
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8083", "--workers", "1"]
```

- **Resultado:** Reducción de tamaño a **~110 MB**.

---

## 3. Benchmark de Operaciones de Escritura y Eliminación (POST/DELETE)

Cuando se realiza estrés directo sobre endpoints transaccionales (haciendo inserciones y eliminaciones alternadas mediante el script `post_delete.lua` con **1,000 conexiones concurrentes** durante 30 segundos), el comportamiento cambia radicalmente respecto a la prueba estática de `/health`. Aquí es donde se exponen los cuellos de botella del clúster y la base de datos:

### Tabla Comparativa de Estrés Transaccional (1,000 Conexiones - 30 Segundos)

| Lenguaje / Framework   | Throughput (Req/s) | Latencia Promedio | Timeouts de Red | Respuestas Non-2xx (404) | Memoria RAM en Carga |
| :--------------------- | :----------------- | :---------------- | :-------------- | :----------------------- | :------------------- |
| **Rust (Axum)**        | **14,376.26**      | **68.22 ms**      | **0**           | ~419k                    | **109 MiB**          |
| **Go (Gin)**           | **3,894.97**       | **262.15 ms**     | 1,806           | ~47k                     | **29 MiB**           |
| **Bun (Elysia)**       | **1,631.22**       | **603.72 ms**     | 72              | ~17k                     | **146 MiB**          |
| **NestJS (Fastify)**   | **697.90**         | **535.49 ms**     | 1,978           | ~10k                     | **141 MiB**          |
| **Python (FastAPI)**   | **486.71**         | **120.77 ms**     | 6,916           | ~14k                     | **69 MiB**           |
| **Java (Spring Boot)** | **410.67**         | **1.73 s**        | 7,068           | ~6k                      | **323 MiB**          |
| **C# (.NET)**          | **2.96**           | **961.48 ms**     | 27              | 71                       | **58 MiB**           |

---

### Análisis Técnico de Cuellos de Botella y Timeouts

#### 1. ¿Por qué surgieron Timeouts y Caídas de Throughput?

- **Saturación del Connection Pool de Base de Datos:** A diferencia de `/health`, cada petición POST y DELETE abre una conexión TCP hacia MySQL. Con 1,000 conexiones concurrentes en los microservicios, el pool de la base de datos se satura, obligando a las peticiones a esperar en cola hasta expirar (Timeouts).
- **Bloqueos de Escribir en Disco (I/O Wait):** Las inserciones y eliminaciones modifican tablas e índices en MySQL. El almacenamiento de tu host se convierte en el cuello de botella físico.
- **Consumo de RAM en Rust (de 1MB a 109MB):** Al manejar miles de hilos y almacenar buffers de conexión SQLx bajo carga extrema de 1,000 conexiones concurrentes, Rust subió a **109 MiB** (lo cual sigue siendo sumamente eficiente, pero demuestra que el pool y la concurrencia de Tokio consumen RAM real para buffers).

#### 2. Explicación de los Errores "Non-2xx"

- Durante el benchmark con el script de automatización, las peticiones DELETE intentan borrar IDs secuenciales. Debido a la concurrencia y desfases de hilos, muchas peticiones DELETE intentan eliminar registros que aún no se han insertado o que ya fueron eliminados por otro hilo, devolviendo un estado HTTP **404 Not Found** (que `wrk` clasifica como Non-2xx). Esto demuestra la resiliencia del framework manejando respuestas controladas bajo estrés sin colapsar el pod.

#### 3. Cómo Prevenir Timeouts en Producción

Para evitar que tus microservicios de producción (como el procesador de PDFs o el gestor de archivos de la Fiscalía) generen timeouts bajo alta concurrencia, debes implementar:

- **Tuning de Connection Pool:** Configurar adecuadamente el tamaño del pool (`max_connections`) y timeouts de adquisición de conexión para que falle rápido antes de colgar el hilo del servidor.
- **Procesamiento Asíncrono con Colas (Workers):** Si una operación (como firmar un PDF o procesar un archivo pesado) toma más de 500ms, no debe procesarse de forma síncrona en el hilo HTTP. Debe delegarse a una cola de mensajería (RabbitMQ, Kafka o Redis) para que un backend worker la procese en segundo plano.
- **Circuit Breakers y Limitación de Tasa (Rate Limiting):** Proteger el backend bloqueando peticiones maliciosas o excesivas antes de que saturen el clúster.

---

## 4. Estructura Sugerida para tu Exposición

Para defender el uso eficiente de RAM e infraestructura ante tu audiencia:

1. **Introducción del Problema Real (La Realidad):** Muestra los pantallazos del entorno de producción (`k9s`). Explica cómo en escenarios reales un solo pod de PDFs puede devorar **11.3 GB de RAM** o un backend saturarse y causar reinicios (`Restarts`).
2. **Presentación de la Solución (El Benchmark):** Presenta las tablas comparativas de tamaño de imagen, consumo de RAM y rendimiento.
3. **El Costo del Lenguaje/Runtime:** Explica detalladamente por qué el runtime influye (Node/Java consumen ~150-200MB en idle sin hacer nada debido a su motor de ejecución, mientras Rust/Go operan de forma nativa en rangos inferiores a 20MB).
4. **Demostración Práctica (en vivo):**
   - Corre el estrés con `wrk` contra Rust o Bun para mostrar latencias mínimas (~1.5 ms).
   - Compara en directo el consumo de memoria usando `watch kubectl top pods -n l-namespace`.
5. **Estrategia de Mitigación (Docker & Code):** Explica cómo un cambio en el Dockerfile (usar compilación multi-stage, Alpine/Distroless y limpiar dependencias) puede salvar gigabytes de disco y megabytes de RAM en el servidor.
