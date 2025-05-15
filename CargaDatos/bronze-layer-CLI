# Guía para Cargar un CSV en Snowflake Usando SnowSQL

**Usuario:** `usuario_developer`  
**Contraseña:** `******`  
**Account:** `kixfvtu-oic64833`  
**Base de datos:** `WORKSHOP`  
**Esquema:** `BRONZE_MERCADEO`  
**Warehouse:** `WH_SMALL`  
**Archivo CSV:** `products.csv`

---

## Requisitos

### 1. Instalar SnowSQL

Puedes descargar el cliente oficial de SnowSQL desde:

[https://docs.snowflake.com/en/user-guide/snowsql-install-config](https://docs.snowflake.com/en/user-guide/snowsql-install-config)

Elige el instalador adecuado para tu sistema operativo (Windows, macOS, Linux).

---

## Credenciales y Acceso

**Comando base para iniciar sesión:**

```bash
snowsql -a kixfvtu-oic64833 -u usuario_developer -p '********'
```

> Esto abre una consola interactiva conectada a tu cuenta.

---

## Subir el archivo CSV al STAGE

Asegúrate de tener el archivo `products.csv` en tu máquina.

Ejecuta este comando (ajustando la ruta del archivo):

```bash
PUT file://C:\Snowflake\CargaDatos\dataset\products.csv @STG_PRODUCTS_DEV auto_compress=false;
```


---

## Script SQL completo

Guarda este archivo como `snowflake_stage_load.sql`:

```sql
-- Paso 1: Selección de entorno
USE ROLE ROLE_DEVELOPER;
USE WAREHOUSE WH_SMALL;
USE DATABASE WORKSHOP;
USE SCHEMA BRONZE_MERCADEO;

-- Paso 2: Crear el STAGE
CREATE OR REPLACE STAGE STG_PRODUCTS_DEV
FILE_FORMAT = (
  TYPE = 'CSV',
  FIELD_OPTIONALLY_ENCLOSED_BY = '"',
  SKIP_HEADER = 1
);

-- Paso 4: Crear la tabla destino
CREATE OR REPLACE TABLE PRODUCTS_BRONZE (
  product_id INTEGER,
  product_name STRING,
  category STRING,
  price FLOAT
);

-- Paso 5: Cargar datos desde el STAGE
COPY INTO PRODUCTS_BRONZE
FROM @STG_PRODUCTS_DEV/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';

-- Paso 6: Verificar los datos
SELECT * FROM PRODUCTS_BRONZE;

-- Paso 7: (Opcional) Limpiar el STAGE
-- REMOVE @STG_PRODUCTS_DEV;
```

---

## Ejecutar el script

Puedes correr el script SQL directamente así:

```bash
snowsql -a kixfvtu-oic64833 -u usuario_developer -p '********' -f snowflake_stage_load.sql
```

---

¿Dudas? Verifica cada paso con:

```sql
SHOW STAGES;
SHOW TABLES;
SELECT * FROM PRODUCTS_BRONZE;
```
