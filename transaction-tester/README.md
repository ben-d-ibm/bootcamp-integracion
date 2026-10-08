# 🔧 Transaction Tester

> ⚠️ Este es el **último paso** del bootcamp: úsalo recién después de completar el [Lab 1](../lab1.md) y el [Lab 2](../lab2.md), cuando el Webhook de tu workflow en IWHI ya esté activo.

App web chica para probar el flujo a mano, transacción por transacción, sin nada automático. Te deja poner la URL del Webhook, elegir una cuenta real de la base de datos y mandar un monto — así puedes ver en vivo cómo avanza tu workflow en IWHI mientras pruebas distintos casos.


---

## Paso 1 — Levantar el contenedor

Necesitas la base de datos ya corriendo (Paso 1 del [Lab 1](../lab1.md)), porque este contenedor se conecta a la misma red `bootcamp_net` para consultarla.

```bash
cd transaction-tester

# Docker
docker compose up --build -d

# Podman
podman-compose up --build -d
```

Abre `http://localhost:8080` en el navegador.

---

## Paso 2 — Probar transacciones

1. **URL del Webhook** — pega la URL que te entregó IWHI en el Paso 1 del Lab 2. Se guarda en el navegador, no hace falta escribirla cada vez.
2. **Cuenta** — click en "Cargar cuentas" para traer las cuentas reales desde Postgres y elige una de la tabla.
3. **Monto** — escríbelo a mano. Usa un monto menor al saldo de la cuenta para ver un caso aprobado, y uno mayor para ver un caso de sobregiro rechazado.
4. **Enviar transacción** — manda la transacción y mira la respuesta en el Registro, abajo. Repite con distintas cuentas y montos las veces que quieras.

> El monto se pone siempre a mano — no hay generación aleatoria, para que controles exactamente qué caso estás probando.

---

Una vez que veas las transacciones aprobadas y rechazadas llegando correctamente a los tópicos de Confluent Cloud, ¡completaste el bootcamp! 🎉
