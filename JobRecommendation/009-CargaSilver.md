# Carga Incremental de Reviews: Bronze a Silver en Snowflake

Este documento describe el proceso de implementación de una carga incremental desde la tabla `reviews_raw` en la capa Bronze hacia la tabla `reviews_silver` en la capa Silver. El procedimiento se ejecuta automáticamente todos los días a las 6:00 a.m. hora de El Salvador mediante una tarea programada en Snowflake.

SHOW PARAMETERS LIKE 'TIMEZONE';
ALTER SESSION SET TIMEZONE = 'America/El_Salvador';


## Código completo

```sql
-- 1. Crear tabla en la capa Silver
CREATE TABLE IF NOT EXISTS workshop.silver_mercadeo.reviews_silver (
  user_id STRING,
  name STRING,
  timestamp TIMESTAMP_LTZ,
  rating NUMBER,
  text STRING,
  response STRING
);

-- 2. Crear procedimiento almacenado para carga incremental
CREATE OR REPLACE PROCEDURE workshop.silver_mercadeo.load_reviews_incremental()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  last_ts TIMESTAMP_LTZ;
BEGIN
  -- Obtener el último timestamp cargado
  SELECT COALESCE(MAX(timestamp), '1900-01-01 00:00:00'::TIMESTAMP_LTZ)
  INTO last_ts
  FROM workshop.silver_mercadeo.reviews_silver;

  -- Insertar solo los nuevos registros desde Bronze
  INSERT INTO workshop.silver_mercadeo.reviews_silver (
    user_id, name, timestamp, rating, text, response
  )
  SELECT
    review:user_id::STRING,
    review:name::STRING,
    TO_TIMESTAMP_LTZ(review:time::NUMBER / 1000),
    review:rating::NUMBER,
    review:text::STRING,
    review:resp.text::STRING
  FROM workshop.bronze_mercadeo.reviews_raw
  WHERE TO_TIMESTAMP_LTZ(review:time::NUMBER / 1000) > :last_ts;

  RETURN 'Carga completada desde timestamp = ' || last_ts;
END;
$$;

-- 3. Crear tarea programada diaria a las 6:00 a.m. hora de El Salvador
USE ROLE role_developer;

CREATE OR REPLACE TASK workshop.silver_mercadeo.task_load_reviews_daily
  WAREHOUSE = WH_SMALL
  SCHEDULE = 'USING CRON 0 6 * * * America/El_Salvador'
  COMMENT = 'Carga diaria incremental desde Bronze a Silver'
AS
  CALL workshop.silver_mercadeo.load_reviews_incremental();

-- 4. Activar la tarea
ALTER TASK workshop.silver_mercadeo.task_load_reviews_daily RESUME;

-- 5. Ejecución manual de la tarea (opcional)
EXECUTE TASK workshop.silver_mercadeo.task_load_reviews_daily;
