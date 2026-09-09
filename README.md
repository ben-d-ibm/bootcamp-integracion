# 🏦 Bootcamp Integración — Integración de Aplicaciones en Arquitectura Híbrida

## ¿Qué haremos?

En este hands-on crearemos un Workflow en IWHI que aprueba o rechaza transacciones de envío de dinero desde las cuentas de clientes que tenemos almacenados en una base de datos PostgreSQL que corre de forma local y aislada. La conexión a la base de datos que no está expuesta la haremos mediante el despliegue de un runtime self-managed dentro de la misma red de nuestra base de datos, para luego usarlo en un FlowService que hará la conexión hacia el IWHI SaaS.
