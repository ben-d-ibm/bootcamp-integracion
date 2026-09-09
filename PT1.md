# 🏗️ Arquitectura PT1 bootcamp

Este ambiente simula un escenario de **integración híbrida real**: la base de datos existe on-premise (en tu máquina, via Docker) y el Edge Runtime de IWHI se instala después para conectarla a la nube — exactamente como ocurre en una empresa que quiere exponer sus sistemas internos a plataformas SaaS sin abrir su firewall.

![Arquitectura del ambiente](arquitectura-ambiente.png)

### Orden de ejecución

| Paso | Qué se hace | Comando |
|------|-------------|---------|
| 1️⃣ | Levantar la base de datos on-premise | `docker compose up -d` |
| 2️⃣ | Verificar los datos de la base de datos | `./status.sh` |
| 3️⃣ | Registrar el Edge Runtime en IWHI y arrancarlo en la misma red | `podman run --network ...` |
| 4️⃣ | Crear el FlowService en IWHI apuntando a `postgres:5432` | Desde la consola IWHI |
| 5️⃣ | Construir el workflow híbrido (on-prem + SaaS) | Desde la consola IWHI |

---

## 📁 Estructura

```
.
├── docker-compose.yml
├── postgresql-42.7.9.jar   ← driver JDBC para usar en iWHI
├── status.sh               ← verifica el estado del entorno
└── init/
    ├── 01_schema.sql   ← crea la tabla `clientes`
    └── 02_data.sql     ← inserta 30 registros dummy
```

---

## 🔑 Credenciales de conexión

### Desde tu máquina (cliente SQL, pgAdmin de escritorio, etc.)

| Parámetro       | Valor            | |
|-----------------|------------------|---|
| **Host**        | `localhost`      | → Host para conexión en IWHI: `postgres` |
| **Puerto**      | `5432`           | |
| **Base de datos** | `bootcamp_db`  | |
| **Usuario**     | `bootcamp_user`  | |
| **Contraseña**  | `bootcamp_pass`  | |

```
postgresql://bootcamp_user:bootcamp_pass@localhost:5432/bootcamp_db
```

### Desde el IWHI Edge Runtime (FlowService)

El runtime corre en la misma red Docker que Postgres (ver paso 2️⃣), por lo que usa el hostname interno del contenedor:

| Parámetro       | Valor            |
|-----------------|------------------|
| **Host**        | `postgres`       |
| **Puerto**      | `5432`           |
| **Base de datos** | `bootcamp_db`  |
| **Usuario**     | `bootcamp_user`  |
| **Contraseña**  | `bootcamp_pass`  |

---

## 🚀 Paso 1 — Levantar la base de datos on-premise

### Con Docker
```bash
docker compose up -d
```

### Con Podman
```bash
podman-compose up -d
```

> ⏱️ La primera vez descarga las imágenes (~200 MB). Espera unos segundos a que el healthcheck de PostgreSQL sea `healthy` antes de conectarte.

---

## ⚙️ Paso 2 — Instalar el IWHI Edge Runtime en la misma red

La red se llama siempre **`bootcamp_net`** — está definida con nombre fijo en el `docker-compose.yml`, sin importar el nombre de tu carpeta.

Puedes confirmarlo con:

```bash
podman network ls | grep bootcamp_net
```

Úsalo en el flag `--network` al correr el runtime:

```bash
podman run \
  --network bootcamp_net \
  -p 5555:5555 \
  -p 4430:443 \
  -d \
  --platform linux/amd64 \
  -e SAG_IS_CLOUD_REGISTER_URL=<URL-de-tu-tenant> \
  -e SAG_IS_EDGE_CLOUD_ALIAS=<nombre-del-runtime> \
  -e SAG_IS_CLOUD_REGISTER_TOKEN=<token-del-paso-4-de-IWHI> \
  -e METERING_TOKEN=<metering-token> \
  --name=<nombre-del-runtime> \
  iwhicr.azurecr.io/webmethods-edge-runtime:12.0.4.0
```

> ⚠️ El token de registro expira en ~15 minutos. Genera el runtime en IWHI, deja abierta la pantalla del paso 4 y ejecuta el comando inmediatamente.

Confirma que el runtime conectó con IWHI:

```bash
podman logs -f <nombre-del-runtime>
# Busca: "Edge instance registration is successful"
```

---


### 🔄 Eliminar y volver a correr el Edge Runtime (Podman)

Si necesitas eliminar el contenedor del runtime y arrancarlo de nuevo:

```bash
podman rm -f <nombre-del-runtime>
```

Luego vuelve a ejecutar el comando del paso 3️⃣.

---

## 🔍 Conectar con psql (opcional)

```bash
# Docker
docker exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db

# Podman
podman exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db
```

---

## 🗄️ Tabla `clientes`

| Columna           | Tipo           | Descripción                          |
|-------------------|----------------|--------------------------------------|
| `id`              | SERIAL (PK)    | Identificador autoincremental        |
| `numero_cuenta`   | VARCHAR(20)    | Número IBAN único                    |
| `nombre`          | VARCHAR(100)   | Nombre del cliente                   |
| `apellido`        | VARCHAR(100)   | Apellidos del cliente                |
| `email`           | VARCHAR(150)   | Email único                          |
| `telefono`        | VARCHAR(20)    | Teléfono de contacto                 |
| `fecha_nacimiento`| DATE           | Fecha de nacimiento                  |
| `tipo_cuenta`     | VARCHAR(20)    | `CORRIENTE`, `AHORRO` o `NOMINA`     |
| `saldo`           | NUMERIC(15,2)  | Saldo actual en euros                |
| `activo`          | BOOLEAN        | Estado de la cuenta                  |
| `fecha_alta`      | TIMESTAMP      | Fecha de apertura de la cuenta       |

### Consultas de ejemplo

```sql
-- Todos los clientes
SELECT * FROM clientes;

-- Clientes con cuenta de ahorro y saldo > 10.000 €
SELECT nombre, apellido, saldo
FROM clientes
WHERE tipo_cuenta = 'AHORRO' AND saldo > 10000
ORDER BY saldo DESC;

-- Resumen por tipo de cuenta (vista precreada)
SELECT * FROM v_resumen_clientes;
```

---

## ✅ Verificar que todo funciona

```bash
# Ver estado de los contenedores
docker compose ps

# Esperar a que postgres esté healthy
docker compose logs postgres
```
