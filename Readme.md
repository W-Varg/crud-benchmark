# 📘 Manual Técnico y Guía Definitiva de Arquitectura CRUD Benchmark

## Guía de Instalación, Operación, Monitoreo y Extensión para Desarrolladores

Bienvenido al laboratorio **CRUD Benchmark Multi-Lenguaje**. Este documento constituye una guía completa, pedagógica y detallada diseñada para que cualquier desarrollador (especialmente perfiles Junior, semi-senior o DevOps en formación) pueda entender, instalar, ejecutar, extender y analizar un entorno comparativo de microservicios sobre **Kubernetes (k3d)**.

---

## 📑 Tabla de Contenidos

1. [Introducción y Fundamentos Técnicos](#1-introducción-y-fundamentos-técnicos)
   - 1.1. ¿Qué es este proyecto y cuál es su objetivo?
   - 1.2. Conceptos Clave: Contenedores, Orquestación y Rendimiento
   - 1.3. Los 7 Stacks Evaluados en el Benchmark
2. [Análisis de Arquitectura Interna de los 7 Microservicios](#2-análisis-de-arquitectura-interna-de-los-7-microservicios)
   - 2.1. Go (Gin + GORM)
   - 2.2. Rust (Axum + SQLx)
   - 2.3. Python (FastAPI + SQLAlchemy Async)
   - 2.4. Bun (Elysia + Drizzle ORM)
   - 2.5. NestJS (Fastify + Prisma)
   - 2.6. Java (Spring Boot + Spring Data JPA)
   - 2.7. NestJS (Express + Prisma)
3. [Requisitos Previos e Instalación Detallada de Herramientas](#3-requisitos-previos-e-instalación-detallada-de-herramientas)
   - 3.1. Instalación de Docker Engine y Docker Compose
   - 3.2. Instalación de kubectl (CLI de Kubernetes)
   - 3.3. Instalación de k3d (Kubernetes sobre Docker)
   - 3.4. Instalación de k9s (Terminal Interactivas)
   - 3.5. Instalación de wrk (Generador de Carga HTTP)
4. [Guía Completa de Despliegue Paso a Paso](#4-guía-completa-de-despliegue-paso-a-paso)
   - 4.1. Paso 1: Construcción de Imágenes Docker Locales
   - 4.2. Paso 2: Creación del Clúster k3d con Mapeo de Puertos
   - 4.3. Paso 3: Importación de Imágenes al Runtime del Clúster
   - 4.4. Paso 4: Despliegue e Instalación de Metrics-Server
   - 4.5. Paso 5: Aplicación de los Manifiestos de Kubernetes (YAML)
5. [Verificación de Salud y Diagnóstico de Servicios](#5-verificación-de-salud-y-diagnóstico-de-servicios)
   - 5.1. Verificación de Recursos en Kubernetes (`kubectl get`)
   - 5.2. Pruebas de Conectividad HTTP con `curl`
6. [Pruebas de Estrés con wrk y Monitoreo en Tiempo Real](#6-pruebas-de-estrés-con-wrk-y-monitoreo-en-tiempo-real)
   - 6.1. Ejecución de Pruebas de Estrés con `wrk`
   - 6.2. Monitoreo Interactivo con `k9s`
   - 6.3. Monitoreo de Recursos con `kubectl top`
   - 6.4. Análisis de Almacenamiento en Disco con `docker system df`
   - 6.5. Experimento de Escalado de Réplicas en Vivo
7. [Resultados Empíricos y Análisis Comparativo](#7-resultados-empíricos-y-análisis-comparativo)
   - 7.1. Tabla General de Resultados Medidos en Vivo
   - 7.2. Análisis Profundo por Lenguaje y Framework
   - 7.3. Matriz de Decisiones Técnicas para Hardware Limitado
8. [Guía Tutorial: Cómo Agregar un Nuevo Competidor al Benchmark](#8-guía-tutorial-cómo-agregar-un-nuevo-competidor-al-benchmark)
   - 8.1. Escenario de Ejemplo: Añadir `07-nests-express` o una Nueva API
   - 8.2. Paso 1: Preparación del Código y Dockerfile
   - 8.3. Paso 2: Creación del Manifiesto Kubernetes (YAML)
   - 8.4. Paso 3: Compilación e Importación al Clúster Activo
   - 8.5. Paso 4: Despliegue y Ejecución de Pruebas
   - 8.6. Ejemplo de Integración Adicional: API en C# .NET 8
9. [Diccionario y Explicación Detallada de Comandos, Banderas y Conceptos](#9-diccionario-y-explicación-detallada-de-comandos-banderas-y-conceptos)
   - 9.1. Comandos de Docker
   - 9.2. Comandos de k3d
   - 9.3. Comandos de kubectl
   - 9.4. Comandos de k9s
   - 9.5. Comandos de wrk
   - 9.6. Comandos de curl
   - 9.7. Glosario de Términos Avanzados de Infraestructura
10. [Resolución de Problemas Frecuentes (Troubleshooting)](#10-resolución-de-problemas-frecuentes-troubleshooting)
    - 10.1. Error: `ErrImagePull` / `ImagePullBackOff`
    - 10.2. Error: `port is already allocated`
    - 10.3. Error: `metrics not available`
    - 10.4. Pod Reiniciado por `OOMKilled` (Out Of Memory)
11. [Comandos de Mantenimiento y Limpieza Final](#11-comandos-de-mantenimiento-y-limpieza-final)

---

## 1. Introducción y Fundamentos Técnicos

### 1.1. ¿Qué es este proyecto y cuál es su objetivo?

En el desarrollo de software moderno, la elección del lenguaje de programación y del framework web tiene un impacto directo en los **costos de infraestructura**, la **densidad de contenedores por servidor** y la **capacidad de respuesta bajo carga**.

Este proyecto es un **laboratorio de benchmark controlado**. Hemos construido **7 aplicaciones web CRUD independientes** que implementan la misma lógica de negocio sobre la misma entidad de base de datos (`Product`), expuestas mediante los mismos contratos API REST. Todas las aplicaciones han sido empaquetadas en contenedores Docker y desplegadas en un clúster Kubernetes local (`k3d`).

El objetivo principal es medir empíricamente:

- **Consumo de Memoria RAM en Reposo (Idle)**: Cuántos megabytes exige la aplicación recién iniciada sin recibir peticiones.
- **Consumo de Memoria RAM bajo Carga**: Cuánto crece la memoria cuando cientos de usuarios concurrentes realizan peticiones HTTP.
- **Procesamiento de CPU**: Cómo utiliza la aplicación el procesador cuando es llevada a su límite (`1000m` = 1 vCPU).
- **Throughput (Peticiones por Segundo - Req/s)**: Cuántas solicitudes HTTP es capaz de resolver exitosamente por segundo.
- **Latencia Promedio**: Cuántos milisegundos tarda en responder a cada cliente.
- **Tamaño de la Imagen Docker**: Cuánto espacio en disco requiere la imagen para ser almacenada y distribuida.

---

### 1.2. Conceptos Clave: Contenedores, Orquestación y Rendimiento

Para entender este laboratorio desde una perspectiva junior, es fundamental dominar los siguientes conceptos:

#### A. Contenedores (Docker)

Un contenedor es una unidad estándar de software que empaqueta el código de la aplicación junto con todas sus dependencias (librerías, binarios, runtime). A diferencia de una máquina virtual, los contenedores comparten el mismo kernel del sistema operativo host, lo que los hace extremadamente livianos y rápidos de iniciar.

#### B. Imágenes Docker y Capas

Una imagen Docker es una plantilla de solo lectura utilizada para crear contenedores. Se compone de múltiples capas superpuestas.

- **Compilación estática (Go/Rust)**: Genera binarios nativos independientes que no necesitan un entorno de ejecución extenso, resultando en imágenes de unos pocos megabytes (ej. Go 31.6 MB).
- **Entornos interpretados/JIT (Python/Node.js/Bun)**: Requieren incluir el motor de ejecución completo (`python`, `node`, `bun`), lo que eleva el tamaño de la imagen a cientos de megabytes o gigabytes (ej. NestJS 1.29 GB).

#### C. Orquestación de Contenedores (Kubernetes / k3d)

Kubernetes es una plataforma de código abierto para automatizar el despliegue, escalado y gestión de aplicaciones containerizadas.

- **k3d**: Es una herramienta ligera que ejecuta **k3s** (una distribución ligera de Kubernetes creada por Rancher) dentro de contenedores Docker. Permite simular un clúster de producción multinodo en la máquina local del desarrollador con un impacto mínimo en recursos.
- **Pod**: Es la unidad mínima desplegable en Kubernetes. Un Pod engloba uno o más contenedores que comparten almacenamiento y red.
- **Deployment**: Es un objeto de Kubernetes que declara el estado deseado para los Pods (por ejemplo, "mantener corriendo 3 réplicas de la aplicación X").
- **Service (LoadBalancer)**: Es un punto de acceso de red estable que abstrae los Pods. Un servicio de tipo `LoadBalancer` en k3d expone los puertos de los Pods hacia la máquina host a través del ingress controller del clúster (Traefik).

#### D. Límites y Solicitudes de Recursos (`requests` y `limits`)

En Kubernetes, se especifican dos valores clave de recursos para cada contenedor:

- **`resources.requests`**: La cantidad mínima de CPU/RAM garantizada que el clúster reserva para que el Pod pueda programarse en un nodo.
- **`resources.limits`**: El techo máximo absoluto de CPU/RAM que el Pod tiene permitido consumir. Si un Pod supera su límite de memoria RAM, el kernel de Linux lo termina inmediatamente emitiendo un evento de tipo `OOMKilled` (Out Of Memory Killed).

#### E. Throughput y Latencia

- **Throughput (RPS / Req/s)**: Mide la cantidad de transacciones completadas por unidad de tiempo. Mayor throughput indica mejor rendimiento general.
- **Latencia**: Mide el tiempo transcurrido desde que un cliente envía una petición HTTP hasta que recibe la respuesta completa. Menor latencia indica mayor velocidad de respuesta.

---

### 1.3. Los 7 Stacks Evaluados en el Benchmark

A continuación se detallan las 7 tecnologías incluidas en este laboratorio:

| #   | Lenguaje    | Framework        | ORM / Driver     | Puerto | Características Principales                                                                                                                                      |
| --- | ----------- | ---------------- | ---------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Go**      | Gin              | GORM             | `8081` | Lenguaje compilado concurrentemente mediante Goroutines. Excelente balance entre rendimiento, bajo consumo de memoria e imágenes diminutas.                      |
| 2   | **Rust**    | Axum             | SQLx             | `8082` | Lenguaje compilado de alto rendimiento sin recolector de basura (_Garbage Collector_). Máxima eficiencia de memoria y CPU mediante el runtime asíncrono `tokio`. |
| 3   | **Python**  | FastAPI          | SQLAlchemy Async | `8083` | Lenguaje interpretado enfocado en velocidad de desarrollo y tipado mediante Pydantic. Ejecutado asíncronamente con `uvicorn`.                                    |
| 4   | **Bun**     | Elysia           | Drizzle ORM      | `8084` | Runtime moderno de JavaScript/TypeScript alternativo a Node.js basado en el motor JavaScriptCore de WebKit. Ultra rápido en I/O.                                 |
| 5   | **Node.js** | NestJS + Fastify | Prisma           | `8085` | Framework empresarial en TypeScript. Configurado con el adaptador de alto rendimiento `Fastify` en lugar del motor Express por defecto.                          |
| 6   | **Java**    | Spring Boot      | Spring Data JPA  | `8086` | Framework empresarial clásico sobre la Máquina Virtual de Java (JVM). Gran ecosistema pero con mayor consumo de memoria RAM base.                                |
| 7   | **Node.js** | NestJS + Express | Prisma           | `8087` | Configuración estándar tradicional de NestJS sobre el adaptador Express. Permite comparar el impacto del adaptador HTTP contra Fastify.                          |

---

## 2. Análisis de Arquitectura Interna de los 7 Microservicios

Para entender cómo está construido cada proyecto en el repositorio, esta sección desglosa la estructura de archivos, el modelo de datos, la gestión de conexiones y las particularidades de código de cada uno.

### 2.1. Go (Gin + GORM) - `./01-go-gin`

- **Estructura**:
  - `main.go`: Inicialización de servidor HTTP en Gin, carga de variables de entorno y definición de rutas.
  - `models/product.go`: Estructura GORM mapping a la tabla `products`.
  - `handlers/product.go`: Controladores CRUD.
  - `Dockerfile`: Multi-stage build compilando con `CGO_ENABLED=0` generando un binario estático sobre Alpine Linux.
- **Manejo de Conexiones**: GORM abre un pool de conexiones nativo a MySQL (`database/sql`) reutilizable entre goroutines.

### 2.2. Rust (Axum + SQLx) - `./02-rust-axum`

- **Estructura**:
  - `src/main.rs`: Inicialización de `tokio` runtime y router Axum.
  - `src/handlers.rs`: Funciones de manejo de peticiones de cero costo sobre abstracciones de Tower.
  - `src/models.rs`: Structs con `serde::Serialize` y `serde::Deserialize`.
  - `Cargo.toml`: Dependencias compiladas en modo `--release`.
- **Manejo de Conexiones**: `sqlx::MySqlPool` administra un pool asíncrono no bloqueante sobre `tokio`.

### 2.3. Python (FastAPI + SQLAlchemy Async) - `./03-python-fastapi`

- **Estructura**:
  - `main.py`: Punto de entrada FastAPI con Uvicorn ASGI server.
  - `database.py`: Creación del motor asíncrono con `create_async_engine` y `aiomysql`.
  - `schemas.py`: Modelos Pydantic para validación automática de datos.
  - `requirements.txt`: Dependencias del proyecto.
- **Manejo de Conexiones**: `async_sessionmaker` maneja transacciones asíncronas liberando el bucle de eventos (_event loop_).

### 2.4. Bun (Elysia + Drizzle ORM) - `./04-bun-elysia`

- **Estructura**:
  - `src/index.ts`: Instancia de servidor Elysia con plugin de Swagger.
  - `src/db/schema.ts`: Definición de esquema con Drizzle ORM sobre `mysql2`.
  - `package.json`: Scripts de ejecución nativos con Bun (`bun run src/index.ts`).
- **Manejo de Conexiones**: Conexión ultra directa a la base de datos aprovechando la API de sockets rápida nativa de Bun.

### 2.5. NestJS (Fastify + Prisma) - `./05-nestjs-fastify`

- **Estructura**:
  - `src/main.ts`: Bootstrap configurando `FastifyAdapter` en lugar de `ExpressAdapter`.
  - `src/products/`: Módulo, Controlador y Servicio de productos.
  - `prisma/schema.prisma`: Definición del modelo relacional.
- **Manejo de Conexiones**: Prisma Client con motor binario gestionado en TypeScript.

### 2.6. Java (Spring Boot + Spring Data JPA) - `./06-java-spring`

- **Estructura**:
  - `src/main/java/.../Application.java`: Clase principal Spring Boot.
  - `src/main/java/.../controller/ProductController.java`: Endpoints anotados con `@RestController`.
  - `src/main/java/.../repository/ProductRepository.java`: Interfaz `JpaRepository`.
  - `pom.xml`: Configuración Maven.
- **Manejo de Conexiones**: Pool de conexiones HikariCP por defecto en Spring Boot.

### 2.7. NestJS (Express + Prisma) - `./07-nests-express`

- **Estructura**:
  - `src/main.ts`: Bootstrap tradicional con Express por defecto.
  - `src/products/`: Módulo, Controlador y Servicio de productos.
- **Manejo de Conexiones**: Mismo esquema Prisma que el proyecto Fastify, permitiendo aislar la variable del framework HTTP.

---

## 3. Requisitos Previos e Instalación Detallada de Herramientas

Para ejecutar este laboratorio en un equipo con sistema operativo **Ubuntu Linux** (o derivado de Debian) desde cero, debes instalar 5 herramientas fundamentales. A continuación se detalla el proceso paso a paso explicando la función de cada comando.

---

### 3.1. Instalación de Docker Engine y Docker Compose

Docker es el motor de contenedores necesario para compilar las imágenes y para que `k3d` pueda crear el clúster de Kubernetes en tu máquina.

```bash
# 1. Actualizar la lista de paquetes del sistema operativo
sudo apt update

# 2. Instalar paquetes auxiliares necesarios para descargar repositorios HTTPS de forma segura
sudo apt install -y curl ca-certificates gnupg lsb-release

# 3. Descargar e instalar el script oficial de instalación automatizada de Docker
curl -fsSL https://get.docker.com | sh

# 4. Agregar tu usuario actual al grupo de seguridad 'docker'
# Esto permite ejecutar comandos de docker sin anteceder siempre 'sudo'
sudo usermod -aG docker $USER

# 5. IMPORTANTE: Para que el cambio de grupo surta efecto en tu terminal actual, ejecuta:
newgrp docker
```

_Explicación para Juniors_: `newgrp docker` reinicia los permisos del grupo en el shell activo. Si no ejecutas este comando, Docker te solicitará permisos de superusuario (`sudo`) en cada interacción.

---

### 3.2. Instalación de kubectl (CLI de Kubernetes)

`kubectl` es la herramienta oficial de línea de comandos para comunicarte con el servidor de API de Kubernetes. Te permite crear, inspeccionar, actualizar y eliminar recursos en el clúster.

```bash
# Opción recomendable vía Snap (instalador de paquetes universal en Ubuntu)
sudo snap install kubectl --classic

# Verificar que la instalación fue exitosa consultando la versión del cliente
kubectl version --client
```

_Explicación para Juniors_: `--classic` le otorga a Snap los permisos necesarios para interactuar con la red y los archivos del sistema, requeridos para que `kubectl` pueda leer tu archivo de configuración de clúster `~/.kube/config`.

---

### 3.3. Instalación de k3d (Kubernetes sobre Docker)

`k3d` es un wrapper liviano que ejecuta `k3s` (distribución reducida de Kubernetes de Rancher) dentro de contenedores Docker. Es la herramienta que nos permitirá crear nuestro clúster local en segundos.

```bash
# Descargar el script de instalación oficial e invocar bash para ejecutarlo
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verificar que k3d esté correctamente instalado consultando su versión
k3d version
```

_Explicación para Juniors_: El flag `-s` en `curl` significa _silent_ (silencioso), lo que evita mostrar barras de progreso molestas durante la descarga del script.

---

### 3.4. Instalación de k9s (Terminal Interactivas)

`k9s` es una interfaz gráfica basada en terminal (TUI) para Kubernetes. Permite visualizar pods, logs, métricas, recursos y realizar operaciones como escalar réplicas mediante atajos de teclado sin necesidad de recordar comandos complejos de `kubectl`.

```bash
# Descargar e instalar k9s mediante Webinstall
curl -sS https://webinstall.dev/k9s | bash

# Si la ruta no se agrega automáticamente a tu PATH, actualiza el entorno:
source ~/.config/env

# Verificar la versión instalada
k9s version
```

---

### 3.5. Instalación de wrk (Generador de Carga HTTP)

`wrk` es una herramienta moderna de benchmarking HTTP capaz de generar una carga masiva de tráfico utilizando una arquitectura multihilo impulsada por eventos asíncronos (`epoll`/`kqueue`).

```bash
# Instalar wrk directamente desde los repositorios oficiales de Ubuntu
sudo apt update
sudo apt install -y wrk

# Verificar la instalación consultando su ayuda rápida
wrk --help
```

---

## 4. Guía Completa de Despliegue Paso a Paso

A continuación se detalla la secuencia exacta de comandos para construir los microservicios, inicializar la infraestructura local de Kubernetes y desplegar la totalidad del benchmark.

---

### 4.1. Paso 1: Construcción de Imágenes Docker Locales

Sitúate en la raíz del repositorio (`/home/dev/Documents/restringida/dev_proyects/crud-benchmark`) y ejecuta la construcción de las 7 imágenes Docker.

```bash
# 1. Compilar imagen de Go (Gin)
docker build -t go_crud:latest ./01-go-gin

# 2. Compilar imagen de Rust (Axum)
docker build -t rust_crud:latest ./02-rust-axum

# 3. Compilar imagen de Python (FastAPI)
docker build -t python_crud:latest ./03-python-fastapi

# 4. Compilar imagen de Bun (Elysia)
docker build -t bun_crud:latest ./04-bun-elysia

# 5. Compilar imagen de NestJS (Fastify)
docker build -t nest-fastify:latest ./05-nestjs-fastify

# 6. Compilar imagen de Java (Spring Boot)
docker build -t java_crud:latest ./06-java-spring

# 7. Compilar imagen de NestJS (Express)
docker build -t nest-express:latest ./07-nests-express
```

_Explicación para Juniors_:

- `docker build`: Inicia el proceso de creación de una imagen basada en las instrucciones del archivo `Dockerfile` ubicado en la carpeta destino.
- `-t nombre:etiqueta`: Asigna un nombre (_Tag_) legible a la imagen generada.
- `./directorio`: Especifica el _Build Context_ (directorio que se enviará al daemon de Docker para empaquetar el código).

---

### 4.2. Paso 2: Creación del Clúster k3d con Mapeo de Puertos

Creamos un clúster de Kubernetes ligero llamado `crud-benchmark`. Exponemos el rango de puertos `8081-8087` en el servidor LoadBalancer del clúster para que sean accesibles directamente desde `http://localhost:808X` en tu máquina host.

```bash
k3d cluster create crud-benchmark \
  --api-port 6550 \
  -p "8081-8087:8081-8087@loadbalancer" \
  --agents 1
```

_Explicación para Juniors_:

- `cluster create crud-benchmark`: Define el nombre del clúster Kubernetes.
- `--api-port 6550`: Asigna el puerto local en el que se expondrá la API de Kubernetes para que `kubectl` pueda conectarse.
- `-p "8081-8087:8081-8087@loadbalancer"`: Enruta las peticiones que lleguen a los puertos 8081 a 8087 de tu computadora local hacia el contenedor `serverlb` (LoadBalancer de k3d) del clúster.
- `--agents 1`: Configura 1 nodo trabajador (_worker node_) adicional al nodo maestro (_control-plane_).

---

### 4.3. Paso 3: Importación de Imágenes al Runtime del Clúster

Por defecto, Kubernetes intenta descargar las imágenes de contenedores desde registros públicos como Docker Hub. Como nuestras imágenes fueron construidas localmente en el daemon de Docker, debemos **importarlas** dentro del almacenamiento interno de imágenes de `k3d`.

```bash
k3d image import \
  go_crud:latest \
  rust_crud:latest \
  python_crud:latest \
  bun_crud:latest \
  nest-fastify:latest \
  java_crud:latest \
  nest-express:latest \
  -c crud-benchmark
```

_Explicación para Juniors_:

- `k3d image import`: Toma imágenes de tu motor Docker local, las empaqueta en un archivo `.tar` interno y las transfiere a los nodos del clúster `k3d`.
- `-c crud-benchmark`: Indica el nombre del clúster destino donde se importarán las imágenes.

---

### 4.4. Paso 4: Despliegue e Instalación de Metrics-Server

Para poder consultar el consumo de CPU y Memoria RAM en tiempo real mediante el comando `kubectl top`, debemos desplegar el componente `metrics-server` en el clúster y aplicarle un parche para ignorar certificados TLS autofirmados.

```bash
# 1. Desplegar los manifiestos oficiales de Metrics-Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 2. Aplicar un parche de configuración para permitir certificados autofirmados en k3d
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

_Explicación para Juniors_:

- `kubectl apply -f URL`: Descarga e instala recursos de Kubernetes directamente desde una URL remota.
- `kubectl patch`: Modifica la especificación de un recurso existente sin necesidad de editar todo su YAML. El parámetro `--kubelet-insecure-tls` le indica a Metrics Server que confíe en los certificados de prueba generados por `k3d`.

---

### 4.5. Paso 5: Aplicación de los Manifiestos de Kubernetes (YAML)

Desplegamos el namespace aislador `crud-benchmark` y los manifiestos de los 7 microservicios.

```bash
# 1. Crear el Namespace en Kubernetes
kubectl apply -f 00-k8s-manifests/00-namespace.yaml

# 2. Desplegar Go (Gin)
kubectl apply -f 00-k8s-manifests/01-go-crud.yaml

# 3. Desplegar Rust (Axum)
kubectl apply -f 00-k8s-manifests/02-rust-crud.yaml

# 4. Desplegar Python (FastAPI)
kubectl apply -f 00-k8s-manifests/03-python-crud.yaml

# 5. Desplegar Bun (Elysia)
kubectl apply -f 00-k8s-manifests/04-bun-crud.yaml

# 6. Desplegar NestJS (Fastify)
kubectl apply -f 00-k8s-manifests/05-nestjs-fastify.yaml

# 7. Desplegar Java (Spring Boot)
kubectl apply -f 00-k8s-manifests/06-java-crud.yaml

# 8. Desplegar NestJS (Express)
kubectl apply -f 07-nests-express/07-nestjs-express.yaml
```

---

## 5. Verificación de Salud y Diagnóstico de Servicios

Una vez aplicados los manifiestos, debemos validar que los Pods estén en estado de ejecución (_Running_) y que respondan adecuadamente a solicitudes HTTP.

---

### 5.1. Verificación de Recursos en Kubernetes (`kubectl get`)

Ejecuta los siguientes comandos para consultar el estado del clúster:

```bash
# Listar los Pods desplegados en el namespace crud-benchmark
kubectl get pods -n crud-benchmark

# Listar los Deployments y su estado de disponibilidad
kubectl get deployments -n crud-benchmark

# Listar los Servicios de red y sus puertos expuestos
kubectl get service -n crud-benchmark
```

_Salida esperada_: Debes observar 7 Pods en estado `Running` con la columna `READY` mostrando `1/1` y `RESTARTS` en `0`.

---

### 5.2. Pruebas de Conectividad HTTP con `curl`

Verifica la conectividad desde tu terminal Linux hacia los puertos mapeados en la máquina host:

```bash
# 1. Probar salud de Go (Gin) en puerto 8081
curl -i http://localhost:8081/health

# 2. Probar salud de Rust (Axum) en puerto 8082
curl -i http://localhost:8082/health

# 3. Probar salud de Python (FastAPI) en puerto 8083
curl -i http://localhost:8083/health

# 4. Probar salud de Bun (Elysia) en puerto 8084
curl -i http://localhost:8084/health

# 5. Probar salud de NestJS (Fastify) en puerto 8085
curl -i http://localhost:8085/health

# 6. Probar salud de Java (Spring Boot) en puerto 8086
curl -i http://localhost:8086/health

# 7. Probar salud de NestJS (Express) en puerto 8087
curl -i http://localhost:8087/health
```

_Explicación para Juniors_: El flag `-i` en `curl` le indica al comando que imprima los **encabezados HTTP de respuesta** (`HTTP/1.1 200 OK`, `Content-Type`, etc.), lo que confirma que el servidor web respondió correctamente.

---

## 6. Pruebas de Estrés con wrk y Monitoreo en Tiempo Real

Llegó el momento de ejecutar la prueba de rendimiento e inspeccionar el comportamiento de la infraestructura.

---

### 6.1. Ejecución de Pruebas de Estrés con `wrk`

Ejecutamos `wrk` configurando **4 hilos de ejecución (`-t4`)**, **100 conexiones HTTP concurrentes abiertas (`-c100`)** durante **30 segundos (`-d30s`)** sobre el endpoint `/health` de cada servicio.

```bash
# 1. Prueba de carga contra Go (Gin)
wrk -t4 -c100 -d30s http://localhost:8091/health

# 2. Prueba de carga contra Rust (Axum)
wrk -t4 -c100 -d30s http://localhost:8092/health

# 3. Prueba de carga contra Python (FastAPI)
wrk -t4 -c100 -d30s http://localhost:8093/health

# 4. Prueba de carga contra Bun (Elysia)
wrk -t4 -c100 -d30s http://localhost:8094/health

# 5. Prueba de carga contra NestJS (Fastify)
wrk -t4 -c100 -d30s http://localhost:8095/health

# 6. Prueba de carga contra Java (Spring Boot)
wrk -t4 -c100 -d30s http://localhost:8096/health

# 7. Prueba de carga contra NestJS (Express)
wrk -t4 -c100 -d30s http://localhost:8097/health

# 8. Prueba de carga contra .NET (Minimal API)
wrk -t4 -c100 -d30s http://localhost:8098/health
```

_Explicación de parámetros para Juniors_:

- `-t4`: Crea 4 hilos (_threads_) del sistema en tu máquina para enviar tráfico.
- `-c100`: Mantiene 100 conexiones HTTP persistentemente abiertas distribuidas entre los hilos.
- `-d30s`: Mantiene la generación de carga durante exactamente 30 segundos.

---

### 6.2. Monitoreo Interactivo con `k9s`

Para visualizar visualmente el rendimiento de los Pods durante las pruebas, abre `k9s` en una terminal secundaria:

```bash
k9s -n crud-benchmark
```

#### Atajos de Teclado Útiles en `k9s`:

- Escribe `:pods` y presiona `Enter`: Muestra la lista interactiva de Pods con consumo en tiempo real de CPU y RAM.
- Selecciona un Pod y presiona `l`: Abre la vista de logs del contenedor en vivo.
- Selecciona un Pod y presiona `s`: Abre una terminal interactiva (_shell_) dentro del contenedor.
- Escribe `:deploy` y presiona `Enter`: Muestra los Deployments. Selecciona uno y presiona `Ctrl + s` para **escalar réplicas en vivo**.

---

### 6.3. Monitoreo de Recursos con `kubectl top`

Si prefieres monitoreo por comandos, puedes usar:

```bash
# Ver consumo instantáneo de CPU y Memoria de los Pods
kubectl top pods -n crud-benchmark

# Ver consumo detallado dividiendo por contenedor dentro de cada Pod
kubectl top pods -n crud-benchmark --containers

# Ver consumo global de CPU y RAM de los Nodos de Kubernetes
kubectl top nodes
```

---

### 6.4. Análisis de Almacenamiento en Disco con `docker system df`

Para analizar cuánto espacio consumen las imágenes compiladas y los contenedores en tu disco rígido:

```bash
# Ver resumen general de uso de disco en Docker
docker system df

# Ver información detallada lista por lista
docker system df -v

# Ver ordenadamente el tamaño de las imágenes del benchmark
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "go_crud|rust_crud|python_crud|bun_crud|nest|java"
```

---

### 6.5. Experimento de Escalado de Réplicas en Vivo

Una pregunta frecuente en arquitectura es: _¿Si escalo un Deployment de 1 a 3 réplicas, se triplica el tamaño de la imagen Docker en mi disco?_

**Demostración Práctica**:

1. Ejecuta el comando de escalado:

```bash
kubectl scale deployment python-crud --replicas=3 -n crud-benchmark
```

2. Revisa el consumo de memoria en Kubernetes:

```bash
kubectl top pods -n crud-benchmark
```

_Resultado_: Verás 3 pods de Python corriendo. Cada uno consumirá ~54 MiB de RAM, por lo que el uso total de RAM del deployment se triplica (54 MiB x 3 = 162 MiB).

3. Revisa el tamaño de la imagen en Docker:

```bash
docker system df
```

_Resultado_: El espacio ocupado en disco por las imágenes **NO cambia en absoluto**. La imagen de Python (261 MB) se descarga y guarda **una sola vez por nodo de Kubernetes** y es compartida eficientemente por todos los Pods.

4. Vuelve al estado inicial de 1 réplica:

```bash
kubectl scale deployment python-crud --replicas=1 -n crud-benchmark
```

---

## 7. Resultados Empíricos y Análisis Comparativo

A continuación se presentan las métricas reales consolidadas durante la ejecución del benchmark en vivo sobre la máquina de pruebas.

---

### 7.1. Tabla General de Resultados Medidos en Vivo

| Servicio / Stack        | Puerto | Peso Imagen | RAM Idle   | RAM bajo Carga  | Peak CPU | Throughput (`wrk`)  | Latencia Prom. | Req. Totales (30s) |
| ----------------------- | ------ | ----------- | ---------- | --------------- | -------- | ------------------- | -------------- | ------------------ |
| 🦀 **Rust (Axum)**      | `8082` | 101 MB      | **1 MiB**  | **1 - 12 MiB**  | 1000m    | **75,830.43 req/s** | **1.41 ms**    | **2,275,685**      |
| ⚡ **Bun (Elysia)**     | `8084` | 292 MB      | 94 MiB     | 108 MiB         | 1000m    | **53,496.00 req/s** | **1.87 ms**    | **1,605,389**      |
| 🪺 **NestJS (Fastify)** | `8085` | 1.29 GB     | 126 MiB    | 152 MiB         | 1000m    | **24,569.27 req/s** | **6.73 ms**    | **739,525**        |
| 🐹 **Go (Gin)**         | `8081` | **31.6 MB** | **20 MiB** | **20 - 41 MiB** | 994m     | **16,591.16 req/s** | **15.02 ms**   | **498,319**        |
| ☕ **Java (Spring)**    | `8086` | 261 MB      | 206 MiB    | 248 MiB         | 998m     | **15,091.22 req/s** | **7.13 ms**    | **452,932**        |
| 🪺 **NestJS (Express)** | `8087` | 1.28 GB     | 125 MiB    | 125 MiB         | 1000m    | **13,527.27 req/s** | **7.42 ms**    | **405,908**        |
| 🐍 **Python (FastAPI)** | `8083` | 261 MB      | 54 MiB     | 78 MiB          | 1000m    | **9,020.20 req/s**  | **11.19 ms**   | **270,912**        |

---

### 7.2. Análisis Profundo por Lenguaje y Framework

#### A. Rust (Axum) - El Líder Imbatible en Eficiencia

- **Memoria RAM**: Espectacular. En reposo consume apenas **1 MiB**. Bajo tráfico masivo apenas sube a 12 MiB.
- **Rendimiento**: Procesa **>75,000 req/s** con una latencia ultra baja de **1.41 ms**.
- **Veredicto**: Es la opción definitiva cuando se busca máxima densidad de Pods y rendimiento crítico en infraestructura limitada.

#### B. Bun (Elysia) - La Revelación en el Ecosistema JavaScript

- **Memoria RAM**: Consume **94 MiB** en idle debido al runtime de Bun / JavaScriptCore.
- **Rendimiento**: Alcanza la sorprendente cifra de **>53,000 req/s** con **1.87 ms** de latencia.
- **Veredicto**: Supera por más del doble a NestJS en rendimiento utilizando menos memoria RAM.

#### C. Go (Gin) - El Estándar de la Industria para Microservicios

- **Imagen Docker**: **La más liviana con diferencia (31.6 MB)**.
- **Memoria RAM**: **20 MiB** en reposo. Muy bajo impacto en servidores VPS pequeños.
- **Rendimiento**: Muy estable a **16,591 req/s**.

#### D. NestJS (Fastify vs Express) - El Poder del Adaptador HTTP

- Al cambiar el motor interno de NestJS de **Express a Fastify**, el throughput se incrementa de **13,527 req/s a 24,569 req/s (+81.6% de velocidad)** manteniendo exactamente el mismo uso de memoria RAM (~125 MiB).

#### E. Java (Spring Boot) - Exigente en Memoria RAM

- Requiere **206 MiB de RAM en reposo** y sube a **248 MiB bajo carga**. Por esta razón, su manifiesto debió configurarse con un límite mayor de `512Mi` RAM para evitar reinicios por OOM.

#### F. Python (FastAPI) - Productividad vs Rendimiento Crudo

- Excelente para prototipado rápido, pero su modelo asíncrono sobre un único hilo principal limita su capacidad a **9,020 req/s**, siendo el más lento de la comparativa en alta concurrencia.

---

### 7.3. Matriz de Decisiones Técnicas para Hardware Limitado

| Restricción Principal de Servidor           | Lenguaje / Framework Recomendado         | Razón Técnica Principal                                                             |
| ------------------------------------------- | ---------------------------------------- | ----------------------------------------------------------------------------------- |
| **RAM Crítica (< 2 GB total en servidor)**  | 🦀 **Rust (Axum)**                       | 1 MiB de consumo en RAM por Pod. Permite desplegar decenas de microservicios.       |
| **Imágenes Pequeñas + Despliegues Rápidos** | 🐹 **Go (Gin)**                          | Imagen de solo 31.6 MB y uso de 20 MiB RAM en reposo.                               |
| **Requisito Empresarial de TypeScript**     | ⚡ **Bun (Elysia)** o **Nest (Fastify)** | Bun rinde a 53k req/s. En NestJS, cambiar a Fastify aumenta la velocidad en +81.6%. |
| **Prototipado Rápido / Data Science**       | 🐍 **Python (FastAPI)**                  | Alta velocidad de desarrollo a costa de menor rendimiento en cargas masivas.        |

---

## 8. Guía Tutorial: Cómo Agregar un Nuevo Competidor al Benchmark

Imagina que tu equipo desarrolla un nuevo microservicio CRUD (por ejemplo en C# .NET, Ruby, PHP o un nuevo framework Node.js) y deseas añadirlo al clúster que **ya se encuentra en ejecución con los otros servicios**.

A continuación se muestra el procedimiento paso a paso para integrarlo sin interrumpir el laboratorio existente.

---

### 8.1. Escenario de Ejemplo: Añadir `07-nests-express` o una Nueva API

Supongamos que creamos la carpeta `./08-dotnet-api` o deseamos agregar el manifiesto de `./07-nests-express` para exponerlo en el puerto host `8087` o `8088`.

---

### 8.2. Paso 1: Preparación del Código y Dockerfile

Crea en la raíz del nuevo proyecto un archivo `Dockerfile` optimizado (multi-stage build si es aplicable).

Asegúrate de que la aplicación implemente la ruta `/health` retornando un código de estado HTTP `200 OK`:

```json
{ "status": "ok" }
```

---

### 8.3. Paso 2: Creación del Manifiesto Kubernetes (YAML)

Crea un archivo de manifiesto `08-nuevo-servicio.yaml` dentro de la carpeta `00-k8s-manifests/` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nuevo-servicio
  namespace: l-namespace
  labels:
    app: nuevo-servicio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nuevo-servicio
  template:
    metadata:
      labels:
        app: nuevo-servicio
    spec:
      containers:
        - name: nuevo-servicio
          image: nuevo-servicio:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8088
          env:
            - name: APP_PORT
              value: "8088"
          resources:
            requests:
              cpu: "250m"
              memory: "128Mi"
            limits:
              cpu: "1000m"
              memory: "256Mi"
          livenessProbe:
            httpGet:
              path: /health
              port: 8088
            initialDelaySeconds: 5
            periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: nuevo-servicio
  namespace: l-namespace
spec:
  type: LoadBalancer
  selector:
    app: nuevo-servicio
  ports:
    - port: 8088
      targetPort: 8088
```

> ⚠️ **Nota Crucial sobre Networking en k3d**: Para que el puerto `8088` sea accesible desde tu máquina host (`http://localhost:8088`), debiste haber incluido dicho puerto al momento de ejecutar `k3d cluster create` con el flag `-p "8081-8088:8081-8088@loadbalancer"`. Si el clúster original se creó con un rango menor (ej. `8081-8087`), debes eliminar y recrear el clúster k3d especificando el rango ampliado.

---

### 8.4. Paso 3: Compilación e Importación al Clúster Activo

Ejecuta la secuencia de comandos para compilar la imagen Docker local e inyectarla directamente en el clúster k3d sin detener los otros pods:

```bash
# 1. Construir la imagen Docker localmente
docker build -t nuevo-servicio:latest ./08-nuevo-servicio

# 2. Importar la nueva imagen dentro del clúster k3d que está corriendo
k3d image import nuevo-servicio:latest -c crud-benchmark
```

---

### 8.5. Paso 4: Despliegue y Ejecución de Pruebas

Aplica el nuevo manifiesto y verifica la integración:

```bash
# 1. Aplicar el manifiesto en el namespace activo
kubectl apply -f 00-k8s-manifests/08-nuevo-servicio.yaml

# 2. Verificar que el pod nuevo se inicie correctamente
kubectl get pods -n crud-benchmark

# 3. Probar la salud del nuevo servicio mediante curl
curl -i http://localhost:8088/health

# 4. Ejecutar la prueba de estrés con wrk
wrk -t4 -c100 -d30s http://localhost:8088/health
```

---

### 8.6. Ejemplo de Integración Adicional: API en C# .NET 8

Para ilustrar cómo se vería la incorporación de otra tecnología muy usada en empresas como C# .NET:

1. **Dockerfile (.NET 8 Minimal API)**:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . ./
RUN dotnet publish -c Release -o /app/out

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/out .
EXPOSE 8088
ENV ASPNETCORE_URLS=http://+:8088
ENTRYPOINT ["dotnet", "DotnetApi.dll"]
```

2. **Comandos de despliegue**:

```bash
docker build -t dotnet-api:latest ./08-dotnet-api
k3d image import dotnet-api:latest -c crud-benchmark
kubectl apply -f 08-dotnet-api.yaml
```

---

## 9. Diccionario y Explicación Detallada de Comandos, Banderas y Conceptos

Esta sección funciona como una referencia de consulta rápida para desarrolladores junior que deseen entender en detalle qué hace cada comando y cada opción utilizada en este proyecto.

---

### 9.1. Comandos de Docker

- `docker build`: Lee el archivo `Dockerfile` del directorio especificado y compila una imagen de contenedor.
  - `-t nombre:etiqueta` (_--tag_): Asigna un nombre legible y una versión a la imagen compilada. Permite identificarla fácilmente.
  - `./directorio`: Define el directorio contexto desde el cual Docker copiará archivos durante el proceso de build.
- `docker images`: Muestra la lista de todas las imágenes almacenadas localmente en el motor Docker.
  - `--format "table ..."`: Permite dar formato tabular personalizado mostrando únicamente las columnas solicitadas (Repository, Tag, Size).
- `docker system df`: Muestra el espacio ocupado en disco por las imágenes, los contenedores activos/inactivos, los volúmenes de datos y la memoria caché de compilación (_build cache_).
  - `-v` (_--verbose_): Desglosa la lista detallada de cada imagen y contenedor individual indicando su tamaño real en megabytes.
- `docker ps`: Muestra los contenedores en ejecución.
  - `-a` (_--all_): Muestra todos los contenedores, incluidos los que se detuvieron o fallaron.
- `docker stop <id>`: Envía una señal `SIGTERM` al contenedor para detener su ejecución de forma segura.

---

### 9.2. Comandos de k3d

- `k3d cluster create <nombre>`: Inicia la creación automatizada de un clúster Kubernetes ligero encapsulado en Docker.
  - `--api-port 6550`: Define el puerto TCP de la máquina host por el que escuchará el Kubernetes API Server (`kube-apiserver`).
  - `-p "puerto_host:puerto_contenedor@loadbalancer"`: Enruta las peticiones HTTP/TCP que llegan a los puertos del host hacia el Proxy Ingress (_Traefik_) que corre dentro del clúster k3d.
  - `--agents N`: Define la cantidad de nodos de trabajo (_Worker Nodes_) que procesarán los Pods de la aplicación.
- `k3d image import <imágenes> -c <clúster>`: Exporta imágenes del daemon de Docker y las inyecta en el registro del runtime interno de k3d (_containerd_). Evita que Kubernetes intente buscarlas en internet.
- `k3d cluster delete <nombre>`: Elimina por completo los contenedores Docker y las redes asociadas al clúster k3d liberando todos los recursos de tu máquina.

---

### 9.3. Comandos de kubectl

- `kubectl apply -f <ruta>`: Aplica una configuración declarativa sobre el clúster basada en archivos YAML.
  - `-f` (_--filename_): Especifica la ruta del archivo o directorio que contiene los manifiestos de Kubernetes.
- `kubectl get <tipo_recurso>`: Consulta y despliega el estado de los recursos solicitados.
  - `pods`: Muestra los Pods con su estado (`Running`, `Pending`, `CrashLoopBackOff`), réplicas listas y reinicios.
  - `deployments`: Muestra los despliegues declarados y la disponibilidad de réplicas.
  - `services`: Muestra las IP virtuales internas y los puertos expuestos.
  - `-n <namespace>`: Especifica el espacio de nombres (_Namespace_) sobre el cual se realizará la consulta.
- `kubectl top pods`: Muestra el consumo en tiempo real de CPU y memoria RAM recopilado por `metrics-server`.
  - `--containers`: Muestra el detalle desagregado por contenedor dentro de cada Pod.
- `kubectl scale deployment <nombre> --replicas=N`: Modifica la cantidad de réplicas (_Pods_) que deben ejecutarse en paralelo para un Deployment.
- `kubectl rollout restart deployment <nombre>`: Inicia un reinicio progresivo de los Pods. Mata un Pod antiguo solo después de que el nuevo Pod pasa las pruebas de salud (_liveness/readiness probes_).
- `kubectl delete namespace <nombre>`: Elimina el namespace y destruye automáticamente todos los recursos creados dentro de él.

---

### 9.4. Comandos de k9s

- `k9s`: Ejecuta la interfaz gráfica interactiva en terminal.
  - `-n <namespace>`: Abre la herramienta enfocada directamente en el namespace especificado.
- `:pods`: Filtro de comando interno en k9s para listar los Pods del clúster.
- `:deploy`: Filtro de comando interno para listar Deployments.
- `:svc`: Filtro de comando interno para listar Servicios de red.
- `:nodes`: Filtro de comando interno para ver la salud de los Nodos físicos o virtuales.
- `l` (_Logs_): Muestra la consola de salida estándar en tiempo real del contenedor seleccionado.
- `s` (_Shell_): Abre una sesión `bash` o `sh` dentro del contenedor seleccionado.
- `d` (_Describe_): Muestra los eventos y configuración detallada del recurso seleccionado.
- `Ctrl + s`: Abre el cuadro de diálogo para cambiar dinámicamente la cantidad de réplicas del Deployment seleccionado.

---

### 9.5. Comandos de wrk

- `wrk <opciones> <URL>`: Herramienta de pruebas de carga de alto rendimiento.
  - `-t <hilos>` (_--threads_): Define la cantidad de hilos de CPU que generarán peticiones en paralelo.
  - `-c <conexiones>` (_--connections_): Especifica el número total de conexiones HTTP concurrentes abiertas.
  - `-d <duración>` (_--duration_): Especifica el tiempo total durante el cual se mantendrá el envío de peticiones (ej. `30s`, `2m`).

---

### 9.6. Comandos de curl

- `curl <URL>`: Cliente HTTP de línea de comandos para enviar peticiones a servidores web.
  - `-i` (_--include_): Incluye las líneas de respuesta HTTP (Headers) en el resultado.
  - `-X POST` / `-X PUT` / `-X DELETE`: Especifica el método HTTP de la petición.
  - `-H "Content-Type: application/json"`: Envía encabezados personalizados.
  - `-d '{"key":"value"}'`: Envía datos en el cuerpo (_body_) de la petición.

---

### 9.7. Glosario de Términos Avanzados de Infraestructura

- **NodePort**: Tipo de servicio en Kubernetes que expone una aplicación en un puerto estático (en el rango 30000-32767) en la IP de cada nodo.
- **LoadBalancer**: Tipo de servicio que integra un balanceador de carga externo o un ingress controller para direccionar el tráfico entrante.
- **LivenessProbe**: Prueba periódica que ejecuta Kubernetes para verificar si la aplicación está viva. Si falla, Kubernetes destruye y reinicia el contenedor.
- **ReadinessProbe**: Prueba periódica para verificar si la aplicación está lista para recibir tráfico. Si falla, el Pod se remueve temporalmente del balanceador de carga sin destruirlo.
- **OOMKilled (Exit Code 137)**: Estado de terminación forzada donde el kernel del sistema operativo mata un proceso por exceder el límite de memoria asignado.
- **Goroutine**: Hilo de ejecución liviano gestionado directamente por el runtime de Go (no por el SO), capaz de ejecutar miles de tareas concurrentes con apenas 2 KB de stack inicial.
- **Tokio Runtime**: Framework asíncrono en Rust impulsado por un bucle de eventos multitarea sin bloqueo de I/O.
- **Garbage Collection (GC)**: Proceso automático de liberación de memoria RAM no utilizada presente en lenguajes como Java, Go y JavaScript.
- **JIT Compilation (Just-In-Time)**: Compilación en tiempo de ejecución utilizada por V8 (Node.js) y JVM (Java) para convertir bytecode en código máquina durante la ejecución.

---

## 10. Resolución de Problemas Frecuentes (Troubleshooting)

---

### 10.1. Error: `ErrImagePull` / `ImagePullBackOff`

**Síntoma**: Al ejecutar `kubectl get pods -n crud-benchmark`, el Pod muestra el estado `ErrImagePull` o `ImagePullBackOff`.

**Causa**: Kubernetes intentó buscar la imagen en un registro público de internet (Docker Hub) porque no existe en el registro local de `k3d`.

**Solución**:
Reimporta la imagen al clúster e inicia un reinicio gradual del deployment:

```bash
# Importar la imagen específica al clúster k3d
k3d image import go_crud:latest -c crud-benchmark

# Reiniciar los pods para que tomen la imagen cargada
kubectl rollout restart deployment go-crud -n crud-benchmark
```

---

### 10.2. Error: `port is already allocated` al Crear el Clúster

**Síntoma**: Al ejecutar `k3d cluster create`, aparece un mensaje de error indicando que un puerto (ej. 8081) ya está ocupado.

**Causa**: Tienes otro proceso o un contenedor previo escuchando en ese mismo puerto de tu computadora host.

**Solución**:

1. Averigua qué contenedor o proceso usa el puerto:

```bash
sudo lsof -i :8081
# o bien
docker ps | grep 8081
```

2. Detén el contenedor conflictivo:

```bash
docker stop <container_id>
```

---

### 10.3. Error: `metrics not available` al Ejecutar `kubectl top`

**Síntoma**: Al ejecutar `kubectl top pods -n crud-benchmark`, la terminal devuelve `error: Metrics API not available`.

**Causa**: `metrics-server` no está instalado o no puede comunicarse con los Kubelets debido a certificados SSL autofirmados.

**Solución**: Vuelve a aplicar la instalación y el parche de seguridad para k3d:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

Espera 30 segundos a que el servicio recolecte las primeras métricas y vuelve a intentar `kubectl top pods -n crud-benchmark`.

---

### 10.4. Pod Reiniciado por `OOMKilled` (Out Of Memory)

**Síntoma**: El Pod se reinicia repentinamente y la columna `RESTARTS` aumenta a 1. Al ejecutar `kubectl describe pod <nombre_pod> -n crud-benchmark` se observa la razón `OOMKilled`.

**Causa**: El proceso consumió más memoria RAM que el límite estipulado en el campo `resources.limits.memory` del YAML.

**Solución**: Incrementa el límite de memoria del servicio en su archivo YAML (por ejemplo de `256Mi` a `512Mi`):

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"
```

Aplica el cambio con `kubectl apply -f 00-k8s-manifests/<archivo.yaml>`.

---

## 11. Comandos de Mantenimiento y Limpieza Final

Cuando hayas concluido la ejecución de tus pruebas o la exposición ante la audiencia, puedes reiniciar los servicios o eliminar la infraestructura por completo para liberar recursos en tu computadora.

```bash
# 1. Reiniciar progresivamente todos los Deployments del laboratorio
kubectl rollout restart deployment -n crud-benchmark --all

# 2. Eliminar únicamente el Namespace (destruye Pods, Servicios y Deployments)
kubectl delete namespace crud-benchmark

# 3. Eliminar por completo el Clúster k3d y borrar todos sus contenedores asociados
k3d cluster delete crud-benchmark

# 4. Limpiar contenedores e imágenes huérfanas en Docker
docker system prune -f
```

---

_Fin del Manual Técnico y Guía de Operación del CRUD Benchmark._
