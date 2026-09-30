# 🔧 Creación de Workflow en IWHI



![Workflow Transferencias](img/workflow-transferencias.png)

---

## Paso 1 — Crear el Webhook (Trigger)

El primer bloque del workflow es un **Webhook** que actúa como trigger: el flujo se gatilla cada vez que un cliente realiza una transferencia.

### Configuración

En IWHI, al crear el Webhook se te entregará una URL. El body que debe recibir tiene la siguiente estructura:

```json
{
  "numero_cuenta": "ES0100010001001234567890",
  "monto": 1000,
  "trx_id": 1234
}
```

| Campo | Tipo | Descripción |
|---|---|---|
| `numero_cuenta` | `string` | Número de cuenta del cliente que realiza la transferencia |
| `monto` | `number` | Monto de la transferencia |
| `trx_id` | `number` | Identificador único de la transacción |


---

## Paso 2 — Return Data on Sync Webhook

Agrega un bloque **Return** inmediatamente después del Webhook. Este paso captura y expone la data recibida en el body del request para que los bloques siguientes del flujo puedan utilizarla.

---

## Paso 3 — getClientInfo (FlowService)

Agrega el FlowService **`getClientInfo`** (creado previamente). Este bloque consulta la base de datos on-premise usando el `numero_cuenta` recibido en el webhook y retorna la información completa del cliente, incluyendo el saldo disponible en su cuenta.

---

## Paso 4 — Switch (Evaluación de sobregiro)

Agrega un bloque **Switch** que evalúa si la transacción debe ser aprobada o rechazada comparando el `monto` del webhook contra el `saldo` retornado por `getClientInfo`:

| Case | Condición | Resultado |
|---|---|---|
| `case 1` | `monto` ≤ `saldo` | ✅ Aprobado |
| `default` | `monto` > `saldo` | ❌ Rechazado — sobregiro |

---

## Paso 5 — Return (Respuesta al webhook)

Cada rama del Switch debe terminar con un bloque **Return** que devuelve el resultado de la evaluación como respuesta HTTP al caller. Esto permite que la web de pruebas muestre el resultado en tiempo real.

### 5.1 — Rama aprobada (`case 1`)

Configura el bloque Return con el siguiente JSON:

```json
{
  "resultado": "aprobado",
  "trx_id": "$trx_id",
  "numero_cuenta": "$numero_cuenta",
  "monto": "$monto",
  "nombre": "$nombre",
  "apellido": "$apellido",
  "saldo": "$saldo"
}
```

> Reemplaza cada `$campo` con el mapeo al valor correspondiente del contexto del workflow (el `trx_id` y `monto` vienen del webhook; `nombre`, `apellido` y `saldo` vienen del FlowService `getClientInfo`).

### 5.2 — Rama rechazada (`default`)

Configura el bloque Return con el siguiente JSON:

```json
{
  "resultado": "rechazado",
  "trx_id": "$trx_id",
  "numero_cuenta": "$numero_cuenta",
  "monto": "$monto",
  "nombre": "$nombre",
  "apellido": "$apellido",
  "saldo": "$saldo",
  "motivo": "Saldo insuficiente"
}
```

El campo `motivo` es texto fijo — no necesita mapeo dinámico.

---

## Paso 6 — Probar con el Transaction Tester

Con el workflow completo y activo en IWHI, levanta la web de pruebas para enviar transacciones reales y ver el resultado en vivo.

### 6.1 — Levantar el contenedor

La base de datos ya está corriendo desde la PT1. Solo hay que levantar el nuevo servicio desde la raíz del proyecto:

```bash
# Docker
docker compose up -d transaction-tester

# Podman
podman compose up -d transaction-tester
```

Abre **http://localhost:8080** en el navegador.

### 6.2 — Configurar la URL del webhook

1. Copia la URL del webhook que te entregó IWHI en el Paso 1.
2. Pégala en el campo **URL del workflow (IWHI)** de la web. Se guarda automáticamente en el navegador.

### 6.3 — Enviar transacciones de prueba

1. Haz clic en **Cargar cuentas** — la web consulta la base de datos y muestra las cuentas disponibles.
2. Selecciona una cuenta de la tabla.
3. Ingresa un **monto menor al saldo** de la cuenta → deberías ver ✅ **Transacción aprobada**.
4. Ingresa un **monto mayor al saldo** → deberías ver ❌ **Transacción rechazada**.

El registro al final de la página muestra el detalle completo de cada llamada (request enviado, HTTP status y respuesta raw de IWHI).
