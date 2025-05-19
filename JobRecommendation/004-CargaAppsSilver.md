
# Carga Enriquecida Directa desde Stage Externo en Snowflake

## Objetivo

Usar `INSERT INTO ... SELECT` directamente desde un stage en Amazon S3 para cargar datos en tablas **RAW (zona BRONZE)**, añadiendo columnas de auditoría como:

- `FechaHoraCarga`: timestamp de la carga.
- `ProcesoCarga`: nombre del proceso o pipeline.
- `FuenteArchivo`: nombre del archivo cargado.

---

## Requisitos

- Stage externo creado correctamente (`@job_stage`).
- Archivo `.tsv` disponible en `s3://snow.workshop.jobrecommendation/jobdata/`.
- File format configurado como `job_tsv_format` con separador `\t`.
- Tablas destino creadas con columnas de datos **+** columnas de control.

---

## 1. Tabla `apps_raw`

```sql
CREATE OR REPLACE TABLE apps_raw (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  ApplicationDate TIMESTAMP_NTZ,
  JobID STRING,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);

INSERT INTO apps_raw (
  UserID, WindowID, Split, ApplicationDate, JobID,
  FechaHoraCarga, ProcesoCarga, FuenteArchivo
)
SELECT
  $1::STRING,
  $2::STRING,
  $3::STRING,
  $4::TIMESTAMP_NTZ,
  $5::STRING,
  CURRENT_TIMESTAMP,
  'manual_script',
  METADATA$FILENAME
FROM @job_stage/apps.tsv
(FILE_FORMAT => job_tsv_format);
```

---

## 2. Tabla `users_raw`

```sql
CREATE OR REPLACE TABLE users_raw (
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
  ManagedHowMany NUMBER,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);

INSERT INTO users_raw
SELECT
  $1::NUMBER,
  $2::NUMBER,
  $3::STRING,
  $4::STRING,
  $5::STRING,
  $6::STRING,
  $7::STRING,
  $8::STRING,
  $9::STRING,
  $10::TIMESTAMP_NTZ,
  $11::NUMBER,
  $12::NUMBER,
  $13::STRING,
  $14::STRING,
  $15::NUMBER,
  CURRENT_TIMESTAMP,
  'manual_script',
  METADATA$FILENAME
FROM @job_stage/users.tsv
(FILE_FORMAT => job_tsv_format);
```

---

## 3. Tabla `user_history_raw`

```sql
CREATE OR REPLACE TABLE user_history_raw (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  Sequence STRING,
  JobTitle STRING,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);

INSERT INTO user_history_raw
SELECT
  $1::STRING,
  $2::STRING,
  $3::STRING,
  $4::STRING,
  $5::STRING,
  CURRENT_TIMESTAMP,
  'manual_script',
  METADATA$FILENAME
FROM @job_stage/user_history.tsv
(FILE_FORMAT => job_tsv_format);
```

---

## 4. Tabla `jobs_raw`

```sql
CREATE OR REPLACE TABLE jobs_raw (
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
  EndDate TIMESTAMP_NTZ,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);

INSERT INTO jobs_raw
SELECT
  $1::NUMBER,
  $2::NUMBER,
  $3::STRING,
  $4::STRING,
  $5::STRING,
  $6::STRING,
  $7::STRING,
  $8::STRING,
  $9::STRING,
  $10::TIMESTAMP_NTZ,
  $11::TIMESTAMP_NTZ,
  CURRENT_TIMESTAMP,
  'manual_script',
  METADATA$FILENAME
FROM @job_stage/jobs.tsv
(FILE_FORMAT => job_tsv_format);
```

---

## 5. Tabla `window_dates_raw`

```sql
CREATE OR REPLACE TABLE window_dates_raw (
  Window NUMBER,
  TrainStart TIMESTAMP_NTZ,
  TestStart TIMESTAMP_NTZ,
  TestEnd TIMESTAMP_NTZ,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);

INSERT INTO window_dates_raw
SELECT
  $1::NUMBER,
  $2::TIMESTAMP_NTZ,
  $3::TIMESTAMP_NTZ,
  $4::TIMESTAMP_NTZ,
  CURRENT_TIMESTAMP,
  'manual_script',
  METADATA$FILENAME
FROM @job_stage/window_dates.tsv
(FILE_FORMAT => job_tsv_format);
```

---

## Ventajas de este enfoque

- Puedes enriquecer los datos al momento de la carga.
- Tienes control total sin modificar el archivo de origen.
- Puedes auditar qué archivo cargó cada fila y cuándo.
- Evitas pasos intermedios como staging con `COPY INTO`.

---
