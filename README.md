# 🏦 Bootcamp Integración — Integración de Aplicaciones en Arquitectura Híbrida

## ¿Qué haremos?

En este hands-on crearemos un Workflow en IWHI que aprueba o rechaza transacciones de envío de dinero desde las cuentas de clientes que tenemos almacenados en una base de datos PostgreSQL que corre de forma local y aislada. 

La conexión a la base de datos que no está expuesta la haremos mediante el despliegue de un runtime self-managed dentro de la misma red de nuestra base de datos, para luego usarlo en un FlowService que hará la conexión hacia el IWHI SaaS.

## Contenido

| Parte | Descripción |
|---|---|
| [📘 PT1 — Arquitectura y ambiente local](PT1.md) | Levantamiento del ambiente Docker/Podman con PostgreSQL e instalación del IWHI Edge Runtime en la misma red |
| [⚙️ PT2 — Creación de Workflow en IWHI](PT2.md) | Construcción del workflow de transferencias: Webhook, FlowService, Switch y publicación en Confluent Cloud |

## 🗄️ Muestra de la base de datos

| numero_cuenta | nombre | apellido | tipo_cuenta | saldo |
|---|---|---|---|---|
| ES0100010001001234567890 | Lucía | Fernández Torres | AHORRO | 12540.75 |
| ES0100010001009876543210 | Carlos | Ramírez Vega | CORRIENTE | 3200.00 |
| ES0100010001005678901234 | Ana | López Martínez | NOMINA | 67890.50 |
| ES0100010001004321098765 | Miguel | García Blanco | CORRIENTE | 580.20 |
| ES0100010001007890123456 | Sara | Martín Soler | AHORRO | 22100.00 |

## 🧪 Testing

Luego de finalizar todos los pasos de la PT1 y PT2, el último paso es testear lo construído.

Para esto usarán alguna de las cuentas de la tabla de arriba y enviarán transacciones mayores o menores al saldo correspondiente. El detalle de las instrucciones para esto se darán directamente en el bootcamp.

---

## 👏 ¡Felicidades!

¡Acabas de realizar un flujo end-to-end de integración de aplicaciones en arquitectura híbrida utilizando las capacidades entregadas por nuestro **IBM webMethods Hybrid Integration**!
