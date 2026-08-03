# Informe de Conclusiones y Exposición: Benchmark de Microservicios CRUD
## Optimización de Recursos en Entornos de Hardware Limitado (Foco en RAM)

---

## 1. Resumen Ejecutivo

Este estudio evalúa **7 implementaciones equivalentes de servicios CRUD/HTTP** containerizadas y desplegadas en un clúster Kubernetes ligero (**k3d**), bajo restricciones estrictas de recursos (`1000m CPU` y `256Mi RAM` por pod, excepto Java con `512Mi RAM`).

El objetivo principal es proveer **evidencia empírica cuantitativa** para la toma de decisiones técnicas al migrar o construir servicios en servidores con **hardware limitado (especialmente RAM)**.

### Tabla Comparativa General (Resultados Medidos en Vivo)

| Lenguaje / Framework | Puerto | Peso Imagen | RAM Idle | RAM bajo Carga | CPU Peak | Throughput (Req/s) | Latencia Prom. | Peticiones Totales (30s) |
|---|---|---|---|---|---|---|---|---|
| **Rust (Axum)** | `8082` | 101 MB | **1 MiB** | **1 - 12 MiB** | 1000m | **75,830.43** | **1.41 ms** | **2,275,685** |
| **Bun (Elysia)** | `8084` | 292 MB | 94 MiB | 108 MiB | 1000m | **53,496.00** | **1.87 ms** | **1,605,389** |
| **NestJS (Fastify)** | `8085` | 1.29 GB | 126 MiB | 152 MiB | 1000m | **24,569.27** | **6.73 ms** | **739,525** |
| **Go (Gin)** | `8081` | **31.6 MB** | **20 MiB** | **20 - 41 MiB** | 994m | **16,591.16** | **15.02 ms** | **498,319** |
| **Java (Spring Boot)**| `8086` | 261 MB | 206 MiB | 248 MiB | 998m | **15,091.22** | **7.13 ms** | **452,932** |
| **NestJS (Express)** | `8087` | 1.28 GB | 125 MiB | 125 MiB | 1000m | **13,527.27** | **7.42 ms** | **405,908** |
| **Python (FastAPI)** | `8083` | 261 MB | 54 MiB | 78 MiB | 1000m | **9,020.20** | **11.19 ms** | **270,912** |

---

## 2. Análisis Detallado de Métricas Clave

### A. Peso de las Imágenes Docker (Almacenamiento en Disco)
1. **La más liviana**: **Go (`go_crud:latest`) con solo 31.6 MB**. Al compilar a un binario estático sin runtime externo sobre imágenes mínimas (Alpine/Scratch), logra un footprint de despliegue imbatible.
2. **Compactas (Binarios Nativo)**: **Rust (`rust_crud:latest`) con 101 MB**. Contiene el binario optimizado en release.
3. **Medianas**: **Python (261 MB)**, **Java (261 MB)** y **Bun (292 MB)**. Incluyen sus respectivos runtimes (`python:slim`, JRE Alpine, Bun runtime).
4. **Las más pesadas**: **NestJS Express (1.28 GB)** y **NestJS Fastify (1.29 GB)**. El costo del runtime Node.js junto con la carpeta `node_modules` y dependencias pesadas (Prisma Client, CLI) incrementa el tamaño más de 40 veces respecto a Go.

> **Regla de Escalado en Kubernetes**: El tamaño de la imagen se descarga **una sola vez por nodo** y se comparte entre todos los pods de ese nodo. Escalar de 1 a 10 réplicas **NO** multiplica el espacio ocupado en disco.

---

### B. Consumo de Memoria RAM (Recurso Más Limitante)
En servidores con RAM restringida (ej. VPS de 2GB a 4GB RAM donde corren múltiples microservicios):

- 🏆 **Ganador Absoluto: Rust (Axum)**
  - **1 MiB en reposo**, **1 MiB - 12 MiB bajo carga máxima**.
  - Permite desplegar decenas de pods sin apenas impactar la memoria de la máquina host.
- 🥈 **Segundo Lugar: Go (Gin)**
  - **20 MiB en reposo**, **20 - 41 MiB bajo carga**.
  - Consumo sumamente predecible sin recolector de basura agresivo.
- 🥉 **Tercer Lugar: Python (FastAPI)**
  - **54 MiB en reposo**, **78 MiB bajo carga**.
- ⚠️ **Cuarto Lugar: Bun (Elysia)**
  - **94 MiB en reposo**, **108 MiB bajo carga**. Muy buen desempeño, pero el motor JavaScript V8 / Bun exige cerca de 100MB base.
- 🔴 **Zona Crítica: NestJS (Express / Fastify)**
  - **125 - 126 MiB en reposo**, subiendo a **152 MiB bajo carga**.
  - Requiere al menos 256MB por pod para operar de forma segura sin sufrir *Out-Of-Memory (OOM)*.
- 🚫 **Mayor Consumo: Java (Spring Boot)**
  - **206 MiB en reposo**, elevándose a **248 - 256 MiB bajo carga**.
  - Obliga a subir el límite de memoria del manifiesto a `512Mi`. No es recomendado si el hardware en RAM es sumamente limitado.

---

### C. Procesamiento de CPU y Capacidad de Peticiones (Throughput con `wrk`)
Todos los microservicios fueron sometidos a **100 conexiones concurrentes durante 30 segundos (`wrk -t4 -c100 -d30s`)**:

1. **Rust (Axum)** procesa **75,830 req/seg** utilizando el 100% de 1 CPU (`1000m`). Rendimiento y paralelismo sin igual gracias a `tokio`.
2. **Bun (Elysia)** alcanza **53,496 req/seg** con 1 CPU, demostrando que Bun y Elysia son extremadamente eficientes para tareas I/O asíncronas.
3. **NestJS (Fastify)** logra **24,569 req/seg**, superando por **81.6%** a NestJS con Express (**13,527 req/seg**) consumiendo la misma memoria.
4. **Go (Gin)** procesa **16,591 req/seg** de forma fluida y estable.
5. **Java (Spring Boot)** procesa **15,091 req/seg** con una latencia de 7.13 ms.
6. **Python (FastAPI)** procesa **9,020 req/seg**, siendo el más lento debido al costo del intérprete de Python y el manejo monohilo del bucle de eventos.

---

### D. Latencia y Manejo de Timeouts
- **Menor Latencia**: **Rust (1.41 ms)** y **Bun (1.87 ms)** responden casi de inmediato.
- **Latencia Media-Baja**: **NestJS Fastify (6.73 ms)**, **Java (7.13 ms)** y **NestJS Express (7.42 ms)**.
- **Latencia Más Alta**: **Python (11.19 ms)** y **Go (15.02 ms)**.
- **Timeouts / Errores**: En todas las pruebas a `/health` con 100 conexiones concurrentes, **ninguno de los 7 servicios registró timeouts ni errores 5xx**. Los límites configurados (`1000m CPU`) permitieron que todos respondieran correctamente sin caídas.

---

## 3. Matriz de Decisiones Técnicas según Limitaciones de Hardware

| Escenario de Arquitectura | Lenguaje Recomendado | Razón Técnica Principal |
|---|---|---|
| **RAM extremadamente limitada (< 2 GB en servidor)** | 🦀 **Rust (Axum)** | Consumo de **1 MiB RAM** por pod. Puedes correr 50 microservicios de Rust donde apenas cabrían 4 de Java. |
| **Baja RAM + Despliegues Rápidos + Imágenes Mínimas** | 🐹 **Go (Gin / Fiber)** | Imagen de **31.6 MB** y uso de **20 MiB RAM**. Equilibrio perfecto entre legibilidad, velocidad y recursos. |
| **Entorno Node.js / TypeScript exigido por la empresa** | ⚡ **Bun (Elysia)** o **NestJS + Fastify** | **Bun** rinde 3.5x más que NestJS usando menos RAM (94MB). Si se debe mantener **NestJS**, cambiar Express por **Fastify** duplica el throughput. |
| **Prototipado rápido / Ciencia de Datos** | 🐍 **Python (FastAPI)** | Alta productividad de desarrollo, pero requiere más pods/CPU para igualar el throughput de Rust o Bun. |
| **Aplicaciones Enterprise Heredadas** | ☕ **Java (Spring Boot)** | Excelente ecosistema pero **muy costoso en RAM** (200MB+ por pod en idle). No recomendable para VPS pequeños. |

---

## 4. Guía para la Exposición en Vivo (Demostración Práctica)

Para realizar una exposición impactante ante la audiencia o comité técnico:

### Paso 1: Mostrar el estado inicial del clúster y los pods
```bash
kubectl get pods -n crud-benchmark
kubectl top pods -n crud-benchmark
```
*Destacar en pantalla que Rust usa 1 MiB de RAM y Go usa 20 MiB vs Java que usa >200 MiB.*

### Paso 2: Comparar el peso de las imágenes en disco
```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "go_crud|rust_crud|python_crud|bun_crud|nest|java"
```
*Explicar que la imagen de Go pesa solo 31.6MB mientras que NestJS supera 1.2GB.*

### Paso 3: Ejecutar la prueba de estrés en vivo con `wrk`
Abre 2 terminales lado a lado:
- **Terminal 1**: Monitoreo en vivo con `watch -n 1 'kubectl top pods -n crud-benchmark'` o `k9s -n crud-benchmark`.
- **Terminal 2**: Lanzar la prueba de estrés:
```bash
# Probar Rust vs Python
wrk -t4 -c100 -d30s http://localhost:8082/health
wrk -t4 -c100 -d30s http://localhost:8083/health
```

### Paso 4: Demostrar Escalado de Réplicas en Vivo
```bash
# Escalar Python a 3 réplicas
kubectl scale deployment python-crud --replicas=3 -n crud-benchmark
kubectl top pods -n crud-benchmark
```
*Enseñar cómo el consumo de RAM de Python se triplica en el servidor (54MB x 3 = 162MB), pero el tamaño de la imagen Docker en disco se mantiene exactamente igual (261MB).*

---

## 5. Conclusión Final

Si el objetivo del equipo es **maximizar la densidad de microservicios CRUD por servidor y reducir los costos de infraestructura en RAM**:

1. **Rust (Axum)** es el estándar de excelencia técnica en eficiencia energética y de memoria (**1 MiB RAM**, **>75k Req/s**).
2. **Go** es el sustituto industrial ideal por su bajo peso (**31.6 MB imagen**, **20 MiB RAM**) y simplicidad de mantenimiento.
3. En ecosistemas JavaScript/TypeScript, migrar de **NestJS (Express)** a **Bun (Elysia)** o al adaptador **NestJS (Fastify)** reduce significativamente el uso de memoria e incrementa el throughput al doble o triple.
