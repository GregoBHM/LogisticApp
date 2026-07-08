-- Migración: Crear tabla de empaques personalizados por proyecto
-- Ejecutar en Supabase -> SQL Editor

CREATE TABLE IF NOT EXISTS empaques (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proyecto_id UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    unidad_medida VARCHAR(50) NOT NULL,
    cantidad_por_unidad FLOAT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para búsquedas rápidas por proyecto
CREATE INDEX IF NOT EXISTS idx_empaques_proyecto_id ON empaques(proyecto_id);
