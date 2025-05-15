-- ============================================================================
-- SCRIPT DE DEMOSTRACIÓN: NETWORK POLICY EN SNOWFLAKE
-- Proyecto: Ejemplo de política de red con estructura completa
-- Descripción:
--   Este script define una política de red con una IP pública permitida ('0.0.0.0/0')
--   que representa acceso total (inseguro, solo para demostración) y bloquea una
--   dirección IP ficticia. Esto sirve para mostrar la sintaxis completa.
--
--   En un entorno real, se deben especificar únicamente IPs confiables en la lista
--   de permitidas y evitar el uso de '0.0.0.0/0'.
--
-- Autor: Nelson Zepeda
-- Fecha: 2025-05-10
-- ============================================================================

-- 1. Crear la política de red
CREATE OR REPLACE NETWORK POLICY policy_demo_completa
ALLOWED_IP_LIST = (
  '0.0.0.0/0'  -- Permitir todas las IPs (solo para demostración, NO usar en producción)
)
BLOCKED_IP_LIST = (
  '203.0.113.123'  -- IP bloqueada ficticia para mostrar uso del parámetro
)
COMMENT = 'Política de red de ejemplo con ALLOWED y BLOCKED IPs. Solo para fines de demo.';

-- 2. Aplicar la política a nivel de cuenta (solo si estás en entorno de pruebas)
ALTER ACCOUNT SET NETWORK_POLICY = policy_demo_completa;

-- 3. Verificación
SHOW PARAMETERS LIKE 'NETWORK_POLICY';
