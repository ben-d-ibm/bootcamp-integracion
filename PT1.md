# 🏗️ Arquitectura PT1 bootcamp

Este ambiente simula un escenario de **integración híbrida real**: la base de datos existe on-premise (en tu máquina, via Docker) y el Edge Runtime de IWHI se instala después para conectarla a la nube — exactamente como ocurre en una empresa que quiere exponer sus sistemas internos a plataformas SaaS sin abrir su firewall.

![Arquitectura del ambiente](img/arquitectura-ambiente.png)

---

## Paso 1 — Levantar la base de datos

Corre el siguiente comando según tu entorno. Esto levantará un contenedor con PostgreSQL y ejecutará automáticamente los scripts de inicialización que crearán la tabla `clientes` y la llenarán con 30 registros dummy.

```bash
# Docker
docker compose up -d

# Podman
podman-compose up -d
```

> ⏱️ La primera vez descarga las imagen (~200 MB). Espera unos segundos a que el healthcheck de PostgreSQL sea `healthy` antes de continuar.

---

## Paso 2 — Verificar los datos de conexión y la carga de datos

Usa estos datos para conectarte desde cualquier cliente SQL (pgAdmin, DBeaver, etc.):

| Parámetro | Valor |
|---|---|
| **Host** | `localhost` |
| **Puerto** | `5432` |
| **Base de datos** | `bootcamp_db` |
| **Usuario** | `bootcamp_user` |
| **Contraseña** | `bootcamp_pass` |

Para verificar que los datos se cargaron correctamente, entra a la consola de PostgreSQL:

```bash
# Docker
docker exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db

# Podman
podman exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db
```

Y luego ejecuta:

```sql
SELECT * FROM clientes;
```

---

## Paso 3 — Instalar el IWHI Edge Runtime en la misma red

El runtime debe correr dentro de la misma red Docker que Postgres (`bootcamp_net`) para poder acceder a él usando el hostname interno `postgres`.

Al comando que te entrega IWHI debes hacerle dos ajustes:
1. Agregar la flag `--network bootcamp_net`
2. Cambiar el puerto `-p 4430:443` (el puerto 443 puede estar ocupado en tu máquina)

Ejemplo del comando:

```bash
docker run \
  --network bootcamp_net \
  -p 5555:5555 \
  -p 4430:443 \
  -d \
  ...
```

> ⚠️ El token de registro expira en ~15 minutos. Genera el runtime en IWHI, deja abierta la pantalla y ejecuta el comando inmediatamente.
---

## Paso 4 — Crear el FlowService `getClientInfo` en IWHI

### 4.1 — Sincronizar con el runtime levantado

En la consola de IWHI, crea un nuevo FlowService y sincronízalo con el Edge Runtime que levantaste en el paso anterior.

### 4.2 — Crear la conexión a la base de datos

Configura una nueva conexión con los siguientes datos:

| Parámetro | Valor |
|---|---|
| **Host** | `postgres` |
| **Puerto** | `5432` |
| **Base de datos** | `bootcamp_db` |
| **Usuario** | `bootcamp_user` |
| **Contraseña** | `bootcamp_pass` |

> El host es `postgres` (no `localhost`) porque el runtime corre dentro de la misma red Docker que el contenedor de PostgreSQL.

### 4.3 — Agregar la acción `getClientInfo`

Agrega una acción de tipo query llamada `getClientInfo` que filtre usando `numero_cuenta` como condición:

```sql
SELECT * FROM clientes WHERE numero_cuenta = :numero_cuenta
```

### 4.4 — Configurar el pipeline y testear

Configura el pipeline del FlowService mapeando el parámetro de entrada `numero_cuenta` a la condición de la query. Luego testea el FlowService directamente desde la consola de IWHI usando alguno de los números de cuenta de la base de datos.

---

Una vez completado esto, estamos listos para continuar con la construcción del workflow. ➡️ [Ir a PT2 — Creación de Workflow en IWHI](PT2.md)
