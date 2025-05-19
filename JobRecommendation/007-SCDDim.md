
# Automatización de carga SCD Type 2 para dimensión USERS en la capa ORO

Este flujo implementa una dimensión lentamente cambiante (SCD Tipo 2) basada en la tabla enriquecida `users_silver`, manteniendo un histórico de los cambios en la capa `GOLD`.


# Permisos requeridos para ejecutar la carga SCD2 en la capa GOLD

Antes de ejecutar la creación de tablas, procedimientos o tareas en el esquema `workshop.gold_analitica`, es necesario que el rol `role_developer` cuente con los permisos adecuados.

A continuación se detallan los comandos que debe ejecutar un usuario con rol `ACCOUNTADMIN` o propietario de la base de datos:

```sql
-- Otorgar acceso al esquema
GRANT USAGE ON SCHEMA workshop.gold_recursos_humanos TO ROLE role_developer;

-- Permitir crear tablas
GRANT CREATE TABLE ON SCHEMA workshop.gold_recursos_humanos TO ROLE role_developer;

-- Permitir crear procedimientos
GRANT CREATE PROCEDURE ON SCHEMA workshop.gold_recursos_humanos TO ROLE role_developer;

-- Permitir operaciones de lectura y escritura sobre todas las tablas existentes
GRANT INSERT, SELECT, UPDATE, DELETE ON ALL TABLES IN SCHEMA workshop.gold_recursos_humanos TO ROLE role_developer;

```

Una vez otorgados estos permisos, el rol `role_developer` podrá ejecutar la carga y mantenimiento de la dimensión `users_dim` de forma completa en la capa ORO.


---

## 1. Crear tabla destino: `users_dim` (modelo SCD Type 2)

```sql
CREATE OR REPLACE TABLE workshop.gold_analitica.users_dim (
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
  FechaInicio DATE,
  FechaFin DATE,
  EsActual BOOLEAN,
  ProcesoCarga STRING,
  FuenteArchivo STRING
);
```

---

## 2. Crear procedimiento para mantener la dimensión `users_dim` con cambios

```sql
CREATE OR REPLACE PROCEDURE workshop.gold_analitica.proc_scdfill_users_dim()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- 1. Cierra registros antiguos que han cambiado
  UPDATE workshop.gold_analitica.users_dim AS d
  SET FechaFin = CURRENT_DATE - 1,
      EsActual = FALSE
  FROM workshop.silver_recursos_humanos.users_silver AS s
  WHERE d.UserID = s.UserID
    AND d.EsActual = TRUE
    AND (
      d.City IS DISTINCT FROM s.City OR
      d.State IS DISTINCT FROM s.State OR
      d.ZipCode IS DISTINCT FROM s.ZipCode OR
      d.DegreeType IS DISTINCT FROM s.DegreeType OR
      d.Major IS DISTINCT FROM s.Major OR
      d.GraduationDate IS DISTINCT FROM s.GraduationDate OR
      d.WorkHistoryCount IS DISTINCT FROM s.WorkHistoryCount OR
      d.TotalYearsExperience IS DISTINCT FROM s.TotalYearsExperience OR
      d.CurrentlyEmployed IS DISTINCT FROM s.CurrentlyEmployed OR
      d.ManagedOthers IS DISTINCT FROM s.ManagedOthers OR
      d.ManagedHowMany IS DISTINCT FROM s.ManagedHowMany
    );

  -- 2. Inserta nuevos registros donde hay cambios o no existía el usuario
  INSERT INTO workshop.gold_analitica.users_dim (
    UserID, WindowID, Split, City, State, Country, ZipCode,
    DegreeType, Major, GraduationDate, WorkHistoryCount, TotalYearsExperience,
    CurrentlyEmployed, ManagedOthers, ManagedHowMany,
    FechaInicio, FechaFin, EsActual, ProcesoCarga, FuenteArchivo
  )
  SELECT
    s.UserID, s.WindowID, s.Split, s.City, s.State, s.Country, s.ZipCode,
    s.DegreeType, s.Major, s.GraduationDate, s.WorkHistoryCount, s.TotalYearsExperience,
    s.CurrentlyEmployed, s.ManagedOthers, s.ManagedHowMany,
    CURRENT_DATE, NULL, TRUE, s.ProcesoCarga, s.FuenteArchivo
  FROM workshop.silver_recursos_humanos.users_silver AS s
  LEFT JOIN workshop.gold_analitica.users_dim AS d
    ON s.UserID = d.UserID AND d.EsActual = TRUE
  WHERE d.UserID IS NULL
     OR (
      d.City IS DISTINCT FROM s.City OR
      d.State IS DISTINCT FROM s.State OR
      d.ZipCode IS DISTINCT FROM s.ZipCode OR
      d.DegreeType IS DISTINCT FROM s.DegreeType OR
      d.Major IS DISTINCT FROM s.Major OR
      d.GraduationDate IS DISTINCT FROM s.GraduationDate OR
      d.WorkHistoryCount IS DISTINCT FROM s.WorkHistoryCount OR
      d.TotalYearsExperience IS DISTINCT FROM s.TotalYearsExperience OR
      d.CurrentlyEmployed IS DISTINCT FROM s.CurrentlyEmployed OR
      d.ManagedOthers IS DISTINCT FROM s.ManagedOthers OR
      d.ManagedHowMany IS DISTINCT FROM s.ManagedHowMany
    );

  RETURN 'Carga SCD2 ejecutada correctamente en users_dim.';
END;
$$;
```

---

## 3. (Opcional) Crear TASK para ejecución diaria

```sql
CREATE OR REPLACE TASK workshop.gold_analitica.enrich_users_dim
  WAREHOUSE = WH_SMALL
  SCHEDULE = 'USING CRON 0 4 * * * UTC'
AS
CALL workshop.gold_analitica.proc_scdfill_users_dim();
```

Activar el task:

```sql
ALTER TASK workshop.gold_analitica.enrich_users_dim RESUME;
```

---

## 4. Consultar la dimensión y los historiales

```sql
SELECT *
FROM workshop.gold_analitica.users_dim
WHERE UserID = 47
ORDER BY FechaInicio;
```

Este diseño permite mantener historial completo de atributos cambiantes por usuario y detectar su vigencia mediante las columnas `FechaInicio`, `FechaFin` y `EsActual`.
