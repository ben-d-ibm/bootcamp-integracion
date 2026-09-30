# 🔧 Transaction Tester

> ⚠️ Úsalo recién después de completar la [PT1](../PT1.md) y la [PT2](../PT2.md), cuando el workflow en IWHI ya esté activo y con los bloques Return configurados.

App web para probar el flujo a mano, transacción por transacción. Te deja poner la URL del webhook, elegir una cuenta real de la base de datos y mandar un monto — y ver en vivo si la transacción fue aprobada o rechazada por el workflow en IWHI.

---

## Levantar el contenedor

El tester se levanta desde la **raíz del proyecto** junto al Postgres:

```bash
# Docker
docker compose up -d

# Podman
podman compose up -d
```

Abre **http://localhost:8080** en el navegador.

---

## Probar transacciones

1. **URL del Webhook** — pega la URL que te entregó IWHI en el Paso 1 de la PT2. Se guarda en el navegador, no hace falta escribirla cada vez.
2. **Cuenta** — clic en "Cargar cuentas" para traer las cuentas reales desde Postgres y elige una de la tabla.
3. **Monto** — escríbelo a mano. Usa un monto menor al saldo para ver un caso aprobado, y uno mayor para ver un caso de sobregiro rechazado.
4. **Enviar transacción** — manda la transacción y observa la notificación de resultado (✅ aprobada / ❌ rechazada). El registro al fondo muestra el detalle técnico de cada llamada.

> El monto se pone siempre a mano — no hay generación aleatoria, para que controles exactamente qué caso estás probando.

---

Una vez que veas las transacciones aprobadas y rechazadas respondiendo correctamente desde IWHI, ¡completaste el bootcamp! 🎉
