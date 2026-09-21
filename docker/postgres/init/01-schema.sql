-- docker/postgres/init/01-schema.sql
-- Runs ONCE on first container start (when the data volume is empty).

CREATE SCHEMA IF NOT EXISTS shopease;

CREATE TABLE IF NOT EXISTS shopease.customers (
    customer_id  BIGSERIAL PRIMARY KEY,
    email        TEXT NOT NULL UNIQUE,
    full_name    TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shopease.orders (
    order_id     BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES shopease.customers(customer_id),
    status       TEXT NOT NULL DEFAULT 'pending',
    total_cents  INTEGER NOT NULL CHECK (total_cents >= 0),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON shopease.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at  ON shopease.orders(created_at);