# Guía: Cargar un archivo CSV desde Amazon S3 a Snowflake

Esta guía describe cómo cargar un archivo `orders.csv` desde un bucket de Amazon S3 hacia una tabla en Snowflake, utilizando un `STAGE` externo.

## 1. Información del archivo

- S3 URI: `s3://snow.workshop.198303/orders.csv`
- Región: `us-east-1`
- Nombre del archivo: `orders.csv`
- Tamaño: 103.9 MB

## 2. Requisitos

Antes de comenzar, asegúrate de tener:

- Una cuenta activa en Snowflake
- Un usuario con permisos para crear stages y tablas
- Credenciales de AWS IAM con permisos `s3:GetObject`
- Acceso al bucket de S3 `snow.workshop.198303`

## 3. Crear el STAGE externo (sin integración)

Si no estás usando una `STORAGE INTEGRATION`, puedes usar credenciales directas:

```sql
CREATE OR REPLACE STAGE STG_ORDERS_S3
URL = 's3://snow.workshop.198303/'
CREDENTIALS = (
  AWS_KEY_ID = '<your-access-key-id>',
  AWS_SECRET_KEY = '<your-secret-access-key>'
)
FILE_FORMAT = (
  TYPE = 'CSV',
  FIELD_OPTIONALLY_ENCLOSED_BY = '"',
  SKIP_HEADER = 1
);
```

Reemplaza `<your-access-key-id>` y `<your-secret-access-key>` por tus credenciales reales de AWS.

## 4. Crear la tabla destino en Snowflake

```sql
CREATE OR REPLACE TABLE ORDERS_BRONZE (
  order_id INTEGER,
  product_id INTEGER,
  user_id INTEGER,
  order_number INTEGER,
  order_dow INTEGER,
  order_hour_of_day INTEGER,
  days_since_prior_order FLOAT
);
```

## 5. Cargar los datos desde el STAGE

```sql
COPY INTO ORDERS_BRONZE
FROM @STG_ORDERS_S3/orders.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';
```

## 6. Validar la carga

```sql
SELECT * FROM ORDERS_BRONZE LIMIT 10;
```

## 7. Ver archivos disponibles en el STAGE (opcional)

```sql
LIST @STG_ORDERS_S3;
```

## Nota adicional

Si cuentas con una `STORAGE INTEGRATION`, puedes definir el STAGE así:

```sql
CREATE OR REPLACE STAGE STG_ORDERS_S3
URL = 's3://snow.workshop.198303/'
STORAGE_INTEGRATION = my_s3_integration
FILE_FORMAT = (
  TYPE = 'CSV',
  FIELD_OPTIONALLY_ENCLOSED_BY = '"',
  SKIP_HEADER = 1
);
```

En ese caso, asegúrate de que la integración esté configurada y autorizada en el bucket de S3.
