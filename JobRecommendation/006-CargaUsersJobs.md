
# Automatización de carga BRONZE → SILVER con Snowpipe + Task + Logs (USERS y JOBS)

Ahora conéctate con el rol `usuario_developer`. Este flujo implementa la carga continua y controlada de archivos desde S3 usando Snowpipe, con trazabilidad y separación entre zonas BRONZE y SILVER.

---

## USERS

### 1. Estructura de tablas y esquemas

**Tabla de staging (`users_stage`) en zona BRONZE**

```sql
CREATE OR REPLACE TABLE workshop.bronze_recursos_humanos.users_stage (
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
```

**Tabla enriquecida (`users_silver`) en zona SILVER**

```sql
CREATE OR REPLACE TABLE workshop.silver_recursos_humanos.users_silver (
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
```

**Tabla de logs (compartida)**

```sql
CREATE OR REPLACE TABLE workshop.bronze_recursos_humanos.carga_logs (
  TablaDestino STRING,
  Archivo STRING,
  FechaCarga TIMESTAMP_NTZ,
  RegistrosCargados NUMBER,
  Proceso STRING,
  Observaciones STRING
);
```

---

### 2. Crear Snowpipe para carga automática

```sql
CREATE OR REPLACE PIPE workshop.bronze_recursos_humanos.users_pipe AUTO_INGEST = TRUE
AS
COPY INTO workshop.bronze_recursos_humanos.users_stage
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

---

### 3. Procedimiento para mover datos a SILVER y registrar log

```sql
CREATE OR REPLACE PROCEDURE workshop.silver_recursos_humanos.proc_enrich_users_silver()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  MERGE INTO workshop.silver_recursos_humanos.users_silver AS target
  USING (
    SELECT * FROM workshop.bronze_recursos_humanos.users_stage
  ) AS source
  ON target.UserID = source.UserID AND target.WindowID = source.WindowID
  WHEN NOT MATCHED THEN
    INSERT (
      UserID, WindowID, Split, City, State, Country, ZipCode,
      DegreeType, Major, GraduationDate, WorkHistoryCount, TotalYearsExperience,
      CurrentlyEmployed, ManagedOthers, ManagedHowMany,
      FechaHoraCarga, ProcesoCarga, FuenteArchivo
    )
    VALUES (
      source.UserID, source.WindowID, source.Split, source.City, source.State, source.Country, source.ZipCode,
      source.DegreeType, source.Major, source.GraduationDate, source.WorkHistoryCount, source.TotalYearsExperience,
      source.CurrentlyEmployed, source.ManagedOthers, source.ManagedHowMany,
      CURRENT_TIMESTAMP, 'snowpipe_users_pipe', NULL
    );

  INSERT INTO workshop.bronze_recursos_humanos.carga_logs
  VALUES (
    'workshop.silver_recursos_humanos.users_silver', NULL, CURRENT_TIMESTAMP, NULL,
    'snowpipe_users_pipe', 'Carga ejecutada con MERGE para evitar duplicados'
  );

  TRUNCATE TABLE workshop.bronze_recursos_humanos.users_stage;

  RETURN 'Carga ejecutada correctamente con MERGE.';
END;
$$;
```

---

### 4. Crear TASK programado

```sql
CREATE OR REPLACE TASK workshop.silver_recursos_humanos.enrich_users_silver
  WAREHOUSE = WH_SMALL
  SCHEDULE = 'USING CRON 0 3 * * * UTC'
AS
CALL workshop.silver_recursos_humanos.proc_enrich_users_silver();
```

Activar el task:

```sql
ALTER TASK workshop.silver_recursos_humanos.enrich_users_silver RESUME;
```

---

## JOBS

### 1. Tabla staging (`jobs_stage`) en BRONZE

```sql
CREATE OR REPLACE TABLE workshop.bronze_recursos_humanos.jobs_stage (
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
```

### 2. Tabla enriquecida (`jobs_silver`) en SILVER

```sql
CREATE OR REPLACE TABLE workshop.silver_recursos_humanos.jobs_silver (
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
```

---

### 3. Snowpipe para `jobs`

```sql
CREATE OR REPLACE PIPE workshop.bronze_recursos_humanos.jobs_pipe AUTO_INGEST = TRUE
AS
COPY INTO workshop.bronze_recursos_humanos.jobs_stage
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

---

### 4. Procedimiento con MERGE para `jobs`

```sql
CREATE OR REPLACE PROCEDURE workshop.silver_recursos_humanos.proc_enrich_jobs_silver()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  MERGE INTO workshop.silver_recursos_humanos.jobs_silver AS target
  USING (
    SELECT * FROM workshop.bronze_recursos_humanos.jobs_stage
  ) AS source
  ON target.JobID = source.JobID AND target.WindowID = source.WindowID
  WHEN NOT MATCHED THEN
    INSERT (
      JobID, WindowID, Title, Description, Requirements,
      City, State, Country, Zip5, StartDate, EndDate,
      FechaHoraCarga, ProcesoCarga, FuenteArchivo
    )
    VALUES (
      source.JobID, source.WindowID, source.Title, source.Description, source.Requirements,
      source.City, source.State, source.Country, source.Zip5, source.StartDate, source.EndDate,
      CURRENT_TIMESTAMP, 'snowpipe_jobs_pipe', NULL
    );

  INSERT INTO workshop.bronze_recursos_humanos.carga_logs
  VALUES (
    'workshop.silver_recursos_humanos.jobs_silver', NULL, CURRENT_TIMESTAMP, NULL,
    'snowpipe_jobs_pipe', 'Carga ejecutada con MERGE para evitar duplicados'
  );

  TRUNCATE TABLE workshop.bronze_recursos_humanos.jobs_stage;

  RETURN 'Carga ejecutada correctamente con MERGE.';
END;
$$;
```

---

### 5. TASK para `jobs`

```sql
CREATE OR REPLACE TASK workshop.silver_recursos_humanos.enrich_jobs_silver
  WAREHOUSE = WH_SMALL
  SCHEDULE = 'USING CRON 0 3 * * * UTC'
AS
CALL workshop.silver_recursos_humanos.proc_enrich_jobs_silver();
```

Activar el task:

```sql
ALTER TASK workshop.silver_recursos_humanos.enrich_jobs_silver RESUME;
```

---

### Verificar logs

```sql
SELECT *
FROM workshop.bronze_recursos_humanos.carga_logs
ORDER BY FechaCarga DESC;
```
