# Optimización de la Tabla `reviews_silver` en Snowflake

Este documento describe siete estrategias clave para optimizar el rendimiento, la eficiencia de almacenamiento y el costo asociado a la tabla `workshop.silver_mercadeo.reviews_silver` en Snowflake. Cada recomendación incluye el fundamento conceptual y su implementación práctica en SQL.

---

## 1. Clustering Manual con `CLUSTER BY`

### Concepto
Snowflake organiza los datos automáticamente en **microparticiones**. Sin embargo, cuando las consultas filtran repetidamente por ciertas columnas (como fechas), puedes ayudar a Snowflake a optimizar el acceso usando `CLUSTER BY`.

Esto **no crea un índice** como en otros motores, pero permite que Snowflake almacene físicamente los datos de forma más ordenada, mejorando los tiempos de escaneo.

### Cuándo usarlo
- Si realizas muchas consultas filtrando por `timestamp`.
- Si haces agregaciones por `rating`, `user_id`, u otras claves.

### Ejemplo

```sql
ALTER TABLE workshop.silver_mercadeo.reviews_silver 
CLUSTER BY (timestamp, rating);
```

> El clustering es reorganizado automáticamente por Snowflake, pero consume créditos cuando se ejecuta. Es importante monitorear el beneficio obtenido en relación con el costo.

---

## 2. Uso de Tipos de Datos Nativos

### Concepto
Snowflake permite trabajar con datos semiestructurados usando el tipo `VARIANT`, ideal para ingestas desde JSON o APIs. Sin embargo, en la capa **Silver**, donde los datos ya fueron transformados, es mejor utilizar tipos nativos (`STRING`, `NUMBER`, `TIMESTAMP`).

### Beneficios
- Mejora el rendimiento de las consultas.
- Reduce el tamaño en almacenamiento (mejor compresión).
- Aumenta la compatibilidad con funciones SQL estándar.

### Qué hacer
Verifica que la tabla `reviews_silver` utilice columnas ya normalizadas, como:

```sql
CREATE TABLE workshop.silver_mercadeo.reviews_silver (
  user_id STRING,
  name STRING,
  timestamp TIMESTAMP_LTZ,
  rating NUMBER,
  text STRING,
  response STRING
);
```

> Si aún estás usando `VARIANT`, realiza una transformación con `SELECT INTO` o `CREATE TABLE AS SELECT`.

---

## 3. Creación de `STREAM` para Procesamiento Incremental

### Concepto
Un `STREAM` es un objeto de Snowflake que permite rastrear cambios (inserciones, actualizaciones, eliminaciones) en una tabla sin necesidad de comparar manualmente.

### Usos comunes
- En pipelines donde necesitas procesar solo los registros nuevos.
- En sincronizaciones entre capas (Silver → Gold).

### Ejemplo

```sql
CREATE OR REPLACE STREAM reviews_silver_stream 
ON TABLE workshop.silver_mercadeo.reviews_silver;
```

Consulta básica:

```sql
SELECT * 
FROM reviews_silver_stream 
WHERE METADATA$ACTION = 'INSERT';
```

> Ideal para tareas programadas o procesos ELT incrementales sin escanear la tabla completa.

---

## 4. Optimización de Consultas Frecuentes

### Concepto
Cuando las consultas se repiten sobre los mismos datos con patrones similares (por ejemplo, agregaciones por día, filtros por puntaje, etc.), es más eficiente precalcular esos resultados o reutilizar respuestas almacenadas.

### Estrategias

#### a. Materialized Views (Vistas Materializadas)

Permiten almacenar el resultado de una consulta como un objeto persistente que Snowflake actualiza automáticamente.

```sql
CREATE OR REPLACE MATERIALIZED VIEW reviews_summary_by_day AS
SELECT
  DATE_TRUNC('DAY', timestamp) AS review_date,
  COUNT(*) AS total_reviews,
  AVG(rating) AS avg_rating
FROM workshop.silver_mercadeo.reviews_silver
GROUP BY review_date;
```

Consulta optimizada:

```sql
SELECT * FROM reviews_summary_by_day
WHERE review_date >= CURRENT_DATE - 30;
```

#### b. Tablas de Agregaciones Precalculadas

Puedes almacenar resultados de agregaciones comunes en una tabla para acelerar dashboards.

```sql
CREATE OR REPLACE TABLE reviews_agg_by_user AS
SELECT
  user_id,
  COUNT(*) AS num_reviews,
  AVG(rating) AS avg_rating
FROM workshop.silver_mercadeo.reviews_silver
GROUP BY user_id;
```

#### c. Uso del Result Cache

Snowflake guarda en caché el resultado de una consulta si:
- No ha cambiado el underlying data.
- El usuario, warehouse y consulta son idénticos.

```sql
-- Primera ejecución
SELECT * FROM reviews_silver WHERE rating = 5;

-- Segunda ejecución (Snowflake la sirve desde cache)
SELECT * FROM reviews_silver WHERE rating = 5;
```

> No hay ningún costo por usar el result cache, pero hay que entender sus condiciones de validez.

---

## 5. Control de Duplicados

### Concepto
Snowflake no aplica restricciones de unicidad por defecto. En modelos donde `user_id` y `timestamp` deberían identificar unívocamente una fila, es recomendable aplicar una deduplicación explícita.

### Ejemplo con `ROW_NUMBER()`

```sql
CREATE OR REPLACE TABLE reviews_silver_dedup AS
SELECT *
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id, timestamp ORDER BY rating DESC) AS rn
  FROM workshop.silver_mercadeo.reviews_silver
)
WHERE rn = 1;
```

> Esto conserva solo una fila por combinación `user_id + timestamp`, tomando el de mayor `rating`.

---

## 6. Configuración Eficiente del Warehouse

### Concepto
El warehouse en Snowflake es la unidad de cómputo. Ajustar correctamente su tamaño y suspensión automática es clave para evitar gastos innecesarios.

### Configuración recomendada para procesamiento ligero:

```sql
CREATE OR REPLACE WAREHOUSE WH_SMALL
WITH WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
```

### Buenas prácticas
- Usa `AUTO_SUSPEND` bajo (30 o 60 segundos).
- Elige el tamaño adecuado según volumen.
- Evita mantener warehouses corriendo sin actividad.

---

## 7. Monitoreo y Métricas con `TABLE_STORAGE_METRICS`

### Concepto
Snowflake provee una vista con métricas de almacenamiento que permite auditar:
- Uso físico vs lógico.
- Cantidad de microparticiones.
- Necesidad de re-clustering.

### Consulta:

```sql
SELECT * 
FROM INFORMATION_SCHEMA.TABLE_STORAGE_METRICS
WHERE TABLE_NAME = 'REVIEWS_SILVER';
```

### Columnas clave:
- `TABLE_BYTES`: espacio usado.
- `ACTIVE_BYTES`: espacio útil actual.
- `TABLE_MICROPARTITION_COUNT`: cantidad de particiones (impacta performance).

> Si la cantidad de particiones es muy alta y las consultas no mejoran, considera revisar tu estrategia de clustering.

---

## Conclusión

La optimización de una tabla en Snowflake no se basa en índices ni particiones manuales, sino en prácticas inteligentes como el uso de tipos nativos, vistas materializadas, cachés de resultados, y estrategias de clustering. Aplicar estas recomendaciones a `reviews_silver` permite mantener un entorno eficiente, escalable y alineado con las mejores prácticas para analítica avanzada.
