
# Carga masiva de reseñas de Google Local (California) desde JSONL a Snowflake

Este ejercicio forma parte del Workshop de Snowflake para demostrar cómo cargar datos semiestructurados (JSON por línea) desde S3 hacia una tabla en la zona BRONZE.

---

## Dataset original

Los datos provienen de la colección pública de reseñas de Google Local recopiladas por el McAuley Lab, UC San Diego:

- Fuente oficial: https://mcauleylab.ucsd.edu/public_datasets/gdrive/googlelocal/#complete-data
- Archivo específico: `review-California_10.json`
- Número total de reseñas en California: **70,529,977**
- Formato: **JSONL** (una reseña por línea)

---

## Almacenamiento en S3

El archivo ha sido subido al siguiente bucket de S3:

- Bucket: `snow.workshop.198303`
- Carpeta: `reviews/`
- Ruta completa: `s3://snow.workshop.198303/reviews/review-California_10.json`

---

## Destino en Snowflake

Los datos se cargarán en:

- **Base de datos**: `workshop`
- **Esquema**: `bronze_mercadeo`
- **Tabla destino**: `review`

---

## 1. Crear STORAGE INTEGRATION (con claves AWS)

> Ejecutar como `ACCOUNTADMIN` o con privilegios para crear integraciones externas.

```sql
CREATE OR REPLACE STORAGE INTEGRATION integration_s3_workshop
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<NO USAR PARA ACCESS_KEY>'
  STORAGE_ALLOWED_LOCATIONS = ('s3://snow.workshop.198303/reviews/')
  STORAGE_AWS_ACCESS_KEY = '<YOUR_AWS_ACCESS_KEY>'
  STORAGE_AWS_SECRET_KEY = '<YOUR_AWS_SECRET_KEY>';
```

>  **IMPORTANTE:** Reemplaza `YOUR_AWS_ACCESS_KEY` y `YOUR_AWS_SECRET_KEY` con tus credenciales IAM válidas con permisos `s3:GetObject` sobre el bucket.

---

## 2. Crear el STAGE externo para S3

```sql
CREATE OR REPLACE STAGE stage_reviews_json
  URL = 's3://snow.workshop.198303/reviews'
  STORAGE_INTEGRATION = integration_s3_workshop
  FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = FALSE);
```

---

## 3. Crear la tabla de destino (VARIANT)

```sql
CREATE OR REPLACE TABLE workshop.bronze_mercadeo.reviews_raw (
  review VARIANT
);
```

---

## 4. Ejecutar el COPY INTO

```sql
COPY INTO workshop.bronze_mercadeo.reviews_raw
FROM @stage_reviews_json/review-California_10.json
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = FALSE)
ON_ERROR = 'CONTINUE';
```

---

## 5. Validar registros cargados

```sql
SELECT COUNT(*) FROM workshop.bronze_mercadeo.reviews_raw;

SELECT
  review:user_id::STRING AS user_id,
  review:name::STRING AS name,
  TO_TIMESTAMP_LTZ(review:time::NUMBER / 1000) AS timestamp,
  review:rating::NUMBER AS rating,
  review:text::STRING AS text,
  review:resp.text::STRING AS response
FROM workshop.bronze_mercadeo.reviews_raw
LIMIT 10;
```

---

## Recomendaciones

- Usa `VARIANT` para ingestión inicial; transforma después con `CREATE TABLE AS SELECT` si lo necesitas tabular.
- Si los archivos son muy grandes, particiónalos por tamaño (~1 GB cada uno) y nómbralos de forma secuencial.
- Revisa errores con `VALIDATION_MODE = RETURN_ERRORS`.
- Automatiza usando Snowpipe si esperas archivos recurrentes.
