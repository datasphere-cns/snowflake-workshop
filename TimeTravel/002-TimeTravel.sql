
-- Establecemos el contexto de trabajo
USE DATABASE WORKSHOP;
USE SCHEMA BRONZE_MERCADEO;

-- 1. Crear tabla ficticia con retención de 1 día para fines de Time Travel
CREATE OR REPLACE TABLE transacciones_credito (
    id_transaccion STRING,
    fecha_transaccion DATE,
    nombre_cliente STRING,
    monto FLOAT,
    categoria STRING
)
DATA_RETENTION_TIME_IN_DAYS = 1;

-- 2. Insertar registros ficticios
INSERT INTO transacciones_credito VALUES
('T001', '2025-05-20', 'Ana López',     85.50,  'Restaurante'),
('T002', '2025-05-21', 'Carlos Reyes', 120.00,  'Supermercado'),
('T003', '2025-05-21', 'Luis Pérez',   35.25,  'Gasolina'),
('T004', '2025-05-22', 'Marta Gómez',  55.75,  'Ropa');

-- 3. Verificar contenido original
SELECT * FROM transacciones_credito;

-- 4. Eliminar una fila por error
DELETE FROM transacciones_credito WHERE id_transaccion = 'T003';

-- 5. Consultar el estado de la tabla justo antes del DELETE
SELECT * FROM transacciones_credito 
  BEFORE (STATEMENT => LAST_QUERY_ID());

-- 6. Restaurar la fila eliminada
INSERT INTO transacciones_credito
SELECT * FROM transacciones_credito 
  BEFORE (STATEMENT => LAST_QUERY_ID())
WHERE id_transaccion = 'T003';

-- 7. Crear una tabla clonada con el estado anterior
CREATE OR REPLACE TABLE transacciones_backup 
  CLONE transacciones_credito 
  AT (OFFSET => -300); -- aproximadamente 5 minutos atrás

-- 8. Verificar contenido restaurado
SELECT * FROM transacciones_credito;

-- 9. Eliminar completamente la tabla (simular un error)
DROP TABLE transacciones_credito;

-- 10. Restaurar la tabla eliminada (si estamos dentro del período de retención)
UNDROP TABLE transacciones_credito;

-- 11. Verificar contenido después de restaurar
SELECT * FROM transacciones_credito;

-- CONSULTAR la retención actual configurada para una tabla
SHOW TABLES LIKE 'transacciones_credito';

-- CAMBIAR el período de retención a 7 días (requiere Enterprise Edition)
ALTER TABLE transacciones_credito SET DATA_RETENTION_TIME_IN_DAYS = 7;

-- Confirmar el cambio de retención
SHOW TABLES LIKE 'transacciones_credito';
