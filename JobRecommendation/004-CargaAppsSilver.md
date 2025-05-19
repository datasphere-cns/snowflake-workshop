
# Requisitos de permisos antes de usar Snowpipe

Antes de crear un PIPE o ejecutar tareas automáticas, asegúrate de que el rol con el que estás trabajando (ej. `usuario_dev`) tenga los permisos necesarios.

## Si tienes acceso a un rol con privilegios administrativos

Solicita o ejecuta los siguientes comandos con un rol como `ACCOUNTADMIN` (cambia de usuario a admin):

```sql
GRANT USAGE ON DATABASE workshop TO ROLE ROLE_DEVELOPER;
GRANT USAGE ON SCHEMA workshop.bronze_recursos_humanos TO ROLE ROLE_DEVELOPER;
GRANT CREATE PIPE ON SCHEMA workshop.bronze_recursos_humanos TO ROLE ROLE_DEVELOPER;
```

> Si no tienes permisos para ejecutar estos `GRANT`, contacta al administrador de Snowflake para solicitarlos antes de continuar.

---


# Automatización de carga BRONZE → SILVER con Snowpipe + Task + Logs

Ahora conectate con el usuario_developer. Este flujo implementa la carga continua y controlada de archivos desde S3 usando Snowpipe, con trazabilidad y separación entre zonas BRONZE y SILVER.

---

## 1. Estructura de tablas y esquemas

### Tabla de staging (`apps_stage`) en zona BRONZE

```sql
CREATE OR REPLACE TABLE workshop.bronze_recursos_humanos.apps_stage (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  ApplicationDate TIMESTAMP_NTZ,
  JobID STRING
);
```

### Tabla enriquecida (`apps_silver`) en zona SILVER

```sql
CREATE OR REPLACE TABLE workshop.silver_recursos_humanos.apps_silver (
  UserID STRING,
  WindowID STRING,
  Split STRING,
  ApplicationDate TIMESTAMP_NTZ,
  JobID STRING,
  FechaHoraCarga TIMESTAMP_NTZ,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);
```

### Tabla de logs

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

## 2. Crear Snowpipe para carga automática en tabla de staging

```sql
CREATE OR REPLACE PIPE workshop.bronze_recursos_humanos.apps_pipe AUTO_INGEST = TRUE
AS
COPY INTO workshop.bronze_recursos_humanos.apps_stage
FROM @job_stage
FILE_FORMAT = (FORMAT_NAME = job_tsv_format);
```

> Este `PIPE` cargará automáticamente nuevos archivos desde el stage en S3 hacia `apps_stage`.

---

## 3. Procedimiento para mover datos a SILVER y registrar log

```sql
CREATE OR REPLACE PROCEDURE workshop.silver_recursos_humanos.proc_enrich_apps_silver()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Cargar datos nuevos desde staging a SILVER usando MERGE
  MERGE INTO workshop.silver_recursos_humanos.apps_silver AS target
  USING (
    SELECT 
      UserID, WindowID, Split, ApplicationDate, JobID
    FROM workshop.bronze_recursos_humanos.apps_stage
  ) AS source
  ON target.UserID = source.UserID
     AND target.WindowID = source.WindowID
     AND target.JobID = source.JobID
  WHEN NOT MATCHED THEN
    INSERT (
      UserID, WindowID, Split, ApplicationDate, JobID,
      FechaHoraCarga, ProcesoCarga, FuenteArchivo
    )
    VALUES (
      source.UserID, source.WindowID, source.Split, source.ApplicationDate, source.JobID,
      CURRENT_TIMESTAMP, 'snowpipe_apps_pipe', NULL
    );

  -- Registrar log (sin conteo exacto)
  INSERT INTO workshop.bronze_recursos_humanos.carga_logs (
    TablaDestino, Archivo, FechaCarga, RegistrosCargados, Proceso, Observaciones
  )
  VALUES (
    'workshop.silver_recursos_humanos.apps_silver',
    NULL,
    CURRENT_TIMESTAMP,
    NULL,
    'snowpipe_apps_pipe',
    'Carga ejecutada con MERGE para evitar duplicados'
  );

  -- Limpiar staging
  TRUNCATE TABLE workshop.bronze_recursos_humanos.apps_stage;

  RETURN 'Carga ejecutada correctamente con MERGE.';
END;
$$;
```

---

## 4. Crear TASK programado para ejecutar el procedimiento cada día a las 3:00 AM UTC

```sql
CREATE OR REPLACE TASK workshop.silver_recursos_humanos.enrich_apps_silver
  WAREHOUSE = WH_SMALL
  SCHEDULE = 'USING CRON 0 3 * * * UTC'
AS
CALL workshop.silver_recursos_humanos.proc_enrich_apps_silver();
```

Activar el task:

```sql
ALTER TASK workshop.silver_recursos_humanos.enrich_apps_silver RESUME;
```

---

## 5. Verificar ejecución y logs

### Consultar logs de carga

```sql
SELECT *
FROM workshop.bronze_recursos_humanos.carga_logs
ORDER BY FechaCarga DESC;
```


---

Este patrón permite tener trazabilidad completa, separación de zonas y automatización segura de cargas desde S3 en Snowflake.

---
