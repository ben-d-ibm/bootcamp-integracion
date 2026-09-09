-- =============================================================
--  Bootcamp Integración — Schema inicial
-- =============================================================

CREATE TABLE IF NOT EXISTS clientes (
    id              SERIAL          PRIMARY KEY,
    numero_cuenta   VARCHAR(30)     NOT NULL UNIQUE,
    nombre          VARCHAR(100)    NOT NULL,
    apellido        VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    fecha_nacimiento DATE,
    tipo_cuenta     VARCHAR(20)     NOT NULL CHECK (tipo_cuenta IN ('CORRIENTE','AHORRO','NOMINA')),
    saldo           NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    fecha_alta      TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clientes_email       ON clientes (email);
CREATE INDEX idx_clientes_tipo_cuenta ON clientes (tipo_cuenta);
