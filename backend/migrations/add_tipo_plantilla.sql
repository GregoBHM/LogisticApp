-- GyL Logistic: Fase 1 — Añadir tipo de plantilla al proyecto
-- Los proyectos existentes se quedan como COMERCIO automáticamente

ALTER TABLE proyectos 
ADD COLUMN IF NOT EXISTS tipo_plantilla VARCHAR DEFAULT 'COMERCIO' NOT NULL;
