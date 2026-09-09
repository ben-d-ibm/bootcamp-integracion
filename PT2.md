# 🔧 Creación de Workflow en IWHI

## Paso 1 — Crear el Webhook (Trigger)

El primer bloque del workflow es un **Webhook** que actúa como trigger: el flujo se gatilla cada vez que un cliente realiza una transferencia.

### Configuración

En IWHI, al crear el Webhook se te entregará una URL. El body que debe recibir tiene la siguiente estructura:

```json
{
  "numero_cuenta": "test",
  "monto": 1000,
  "trx_id": 1234,
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

## Paso 5 — Produce (Confluent Cloud)

Desde el Switch se abren **dos flujos paralelos**, cada uno con un bloque **Produce** que publica el evento en el tópico correspondiente de Confluent Cloud:

| Caso | Tópico |
|---|---|
| ✅ Aprobado | `beetech_aprobados` |
| ❌ Rechazado | `beetech_rechazados` |

El mensaje publicado debe incluir la información del cliente y el resultado de la evaluación.
