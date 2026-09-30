# 🏗️ Arquitectura PT1 bootcamp

Este ambiente simula un escenario de **integración híbrida real**: la base de datos existe on-premise (en tu máquina, via Docker) y el Edge Runtime de IWHI se instala después para conectarla a la nube — exactamente como ocurre en una empresa que quiere exponer sus sistemas internos a plataformas SaaS sin abrir su firewall.

![Arquitectura del ambiente](img/arquitectura-ambiente.png)

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

![Cliente SQL conectado a bootcamp_db](img/PT1-1.png)

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

![Resultado del SELECT * FROM clientes](img/PT1-2.png)

---

## Paso 3 — Instalar el IWHI Edge Runtime en la misma red

En la consola de IBM Integration, ve a **Manage your runtimes** desde el home:

![Home de IBM Integration](img/PT1-5.png)

Luego hacé clic en **Register runtime** y seleccioná **Edge runtime**:

![Registrar un nuevo Edge Runtime](img/PT1-6.png)

En el paso de conexión, hacé clic en **Generate Credentials** para autenticarte con el registry y obtener el comando `docker pull` con la imagen del runtime:

![Wizard de registro — credenciales y descarga de la imagen](img/PT1-7.png)

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

![Wizard de registro — Definir nombre](images/image_bootcamp_01.png)

Configurá la ubicación o metadata si aplica:

![Wizard de registro — Metadata](images/image_bootcamp_02.png)

También se mostrará el comando de ejecución (`docker run`) con los tokens de registro correspondientes:

![Comando de registro del Runtime](images/image_bootcamp_03.png)

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

![Lista de Runtimes — Estado Ready](images/image_bootcamp_05.png)

Al ingresar al runtime, verás el detalle de réplicas conectadas y el botón para sincronizar configuraciones:

![Detalle del Runtime y réplicas](images/image_bootcamp_06.png)

---

## Paso 4 — Crear el proyecto en IWHI

Una vez que el runtime esté registrado, creá un nuevo proyecto donde vas a construir el FlowService. En la sección **Projects**, hacé clic en **New project → Create**:

![Crear un nuevo proyecto en IWHI](img/PT1-3.png)

Completá el formulario con el nombre del proyecto y hacé clic en **Create**:

![Formulario de nuevo proyecto](img/PT1-4.png)

---

## Paso 5 — Crear el FlowService `getClientInfo` en IWHI

### 5.1 — Crear el FlowService y asociar el Runtime

Dentro del proyecto creado (ej: `bootcamp_beetech`), ve a la sección **Flow services** y haz clic en **+** o **Create a new flow service**:

![Crear nuevo Flow Service](images/image_bootcamp_07.png)

Selecciona el tipo de Flow Service como **Deploy Anywhere Flow Service**:

![Seleccionar tipo Deploy Anywhere Flow Service](images/image_bootcamp_08.png)

En el editor del Flow Service, en la esquina superior derecha selecciona tu Edge Runtime (`runtime_beetech`):

![Seleccionar Edge Runtime en el canvas](images/image_bootcamp_09.png)

Haz clic en **Sync** para asegurar que el Flow Service esté sincronizado con el runtime:

![Sincronizar con el runtime](images/image_bootcamp_10.png)

Asigna el nombre `getClientInfo` al Flow Service y haz clic en **Save**:

![Guardar Flow Service con nombre getClientInfo](images/image_bootcamp_11.png)

---

### 5.2 — Configurar la cuenta y conexión a la base de datos

En el canvas del Flow Service, haz clic en **+** para agregar el primer paso y busca el conector **Database**:

![Seleccionar conector Database](images/image_bootcamp_12.png)

En el menú de acciones del conector Database, selecciona **Add Custom Action**:

![Agregar Custom Action en Database](images/image_bootcamp_13.png)

En la pantalla de configuración de la acción:
1. Define el **Action name** como `getClientInfo`.
2. En **Connect to account Database**, haz clic para crear/asociar una cuenta:

![Configurar Action getClientInfo y seleccionar cuenta](images/image_bootcamp_14.png)

Haz clic en **Add account** y define el nombre de la cuenta (ej: `postgres_bootcamp`):

![Crear cuenta postgres_bootcamp](images/image_bootcamp_15.png)

Sube el driver JDBC de PostgreSQL (`postgresql-42.7.9.jar` disponible en la raíz del repositorio):

![Cargar driver JDBC PostgreSQL](images/image_bootcamp_16.png)

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

![Formulario de configuración de cuenta](images/image_bootcamp_17.png)

![Datos de conexión completados](images/image_bootcamp_18.png)

Haz clic en **Save** / **Next**. Se sincronizarán y desplegarán los assets en el Edge Runtime:

![Sincronización de assets en Edge Runtime](images/image_bootcamp_19.png)

Haz clic en **Test connection** para validar la conectividad:

![Test connection de la cuenta](images/image_bootcamp_20.png)

Verifica que aparezca el mensaje de éxito `Success: Test Account is successful` y luego haz clic en **Enable**:

![Test de conexión exitoso](images/image_bootcamp_21.png)

Confirma que la cuenta quede habilitada (`Success: Account is enabled`) y haz clic en **Done**:

![Cuenta habilitada con éxito](images/image_bootcamp_22.png)

Selecciona la cuenta `postgres_bootcamp` recién creada para la acción y haz clic en **Next**:

![Cuenta seleccionada en la acción](images/image_bootcamp_23.png)

---

### 5.3 — Configurar la acción `getClientInfo` (Query a la tabla `clientes`)

Selecciona el tipo de operación **Select**:

![Seleccionar operación Select](images/image_bootcamp_24.png)

En el paso **Tables**, haz clic en **+** para agregar la tabla:

![Paso Tables — Agregar tabla](images/image_bootcamp_25.png)

Despliega el catálogo `bootcamp_db`, el esquema `public` y selecciona la tabla `clientes`:

![Seleccionar tabla public.clientes](images/image_bootcamp_26.png)

Verifica que se agregue `bootcamp_db.public.clientes` con el alias correspondiente:

![Tabla agregada con alias](images/image_bootcamp_27.png)

![Alias de tabla clientes](images/image_bootcamp_28.png)

En el paso **Joins**, no es necesario agregar joins ya que es una única tabla; haz clic en **Next**:

![Paso Joins](images/image_bootcamp_29.png)

En el paso **Data fields**, haz clic en **+** para agregar los campos a retornar:

![Paso Data fields](images/image_bootcamp_30.png)

Selecciona los campos de la tabla `clientes` (o todos los campos):

![Seleccionar campos de clientes](images/image_bootcamp_32.png)

Verifica la lista de campos seleccionados y sus tipos de datos de salida:

![Lista de campos seleccionados](images/image_bootcamp_33.png)

En el paso **Condition**, configura la cláusula `WHERE` para filtrar por el número de cuenta:

![Paso Condition — WHERE](images/image_bootcamp_34.png)

Haz clic en **+** para agregar la condición y selecciona el campo `numero_cuenta`:

![Seleccionar campo numero_cuenta para condición](images/image_bootcamp_35.png)

Define la condición con el operador `=` y el placeholder `?` para el parámetro de entrada:

```sql
clientes.numero_cuenta = ?
```

![Configuración del parámetro numero_cuenta en WHERE](images/image_bootcamp_36.png)

Revisa el **Summary** con la consulta SQL generada y haz clic en **Done**:

```sql
Select clientes.id as id_1, clientes.numero_cuenta as numero_cuenta, clientes.nombre as nombre_1, clientes.apellido as apellido_1, clientes.email as email_1, clientes.telefono as telefono_1, clientes.fecha_nacimiento as fecha_nacimiento_1, clientes.tipo_cuenta as tipo_cuenta_1, clientes.saldo as saldo_1, clientes.activo as activo_1, clientes.fecha_alta as fecha_alta_1 from clientes clientes where clientes.numero_cuenta = ?
```

![Resumen de la acción SQL](images/image_bootcamp_37.png)

La acción quedará incorporada en el flujo del Flow Service:

![Acción agregada al canvas](images/image_bootcamp_31.png)

---

### 5.4 — Configurar Signature (Input/Output), Pipeline Mappings y Testear

Abre la vista de **Pipeline / I/O** del Flow Service para configurar los parámetros de entrada y salida:

![Vista de Pipeline inicial](images/image_bootcamp_38.png)

![Detalle de I/O en Pipeline](images/image_bootcamp_39.png)

En **Define input and output fields** (signature), agrega en **Input Fields** un campo `numero_cuenta` de tipo `String` y márcalo como requerido:

![Definir Input Field numero_cuenta](images/image_bootcamp_40.png)

En el mapeo de Pipeline, mapea `Pipeline Input -> numero_cuenta` hacia `doc getClientInfo_Input -> numero_cuenta_1`:

![Mapeo de Input numero_cuenta hacia la acción](images/image_bootcamp_41.png)

![Detalle del enlace de mapeo de entrada](images/image_bootcamp_42.png)

![Pipeline mapping completado](images/image_bootcamp_43.png)

Para probar la ejecución, puedes usar alguno de los números de cuenta existentes en la base de datos (por ejemplo de la muestra del README):

| Número de cuenta | Nombre | Apellido | Tipo cuenta | Saldo |
|---|---|---|---|---|
| `ES0100010001001234567890` | Lucía | Fernández Torres | AHORRO | 12540.75 |
| `ES0100010001009876543210` | Carlos | Ramírez Vega | CORRIENTE | 3200.00 |

![Muestra de datos de cuentas](images/image_bootcamp_44.png)

Ejecuta el Flow Service haciendo clic en **Run** e ingresa el valor de prueba en `numero_cuenta` (ej: `ES0100010001001234567890`):

![Ejecutar Flow Service con valor de prueba](images/image_bootcamp_45.png)

Verifica que el resultado sea exitoso (**Run Successful**) retornando el registro completo del cliente con su saldo:

![Resultado exitoso de ejecución del Flow Service](images/image_bootcamp_46.png)

---

Una vez completado esto, estamos listos para continuar con la construcción del workflow. ➡️ [Ir a PT2 — Creación de Workflow en IWHI](PT2.md)
