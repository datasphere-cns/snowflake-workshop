-- Otorgar acceso a la base de datos
GRANT USAGE ON DATABASE workshop TO ROLE role_Developer;

-- Otorgar acceso al esquema
GRANT USAGE ON SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;

-- Permitir creación de objetos en el esquema
GRANT CREATE TABLE ON SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;
GRANT CREATE VIEW ON SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;
GRANT CREATE MATERIALIZED VIEW ON SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;
GRANT CREATE STREAM ON SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;

-- Permitir acceso automático a objetos futuros
GRANT SELECT, INSERT, UPDATE, DELETE
  ON FUTURE TABLES IN SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;

GRANT SELECT
  ON FUTURE VIEWS IN SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;

GRANT SELECT
  ON FUTURE MATERIALIZED VIEWS IN SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;

GRANT SELECT
  ON FUTURE STREAMS IN SCHEMA workshop.gold_mercadeo TO ROLE role_Developer;
