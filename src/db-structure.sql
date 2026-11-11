-- 1. Tabla de Colecciones
CREATE TABLE collections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  owner TEXT, -- Para identificar si es tuyo, de tu mujer o de tu hija
  total_regular INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Tabla de Grupos Especiales (ej. X1, X2... o F1, F2...)
CREATE TABLE special_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  prefix TEXT NOT NULL,
  total INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Tabla de Progreso (cromos conseguidos)
CREATE TABLE progress (
  collection_id UUID PRIMARY KEY REFERENCES collections(id) ON DELETE CASCADE,
  acquired JSONB DEFAULT '[]'::jsonb, -- Guardaremos un array como ["1", "5", "X2"]
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================================
-- CONFIGURACIÓN DE SEGURIDAD (Row Level Security - RLS)
-- ============================================================================

-- Habilitar RLS en las tres tablas
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE special_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso temporal (Permiten leer/escribir sin estar logueado)
CREATE POLICY "Acceso total temporal collections" ON collections FOR ALL USING (true);
CREATE POLICY "Acceso total temporal special_groups" ON special_groups FOR ALL USING (true);
CREATE POLICY "Acceso total temporal progress" ON progress FOR ALL USING (true);