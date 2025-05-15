# Guía para Cargar un Archivo CSV a la Capa Bronze en Snowflake usando GUI

**Autor:** Nelson Zepeda  
**Fecha:** 2025-05-15  
**Tema:** Carga de Datos desde un CSV hacia la Capa Bronze de Mercadeo usando Stages en Snowflake

### Un Stage es tu buffer seguro, escalable y controlado entre el mundo externo (archivos CSV, JSON, Parquet) y tus tablas en Snowflake.


## Beneficios de usar un Stage en Snowflake
1. Desacopla la carga física del procesamiento
Un Stage permite subir archivos una sola vez y reutilizarlos en múltiples procesos de carga. Esto evita depender de tu máquina local o volver a subir el mismo archivo cada vez. Por ejemplo, puedes subir un archivo CSV y probar distintas estructuras de tabla sin tener que volver a cargar el archivo.

2. Cargas más rápidas y paralelizadas
Snowflake puede leer archivos desde el Stage en paralelo, lo que mejora significativamente el rendimiento en cargas masivas. Esto es especialmente útil cuando trabajas con archivos comprimidos o grandes volúmenes de datos.

3. Soporte para grandes volúmenes
Los Stages están diseñados para manejar archivos de gran tamaño, incluso en el orden de gigabytes o terabytes. Esto los hace ideales para procesos ETL/ELT que involucran grandes lotes de datos.

4. Auditoría y visibilidad
Puedes listar el contenido del Stage (LIST @stage_name) y verificar qué archivos están disponibles. Además, puedes validar qué datos se han cargado correctamente utilizando opciones como VALIDATION_MODE, lo que facilita el monitoreo y la trazabilidad.

5. Reutilización y control de errores
Un archivo subido al Stage puede utilizarse múltiples veces. También puedes usar configuraciones como ON_ERROR, SKIP_HEADER, FIELD_OPTIONALLY_ENCLOSED_BY, entre otros, para definir un comportamiento detallado ante errores de formato o contenido, brindando control granular sobre las cargas.

6. Facilita pruebas y desarrollo
Al permitir trabajar con los mismos archivos en diferentes entornos (desarrollo, pruebas, producción), los Stages ayudan a estandarizar procesos y a simular cargas sin depender de la fuente original. Esto es útil para diseñar y validar transformaciones antes de implementarlas en producción.

7. Mayor seguridad y cumplimiento
Usar Stages permite controlar estrictamente quién puede subir, ver o cargar archivos. Se integra con el modelo de roles y políticas de seguridad de Snowflake, evitando accesos no deseados o errores por manipulación directa desde archivos locales.

8. Compatible con pipelines modernos
Los Stages funcionan bien con herramientas de orquestación como Apache Airflow, dbt, y CI/CD pipelines, lo cual permite automatizar y mantener procesos de carga eficientes y trazables.


---

## Objetivo

Aprender a cargar un archivo CSV (`products.csv`) desde tu computadora hacia una tabla en Snowflake ubicada en el esquema `WORKSHOP.BRONZE_MERCADEO`, utilizando un Stage como punto intermedio. Esta guía está diseñada para quienes están empezando con Snowflake y quieren entender todos los pasos con claridad.

---

## ¿Qué es un Stage en Snowflake?

Un **Stage** en Snowflake es un área de almacenamiento temporal o permanente que te permite **subir archivos desde tu computadora o desde un bucket en la nube** y luego cargarlos a tablas. Funciona como una **“sala de espera”** para los archivos que luego serán procesados por Snowflake.

Existen tres tipos principales de stages:

- **Stage Interno**: Reside dentro de Snowflake.
- **Stage Externo**: Apunta a Amazon S3, Azure Blob Storage, etc.
- **Stage Temporal**: Solo existe durante la sesión actual.

En esta guía crearemos un **Stage interno persistente**.

---

## Requisitos Previos

- Rol: `ROLE_ADMIN_FULL` o `ROLE_DEVELOPER`
- Warehouse disponible: `WH_SMALL`
- Base de datos y esquema ya creados: `WORKSHOP.BRONZE_MERCADEO`
- Archivo CSV: `products.csv`

---

## Paso 1: Seleccionar el warehouse, base y esquema

```sql
USE ROLE ROLE_ADMIN_FULL;
USE WAREHOUSE WH_SMALL;
USE SCHEMA WORKSHOP.BRONZE_MERCADEO;
```

---

## Paso 2: Entrar con el usuario Developer y Crear el `STAGE` para subir el CSV

```sql


CREATE OR REPLACE STAGE STG_PRODUCTS_DEV
FILE_FORMAT = (
  TYPE = 'CSV',
  FIELD_OPTIONALLY_ENCLOSED_BY = '"',
  SKIP_HEADER = 1
);


```

Esto crea un contenedor en el esquema actual donde subiremos el archivo. La opción `SKIP_HEADER = 1` indica que la primera fila del archivo contiene los nombres de las columnas y debe ser ignorada al cargar los datos.

---

## Paso 3: Subir el archivo `products.csv` al `STAGE`


1. Ve a la sección "Data" en la interfaz.
2. Navega al esquema `WORKSHOP.BRONZE_MERCADEO`.
3. Ve a "Stages", selecciona `STG_PRODUCTS_DEV`.
4. Haz clic en **"Upload"** y selecciona tu archivo `products.csv`.


---

## Paso 4: Crear la tabla destino

Con base en el archivo `products.csv` que contiene:

```csv
product_id,product_name,category,price
1,Laptop,Electronics,799.99
2,Smartphone,Electronics,599.99
3,Desk,Furniture,120.00
```

Creamos la tabla:

```sql
CREATE OR REPLACE TABLE PRODUCTS_BRONZE (
  product_id INTEGER,
  product_name STRING,
  category STRING,
  price FLOAT
);
```

---

## Paso 5: Cargar los datos desde el Stage

```sql
COPY INTO PRODUCTS_BRONZE
FROM @STG_PRODUCTS_DEV/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';
```

La opción `ON_ERROR = 'CONTINUE'` hace que Snowflake continúe con la carga si encuentra errores en alguna fila.

---

## Paso 6: Verificar los datos

```sql
SELECT * FROM PRODUCTS_BRONZE;
```

---

## Paso 7: (Opcional) Limpiar el Stage

```sql
REMOVE @STG_PRODUCTS_DEV;
```

Esto borra los archivos subidos al stage si ya no los necesitas.

---

## Conclusión

Has aprendido cómo:

- Usar un **STAGE** en Snowflake.
- Subir un archivo CSV desde tu máquina local.
- Crear una tabla en la capa `BRONZE_MERCADEO`.
- Ejecutar `COPY INTO` para cargar datos.
- Validar y depurar resultados.

No usar Stages es posible, pero te limita en trazabilidad, control, eficiencia y escalabilidad.
Usarlos es una buena práctica recomendada

---

¿Dudas o sugerencias?  
Contacta con el autor: [nelson.zepeda@datasphere.tech](mailto:nelson.zepeda@datasphere.tech)

