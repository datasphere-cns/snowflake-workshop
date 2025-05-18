
# Workshop de Snowflake - Ejercicio de Carga de Datos desde S3

## Introducción

Este ejercicio forma parte del **Workshop de Snowflake** orientado a ingenieros de datos, analistas y científicos que necesitan familiarizarse con la carga de archivos masivos desde fuentes externas hacia Snowflake, utilizando prácticas recomendadas en ambientes productivos.

Trabajaremos con un conjunto de archivos reales del reto de Kaggle: [**Job Recommendation Engine Challenge**](https://www.kaggle.com/competitions/job-recommendation/overview), organizado por CareerBuilder. Aunque la competencia está orientada a sistemas de recomendación, nuestro enfoque será netamente de **ingeniería de datos**: organizar, cargar, validar y consultar datos desde un bucket de S3 hacia Snowflake.

## Archivos del Dataset

Trabajaremos con cinco archivos `.tsv` (tabulador como separador). Cada uno representa una entidad clave del sistema:

| Archivo | Contenido |
|--------|-----------|
| `apps.tsv` | Postulaciones de usuarios a empleos. Incluye fechas, IDs y ventanas. |
| `users.tsv` | Información demográfica y profesional de usuarios. |
| `user_history.tsv` | Historial de trabajos anteriores por usuario, con secuencia cronológica. |
| `jobs.tsv` | Publicaciones de empleo con fechas de vigencia. |
| `window_dates.tsv` | Fechas de inicio y fin de los períodos de entrenamiento y prueba. |

## Objetivo del Ejercicio

Realizar un flujo completo de carga de datos a Snowflake que incluya:

- Definición de formatos de archivo (`FILE FORMAT`).
- Creación de un `STAGE` externo apuntando a S3.
- Creación de tablas en el esquema `BRONZE_RECURSOS_HUMANOS` dentro de la base `workshop`.
- Carga de archivos con el comando `COPY INTO`.
- Validaciones posteriores con SQL.

## Teoría Clave

### ¿Qué es un STAGE en Snowflake?

Un **stage** es un área temporal o permanente que sirve como punto de entrada para cargar o descargar archivos desde Snowflake. Puede ser:

- **Interno**: dentro del propio Snowflake.
- **Externo**: en un servicio como Amazon S3, Azure Blob Storage o Google Cloud Storage.

### ¿Qué es un STAGE EXTERNO?

Un **stage externo** apunta a un bucket o contenedor de almacenamiento fuera de Snowflake. Se configura con:

- La URL del bucket.
- Un `FILE FORMAT` asociado.
- Opcionalmente, credenciales de acceso (access key y secret key si no se usa `STORAGE INTEGRATION`).

### ¿Qué es el comando COPY INTO?

`COPY INTO` permite copiar datos desde archivos en un stage hacia una tabla de Snowflake. Es el método más usado para cargas masivas. Admite opciones como:

- Validación de tipos de datos.
- Manejo de errores.
- Carga incremental o completa.

## Instrucciones Técnicas

### 1. Establecer base de datos y esquema

```sql
USE DATABASE workshop;
USE SCHEMA BRONZE_RECURSOS_HUMANOS;
```

### 2. Crear un FILE FORMAT para archivos TSV

```sql
CREATE OR REPLACE FILE FORMAT job_tsv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = '\t'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL')
  TIMESTAMP_FORMAT = 'AUTO';
```

### 3. Crear el STAGE externo hacia S3

Utilizaremos el bucket `snow.workshop.jobrecommendation` en la región `us-east-1`.

```sql
CREATE OR REPLACE STAGE job_stage
  URL = 's3://snow.workshop.jobrecommendation/'
  CREDENTIALS = (
    AWS_KEY_ID = 'TU_AWS_KEY_ID'
    AWS_SECRET_KEY = 'TU_AWS_SECRET_KEY'
  )
  FILE_FORMAT = job_tsv_format;
```

> Importante: Sustituye `TU_AWS_KEY_ID` y `TU_AWS_SECRET_KEY` con las credenciales proporcionadas para el workshop.

### 4. Crear las tablas destino

```sql
CREATE OR REPLACE TABLE apps (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  ApplicationDate TIMESTAMP,
  JobID STRING
);

CREATE OR REPLACE TABLE users (
  UserID NUMBER,
  WindowID NUMBER,
  Split STRING,
  City STRING,
  State STRING,
  Country STRING,
  ZipCode STRING,
  DegreeType STRING,
  Major STRING,
  GraduationDate TIMESTAMP_NTZ,
  WorkHistoryCount NUMBER,
  TotalYearsExperience NUMBER,
  CurrentlyEmployed STRING,
  ManagedOthers STRING,
  ManagedHowMany NUMBER
);


CREATE OR REPLACE TABLE user_history (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  Sequence STRING,
  JobTitle STRING
);

CREATE OR REPLACE TABLE jobs (
  JobID NUMBER,
  WindowID NUMBER,
  Title STRING,
  Description STRING,
  Requirements STRING,
  City STRING,
  State STRING,
  Country STRING,
  Zip5 STRING,
  StartDate TIMESTAMP_NTZ,
  EndDate TIMESTAMP_NTZ
);


CREATE OR REPLACE TABLE window_dates (
  Window STRING,
  TrainStart TIMESTAMP,
  TrainEnd TIMESTAMP,
  TestStart TIMESTAMP,
  TestEnd TIMESTAMP
);
```

### 5. Ejecutar los comandos COPY INTO

```sql
COPY INTO apps
  FROM @job_stage/apps.tsv;

COPY INTO users
  FROM @job_stage/users.tsv;

COPY INTO user_history
  FROM @job_stage/user_history.tsv;

COPY INTO jobs
  FROM @job_stage/jobs.tsv;

COPY INTO window_dates
  FROM @job_stage/window_dates.tsv;
```

### 6. Consultas de Validación

```sql
-- Usuarios únicos por ventana
SELECT WindowID, COUNT(DISTINCT UserID)
FROM users
GROUP BY WindowID;

-- Fechas clave por ventana
SELECT * FROM window_dates
ORDER BY Window;

-- Historial laboral de un usuario
SELECT * FROM user_history
WHERE UserID = 47
ORDER BY Sequence;

-- Aplicaciones fuera del período de visibilidad
SELECT a.UserID, a.ApplicationDate, j.StartDate, j.EndDate
FROM apps a
JOIN jobs j ON a.JobID = j.JobID
WHERE a.ApplicationDate < j.StartDate OR a.ApplicationDate > j.EndDate;
```

## Consideraciones Finales

- Este ejercicio simula una situación real de integración de datos entre un sistema de almacenamiento externo (S3) y una plataforma analítica (Snowflake).
- La separación en etapas permite reutilizar el mismo flujo en otros proyectos, datasets o ambientes.
- Posteriormente, estos datos pueden ser refinados en esquemas *silver* y *gold* para análisis avanzados, visualización o ciencia de datos.
