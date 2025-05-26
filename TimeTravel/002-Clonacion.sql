-- Clonar la base de datos WORKSHOP para ambiente de desarrollo
CREATE OR REPLACE DATABASE WORKSHOP_DEV 
  CLONE WORKSHOP;

-- Clonar la base de datos WORKSHOP para ambiente de pruebas de aceptación
CREATE OR REPLACE DATABASE WORKSHOP_UAT 
  CLONE WORKSHOP;

-- Opcional: Verificar que las bases se crearon correctamente
SHOW DATABASES LIKE 'WORKSHOP_%';

-- Opcional: Usar una de las nuevas bases para empezar a trabajar
USE DATABASE WORKSHOP_DEV;

--Recomendaciones adicionales
--Si deseas clonar a un estado pasado (por ejemplo, antes de un cambio), puedes usar AT (TIMESTAMP => 'YYYY-MM-DD HH:MI:SS').
--Puedes asignar permisos a los nuevos entornos usando GRANT USAGE ON DATABASE según tus roles.
--No olvides revisar que los stages externos o pipes no se copian (deberás configurarlos aparte si los necesitas en DEV o UAT).
