# 🏗️ Lab 1 — Ambiente local y FlowService

Este ambiente simula un escenario de **integración híbrida real**: la base de datos existe on-premise (en tu máquina, via Docker) y el Edge Runtime de IWHI se instala después para conectarla a la nube — exactamente como ocurre en una empresa que quiere exponer sus sistemas internos a plataformas SaaS sin abrir su firewall.

![Arquitectura del ambiente](img/lab1/lab1-01.png)

---

## Paso 1 — Levantar la base de datos

Corre el siguiente comando según tu entorno. Esto levantará un contenedor con PostgreSQL y ejecutará automáticamente los scripts de inicialización que crearán la tabla `clientes` y la llenarán con 30 registros dummy.

```bash
docker compose up -d
```

```bash
podman-compose up -d
```

> ⏱️ La primera vez descarga las imagen (~200 MB). Espera unos segundos a que el healthcheck de PostgreSQL sea `healthy` antes de continuar.

---

## Paso 2 — Verificar los datos de conexión y la carga de datos

Para verificar que los datos se cargaron correctamente, tienes dos alternativas:

---
**Alternativa A — desde un cliente SQL (pgAdmin, DBeaver, etc.)**

Conéctate usando estos datos:

| Parámetro | Valor |
|---|---|
| **Host** | `localhost` |
| **Puerto** | `5432` |
| **Base de datos** | `bootcamp_db` |
| **Usuario** | `bootcamp_user` |
| **Contraseña** | `bootcamp_pass` |

![Cliente SQL conectado a bootcamp_db](img/lab1/lab1-02.png)

---
**Alternativa B — desde la consola del contenedor**

Entra a la consola de PostgreSQL con el comando correspondiente a tu entorno:

```bash
docker exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db
```

```bash
podman exec -it bootcamp_postgres psql -U bootcamp_user -d bootcamp_db
```
---
En cualquier caso, ejecuta:

```sql
SELECT * FROM clientes;
```

Deberías ver algo así:

![Resultado del SELECT * FROM clientes](img/lab1/lab1-03.png)

---

## Paso 3 — Instalar el IWHI Edge Runtime en la misma red

En la consola de IBM Integration, ve a **Manage your runtimes** desde el home:

![Home de IBM Integration](img/lab1/lab1-04.png)

Luego hacé clic en **Register runtime** y seleccioná **Edge runtime**:

![Registrar un nuevo Edge Runtime](img/lab1/lab1-05.png)

En el paso de conexión, hacé clic en **Generate Credentials** para autenticarte con el registry y obtener el comando `docker pull` con la imagen del runtime:

![Wizard de registro — credenciales y descarga de la imagen](img/lab1/lab1-06.png)

Ejecutá los dos comandos que te genera la pantalla. Primero el login con tus credenciales:

```bash
docker login -u "<tu-usuario>" -p "<tu-token>" iwhicr.azurecr.io
```

```bash
podman login -u "<tu-usuario>" -p "<tu-token>" iwhicr.azurecr.io
```

Y luego el pull de la imagen:

```bash
docker pull iwhicr.azurecr.io/webmethods-edge-runtime:12.0.5.0
```

```bash
podman pull iwhicr.azurecr.io/webmethods-edge-runtime:12.0.5.0
```

> ⏱️ La imagen pesa ~1.5 GB. Puede tardar varios minutos dependiendo de tu conexión.

Se abrirá el wizard de registro. En el primer paso, definí el nombre del runtime (ej: `runtime_beetech`):

![Wizard de registro — Definir nombre](img/lab1/lab1-07.png)

Configurá la ubicación o metadata si aplica:

![Wizard de registro — Metadata](img/lab1/lab1-08.png)

También se mostrará el comando de ejecución (`docker run`) con los tokens de registro correspondientes:

![Comando de registro del Runtime](img/lab1/lab1-09.png)

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

Una vez registrado y ejecutado el contenedor, podés verificar en **Manage integration runtimes** que el runtime figure en estado `Ready`:

![Lista de Runtimes — Estado Ready](img/lab1/lab1-10.png)

Al ingresar al runtime, verás el detalle de réplicas conectadas y el botón para sincronizar configuraciones:

![Detalle del Runtime y réplicas](img/lab1/lab1-11.png)

---

## Paso 4 — Crear el proyecto en IWHI

Una vez que el runtime esté registrado, creá un nuevo proyecto donde vas a construir el FlowService. En la sección **Projects**, hacé clic en **New project → Create**:

![Crear un nuevo proyecto en IWHI](img/lab1/lab1-12.png)

Completá el formulario con el nombre del proyecto y hacé clic en **Create**:

![Formulario de nuevo proyecto](img/lab1/lab1-13.png)

---

## Paso 5 — Crear el FlowService `getClientInfo` en IWHI

### 5.1 — Crear el FlowService y asociar el Runtime

Dentro del proyecto creado (ej: `bootcamp_beetech`), ve a la sección **Flow services** y haz clic en **+** o **Create a new flow service**:

![Crear nuevo Flow Service](img/lab1/lab1-14.png)

Selecciona el tipo de Flow Service como **Deploy Anywhere Flow Service**:

![Seleccionar tipo Deploy Anywhere Flow Service](img/lab1/lab1-15.png)

En el editor del Flow Service, en la esquina superior derecha selecciona tu Edge Runtime (`runtime_beetech`):

![Seleccionar Edge Runtime en el canvas](img/lab1/lab1-16.png)

Haz clic en **Sync** para asegurar que el Flow Service esté sincronizado con el runtime:

![Sincronizar con el runtime](img/lab1/lab1-17.png)

Asigna el nombre `getClientInfo` al Flow Service y haz clic en **Save**:

![Guardar Flow Service con nombre getClientInfo](img/lab1/lab1-18.png)

---

### 5.2 — Configurar la cuenta y conexión a la base de datos

En el canvas del Flow Service, haz clic en **+** para agregar el primer paso y busca el conector **Database**:

![Seleccionar conector Database](img/lab1/lab1-19.png)

En el menú de acciones del conector Database, selecciona **Add Custom Action**:

![Agregar Custom Action en Database](img/lab1/lab1-20.png)

En la pantalla de configuración de la acción:
1. Define el **Action name** como `getClientInfo`.
2. En **Connect to account Database**, haz clic para crear/asociar una cuenta:

![Configurar Action getClientInfo y seleccionar cuenta](img/lab1/lab1-21.png)

Haz clic en **Add account** y define el nombre de la cuenta `postgres_bootcamp` y como default su runtime antes creado (ej: `runtime_beetech`) y haz clic en **Next**.

![Crear cuenta postgres_bootcamp](img/lab1/lab1-22.png)


Sube el driver JDBC de PostgreSQL (`postgresql-42.7.9.jar` disponible en la raíz del repositorio):

![Cargar driver JDBC PostgreSQL](img/lab1/lab1-23.png)

En la sección **Basic configuration**, completa los datos de conexión:

| Parámetro | Valor |
|---|---|
| **Database** | `POSTGRESQL` |
| **Transaction type** | `NO_TRANSACTION` |
| **DataSource class** | `org.postgresql.ds.PGSimpleDataSource` |
| **Driver group** | `JDBC` |
| **Server name** | `postgres` |
| **Port number** | `5432` |
| **Database name** | `bootcamp_db` |
| **User** | `bootcamp_user` |
| **Password** | `bootcamp_pass` |

> 💡 El host es `postgres` (no `localhost`) porque el runtime corre dentro de la misma red Docker que el contenedor de PostgreSQL.

![Formulario de configuración de cuenta](img/lab1/lab1-24.png)

![Datos de conexión completados](img/lab1/lab1-25.png)

Haz clic en **Next**. Se sincronizarán y desplegarán los assets en el Edge Runtime:

![Sincronización de assets en Edge Runtime](img/lab1/lab1-26.png)

Haz clic en **Test connection** para validar la conectividad:

![Test connection de la cuenta](img/lab1/lab1-27.png)

Verifica que aparezca el mensaje de éxito `Success: Test Account is successful` y luego haz clic en **Enable**:

![Test de conexión exitoso](img/lab1/lab1-28.png)

Confirma que la cuenta quede habilitada (`Success: Account is enabled`) y haz clic en **Done**:

![Cuenta habilitada con éxito](img/lab1/lab1-29.png)

Selecciona la cuenta `postgres_bootcamp` recién creada para la acción y haz clic en **Next**:

![Cuenta seleccionada en la acción](img/lab1/lab1-30.png)

---

### 5.3 — Configurar la acción `getClientInfo` (Query a la tabla `clientes`)

Selecciona el tipo de operación **Select**:

![Seleccionar operación Select](img/lab1/lab1-31.png)

En el paso **Tables**, haz clic en **+** para agregar la tabla:

![Paso Tables — Agregar tabla](img/lab1/lab1-32.png)

Despliega el catálogo `bootcamp_db`, el esquema `public` y selecciona la tabla `clientes`:

![Seleccionar tabla public.clientes](img/lab1/lab1-33.png)

Verifica que se agregue `bootcamp_db.public.clientes` con el alias correspondiente:

![Tabla agregada con alias](img/lab1/lab1-34.png)

![Alias de tabla clientes](img/lab1/lab1-35.png)

En el paso **Joins**, no es necesario agregar joins ya que es una única tabla; haz clic en **Next**:

![Paso Joins](img/lab1/lab1-36.png)

En el paso **Data fields**, haz clic en **+** para agregar los campos a retornar:

![Paso Data fields](img/lab1/lab1-37.png)

Selecciona los campos de la tabla `clientes` (o todos los campos):

![Seleccionar campos de clientes](img/lab1/lab1-38.png)

Verifica la lista de campos seleccionados y sus tipos de datos de salida:

![Lista de campos seleccionados](img/lab1/lab1-39.png)

En el paso **Condition**, configura la cláusula `WHERE` para filtrar por el número de cuenta:

![Paso Condition — WHERE](img/lab1/lab1-40.png)

Haz clic en **+** para agregar la condición y selecciona el campo `numero_cuenta`:

![Seleccionar campo numero_cuenta para condición](img/lab1/lab1-41.png)

Define la condición con el operador `=` y el placeholder `?` para el parámetro de entrada:

```sql
clientes.numero_cuenta = ?
```

![Configuración del parámetro numero_cuenta en WHERE](img/lab1/lab1-42.png)

Revisa el **Summary** con la consulta SQL generada y haz clic en **Done**:

```sql
Select clientes.id as id_1, clientes.numero_cuenta as numero_cuenta, clientes.nombre as nombre_1, clientes.apellido as apellido_1, clientes.email as email_1, clientes.telefono as telefono_1, clientes.fecha_nacimiento as fecha_nacimiento_1, clientes.tipo_cuenta as tipo_cuenta_1, clientes.saldo as saldo_1, clientes.activo as activo_1, clientes.fecha_alta as fecha_alta_1 from clientes clientes where clientes.numero_cuenta = ?
```

![Resumen de la acción SQL](img/lab1/lab1-43.png)

La acción quedará incorporada en el flujo del Flow Service:

![Acción agregada al canvas](img/lab1/lab1-44.png)

---

### 5.4 — Configurar Signature (Input/Output), Pipeline Mappings y Testear

Abre la vista de **Pipeline / I/O** del Flow Service para configurar los parámetros de entrada y salida:

![Vista de Pipeline inicial](img/lab1/lab1-45.png)

![Detalle de I/O en Pipeline](img/lab1/lab1-46.png)

En **Define input and output fields** (signature), agrega en **Input Fields** un campo `numero_cuenta` de tipo `String` y márcalo como requerido:

![Definir Input Field numero_cuenta](img/lab1/lab1-47.png)

En el mapeo de Pipeline, mapea `Pipeline Input -> numero_cuenta` hacia `doc getClientInfo_Input -> numero_cuenta_1`:

![Mapeo de Input numero_cuenta hacia la acción](img/lab1/lab1-48.png)

![Detalle del enlace de mapeo de entrada](img/lab1/lab1-49.png)

![Pipeline mapping completado](img/lab1/lab1-50.png)

Para probar la ejecución, puedes usar alguno de los números de cuenta existentes en la base de datos (por ejemplo de la muestra del README):

| Número de cuenta | Nombre | Apellido | Tipo cuenta | Saldo |
|---|---|---|---|---|
| `ES0100010001001234567890` | Lucía | Fernández Torres | AHORRO | 12540.75 |
| `ES0100010001009876543210` | Carlos | Ramírez Vega | CORRIENTE | 3200.00 |


Ejecuta el Flow Service haciendo clic en **Run** e ingresa el valor de prueba en `numero_cuenta` (ej: `ES0100010001001234567890`):

![Ejecutar Flow Service con valor de prueba](img/lab1/lab1-51.png)

Verifica que el resultado sea exitoso (**Run Successful**) retornando el registro completo del cliente con su saldo:

![Resultado exitoso de ejecución del Flow Service](img/lab1/lab1-52.png)

---

Una vez completado esto, estamos listos para continuar con la construcción del workflow. ➡️ [Ir a Lab 2 — Creación de Workflow en IWHI](lab2.md)
