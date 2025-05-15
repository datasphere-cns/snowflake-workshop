-- ============================================================================
-- SCRIPT DE CREACIÓN DE COMPUTE POOL EN SNOWFLAKE
-- Proyecto: Plataforma de Datos Avanzados con Snowpark Container Services
-- Descripción:
--   Este script crea un Compute Pool en Snowflake, que es una agrupación de
--   recursos de cómputo utilizada por Snowpark Container Services.
--
--   Los Compute Pools permiten ejecutar contenedores Docker directamente dentro
--   del ecosistema de Snowflake, facilitando tareas como:
--     - Despliegue de microservicios y APIs personalizados.
--     - Ejecución de modelos de Machine Learning (entrenamiento/inferencia).
--     - Procesamiento avanzado de datos con librerías externas (p. ej. spaCy, TensorFlow).
--     - Análisis en notebooks embebidos.
--
--   A diferencia de los warehouses tradicionales, los Compute Pools están diseñados
--   para ejecutarse en un entorno controlado por el usuario y no se autosuspenden
--   de forma automática por consultas SQL.
--
-- Requisitos:
--   - Edición Enterprise de Snowflake o superior.
--   - Funcionalidad Snowpark Container Services habilitada.
--   - Repositorio de imágenes Docker accesible (ej. ECR, DockerHub, etc.).
--
-- Autor: Nelson Zepeda
-- Email: nelson.zepeda@datasphere.tech
-- Fecha de creación: 2025-05-01
-- Log de Cambios:
--
--
--
-- ============================================================================


-- =========================================
-- 1. CREACIÓN DEL COMPUTE POOL
-- =========================================

CREATE OR REPLACE COMPUTE POOL ML_COMPUTE_POOL
MIN_INSTANCES = 1
MAX_INSTANCES = 2
INSTANCE_FAMILY = 'CPU_X64_XS'  -- Tamaño pequeño para pruebas
AUTO_RESUME = TRUE
AUTO_SUSPEND = 1800  -- 30 minutos de inactividad
COMMENT = 'Compute Pool para servicios de ML, APIs o procesamiento avanzado usando Snowpark Container Services.';


-- =========================================
-- 2. VERIFICACIÓN
-- =========================================

-- Ver detalles del compute pool creado
SHOW COMPUTE POOLS;

-- Describir el compute pool
DESCRIBE COMPUTE POOL ML_COMPUTE_POOL;

