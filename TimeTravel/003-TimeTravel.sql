
-- Establecemos el contexto de trabajo
USE DATABASE WORKSHOP;
USE SCHEMA BRONZE_MERCADEO;

-- 1. Crear tabla ficticia con retención de 3 días
CREATE OR REPLACE TABLE transacciones_credito (
    id_transaccion STRING,
    fecha_transaccion TIMESTAMP_NTZ,
    nombre_cliente STRING,
    monto FLOAT,
    categoria STRING
)
DATA_RETENTION_TIME_IN_DAYS = 3;

-- 2. Insertar registros con marca de tiempo
INSERT INTO transacciones_credito VALUES
('T001', '2025-05-26 08:55:00', 'Ana López',     85.50,  'Restaurante'),
('T002', '2025-05-26 09:05:00', 'Carlos Reyes', 120.00,  'Supermercado'),
('T003', '2025-05-26 09:10:00', 'Luis Pérez',   35.25,   'Gasolina');

-- 3. Verificar contenido actual
SELECT * FROM transacciones_credito;

-- 4. Eliminar datos por error después de las 9:00 a.m.
DELETE FROM transacciones_credito WHERE fecha_transaccion < '2025-05-26 09:10:00';

-- 5. Consultar la tabla tal como estaba a las 09:00 a.m.
SELECT * FROM transacciones_credito 
  AT (TIMESTAMP => '2025-05-26 09:00:00');

-- ¿Qué hace esto?
-- Solo permite ver los datos anteriores. No modifica ni restaura nada por sí solo.

-- 6. Crear una tabla CLONADA con el estado exacto a las 09:00 a.m.
CREATE OR REPLACE TABLE transacciones_9am_backup 
  CLONE transacciones_credito 
  AT (TIMESTAMP => '2025-05-26 09:00:00');

-- ¿Qué hace esto?
-- Crea una nueva tabla física con los datos tal como estaban a esa hora. Ideal para recuperar información perdida.

-- 7. Comparar datos actuales vs los del respaldo
SELECT * FROM transacciones_9am_backup
MINUS
SELECT * FROM transacciones_credito;

-- 8. Recuperar un registro eliminado usando la tabla clonada
INSERT INTO transacciones_credito
SELECT * FROM transacciones_9am_backup
WHERE id_transaccion = 'T002';

-- 9. Consultar retención actual
SHOW TABLES LIKE 'transacciones_credito';

-- 10. Cambiar la retención a 7 días (requiere edición Enterprise)
ALTER TABLE transacciones_credito SET DATA_RETENTION_TIME_IN_DAYS = 7;

-- 11. Confirmar el cambio de retención
SHOW TABLES LIKE 'transacciones_credito';

-- En resumen:
-- SELECT ... AT (TIMESTAMP): solo consulta datos históricos, útil para comparar o auditar.
-- CLONE ... AT (TIMESTAMP): crea una copia física y restaurable del estado anterior.
