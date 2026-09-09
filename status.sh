#!/bin/bash
# =============================================================
#  Bootcamp Integración — Estado del ambiente
#  Uso: ./status.sh
# =============================================================

VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NEGRITA='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${NEGRITA}${AZUL}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${NEGRITA}${AZUL}║     Bootcamp Integración — Estado del ambiente       ║${RESET}"
echo -e "${NEGRITA}${AZUL}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Detectar docker o podman ──────────────────────────────────
if command -v podman &>/dev/null; then
  CMD="podman"
elif command -v docker &>/dev/null; then
  CMD="docker"
else
  echo -e "${ROJO}✗ No se encontró docker ni podman instalado.${RESET}"
  exit 1
fi

# ── Estado del contenedor PostgreSQL ─────────────────────────
echo -e "${NEGRITA}▸ PostgreSQL${RESET}"
STATUS=$($CMD inspect bootcamp_postgres --format '{{.State.Status}}' 2>/dev/null)
HEALTH=$($CMD inspect bootcamp_postgres --format '{{.State.Health.Status}}' 2>/dev/null)

if [ "$STATUS" = "running" ] && [ "$HEALTH" = "healthy" ]; then
  echo -e "  Estado:     ${VERDE}● running (healthy)${RESET}"
else
  echo -e "  Estado:     ${ROJO}✗ $STATUS / $HEALTH${RESET}"
fi

PG_VERSION=$($CMD exec bootcamp_postgres postgres --version 2>/dev/null)
echo -e "  Versión:    ${PG_VERSION}"
echo -e "  Host:       ${NEGRITA}localhost${RESET}"
echo -e "  Puerto:     ${NEGRITA}5432${RESET}"
echo -e "  Base datos: ${NEGRITA}bootcamp_db${RESET}"
echo -e "  Usuario:    ${NEGRITA}bootcamp_user${RESET}"
echo -e "  Password:   ${NEGRITA}bootcamp_pass${RESET}"
echo -e "  Conn string:${AMARILLO} postgresql://bootcamp_user:bootcamp_pass@localhost:5432/bootcamp_db${RESET}"
echo ""

# ── Datos cargados ────────────────────────────────────────────
echo -e "${NEGRITA}▸ Datos en la base de datos${RESET}"
TOTAL=$($CMD exec bootcamp_postgres psql -U bootcamp_user -d bootcamp_db -t -c "SELECT COUNT(*) FROM clientes;" 2>/dev/null | tr -d ' ')
if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
  echo -e "  Tabla clientes: ${VERDE}${TOTAL} registros cargados ✓${RESET}"
else
  echo -e "  Tabla clientes: ${ROJO}✗ Sin datos — revisar inicialización${RESET}"
fi

echo ""
$CMD exec bootcamp_postgres psql -U bootcamp_user -d bootcamp_db -c \
  "SELECT tipo_cuenta, COUNT(*) AS clientes, ROUND(AVG(saldo),2) AS saldo_promedio FROM clientes GROUP BY tipo_cuenta ORDER BY tipo_cuenta;" \
  2>/dev/null
echo ""

# ── Red Docker ────────────────────────────────────────────────
echo -e "${NEGRITA}▸ Red${RESET}"
NETWORK=$($CMD inspect bootcamp_postgres --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null)
if [ "$NETWORK" = "bootcamp_net" ]; then
  echo -e "  Red:        ${VERDE}bootcamp_net ✓${RESET}"
else
  echo -e "  Red:        ${ROJO}✗ Red inesperada: $NETWORK${RESET}"
fi
echo ""

# ── Instrucciones IWHI Runtime ────────────────────────────────
echo -e "${NEGRITA}▸ Siguiente paso — Instalar IWHI Edge Runtime${RESET}"
echo -e "  Genera el runtime en IWHI y ejecuta:"
echo ""
echo -e "${AMARILLO}  podman run \\
    --network bootcamp_net \\
    -p 5555:5555 \\
    -p 4430:443 \\
    -d \\
    --platform linux/amd64 \\
    -e SAG_IS_CLOUD_REGISTER_URL=<URL-de-tu-tenant> \\
    -e SAG_IS_EDGE_CLOUD_ALIAS=<alias-del-runtime> \\
    -e SAG_IS_CLOUD_REGISTER_TOKEN=<token> \\
    -e METERING_TOKEN=<metering-token> \\
    --name=<nombre-del-runtime> \\
    iwhicr.azurecr.io/webmethods-edge-runtime:12.0.4.0${RESET}"
echo ""
echo -e "  Conéctate a Postgres desde el FlowService con host: ${NEGRITA}postgres${RESET}"
echo ""
echo -e "${NEGRITA}${AZUL}══════════════════════════════════════════════════════${RESET}"
echo ""
