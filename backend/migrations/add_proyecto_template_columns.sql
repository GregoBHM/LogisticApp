-- GyL Logistic: Migración de Plantilla de Proyecto
-- Agrega campos de plantilla al proyecto para auto-llenar nuevas cuentas/lotes

ALTER TABLE proyectos ADD COLUMN IF NOT EXISTS producto_default VARCHAR;
ALTER TABLE proyectos ADD COLUMN IF NOT EXISTS tipo_unidad_default VARCHAR;
ALTER TABLE proyectos ADD COLUMN IF NOT EXISTS unidad_medida_default VARCHAR;
ALTER TABLE proyectos ADD COLUMN IF NOT EXISTS cantidad_por_unidad_default FLOAT;
