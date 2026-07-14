CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE public.perfiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre      TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE public.proyectos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          TEXT NOT NULL CHECK (char_length(nombre) >= 2),
    descripcion     TEXT,
    moneda_simbolo  TEXT NOT NULL DEFAULT 'S/' CHECK (moneda_simbolo IN ('S/', '$', 'MXN', 'COP', 'BRL', '€')),
    moneda_codigo   TEXT NOT NULL DEFAULT 'PEN' CHECK (moneda_codigo IN ('PEN', 'USD', 'MXN', 'COP', 'BRL', 'EUR')),
    creado_por      UUID NOT NULL REFERENCES public.perfiles(id),
    created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE public.proyecto_miembros (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proyecto_id UUID NOT NULL REFERENCES public.proyectos(id) ON DELETE CASCADE,
    usuario_id  UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    rol         TEXT NOT NULL DEFAULT 'vendedor' CHECK (rol IN ('dueño', 'vendedor')),
    invited_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE (proyecto_id, usuario_id)
);

CREATE TABLE public.cuentas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proyecto_id         UUID NOT NULL REFERENCES public.proyectos(id) ON DELETE CASCADE,
    nombre              TEXT NOT NULL CHECK (char_length(nombre) >= 2),
    producto            TEXT NOT NULL,
    tipo_unidad         TEXT NOT NULL,
    cantidad_unidades   NUMERIC NOT NULL CHECK (cantidad_unidades > 0),
    cantidad_por_unidad NUMERIC NOT NULL CHECK (cantidad_por_unidad > 0),
    stock_total         NUMERIC GENERATED ALWAYS AS (cantidad_unidades * cantidad_por_unidad) STORED,
    inversion_total     NUMERIC NOT NULL CHECK (inversion_total > 0),
    precio_unitario     NUMERIC NOT NULL CHECK (precio_unitario > 0),
    estado              TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta', 'cerrada')),
    creado_por          UUID NOT NULL REFERENCES public.perfiles(id),
    cerrado_por         UUID REFERENCES public.perfiles(id),
    fecha_apertura      DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_cierre        DATE,
    created_at          TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE public.ventas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id       UUID NOT NULL REFERENCES public.cuentas(id) ON DELETE CASCADE,
    registrado_por  UUID NOT NULL REFERENCES public.perfiles(id),
    cliente         TEXT NOT NULL CHECK (char_length(cliente) >= 2),
    cantidad_vendida    NUMERIC NOT NULL CHECK (cantidad_vendida > 0),
    precio_unitario     NUMERIC NOT NULL CHECK (precio_unitario > 0),
    total_venta         NUMERIC GENERATED ALWAYS AS (cantidad_vendida * precio_unitario) STORED,
    fecha_venta     DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE public.abonos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id        UUID NOT NULL REFERENCES public.ventas(id) ON DELETE CASCADE,
    registrado_por  UUID NOT NULL REFERENCES public.perfiles(id),
    monto           NUMERIC NOT NULL CHECK (monto > 0),
    fecha_abono     DATE NOT NULL DEFAULT CURRENT_DATE,
    nota            TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE public.gastos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cuenta_id       UUID NOT NULL REFERENCES public.cuentas(id) ON DELETE CASCADE,
    registrado_por  UUID NOT NULL REFERENCES public.perfiles(id),
    descripcion     TEXT NOT NULL CHECK (char_length(descripcion) >= 2),
    monto           NUMERIC NOT NULL CHECK (monto > 0),
    fecha_gasto     DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE OR REPLACE VIEW public.ventas_con_saldo AS
SELECT
    v.id,
    v.cuenta_id,
    v.registrado_por,
    p.nombre AS registrado_por_nombre,
    v.cliente,
    v.cantidad_vendida,
    v.precio_unitario,
    v.total_venta,
    COALESCE(SUM(a.monto), 0) AS total_abonado,
    GREATEST(v.total_venta - COALESCE(SUM(a.monto), 0), 0) AS saldo_pendiente,
    CASE
        WHEN COALESCE(SUM(a.monto), 0) >= v.total_venta THEN 'Pagado'
        WHEN COALESCE(SUM(a.monto), 0) > 0 THEN 'Parcial'
        ELSE 'Pendiente'
    END AS estado_pago,
    v.fecha_venta,
    v.created_at
FROM public.ventas v
LEFT JOIN public.abonos a ON a.venta_id = v.id
LEFT JOIN public.perfiles p ON p.id = v.registrado_por
GROUP BY v.id, p.nombre;

CREATE OR REPLACE VIEW public.cuentas_resumen AS
SELECT
    c.id,
    c.proyecto_id,
    c.nombre,
    c.producto,
    c.tipo_unidad,
    c.cantidad_unidades,
    c.cantidad_por_unidad,
    c.stock_total,
    c.inversion_total,
    c.precio_unitario,
    c.estado,
    c.fecha_apertura,
    c.fecha_cierre,
    COALESCE(SUM(v.total_venta), 0) AS ingresos_brutos,
    COALESCE(SUM(v.cantidad_vendida), 0) AS cantidad_vendida_total,
    GREATEST(c.stock_total - COALESCE(SUM(v.cantidad_vendida), 0), 0) AS stock_restante,
    COALESCE(SUM(ab.monto_total), 0) AS total_cobrado,
    COALESCE(SUM(g.monto), 0) AS total_gastos,
    COALESCE(SUM(ab.monto_total), 0) - c.inversion_total - COALESCE(SUM(g.monto), 0) AS ganancia_real
FROM public.cuentas c
LEFT JOIN public.ventas v ON v.cuenta_id = c.id
LEFT JOIN (
    SELECT venta_id, SUM(monto) AS monto_total FROM public.abonos GROUP BY venta_id
) ab ON ab.venta_id = v.id
LEFT JOIN public.gastos g ON g.cuenta_id = c.id
GROUP BY c.id;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.perfiles (id, email, nombre)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_proyecto()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.proyecto_miembros (proyecto_id, usuario_id, rol)
    VALUES (NEW.id, NEW.creado_por, 'dueño');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_proyecto_created
    AFTER INSERT ON public.proyectos
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_proyecto();

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_proyectos_updated_at BEFORE UPDATE ON public.proyectos
    FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at();
CREATE TRIGGER update_cuentas_updated_at BEFORE UPDATE ON public.cuentas
    FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at();
CREATE TRIGGER update_ventas_updated_at BEFORE UPDATE ON public.ventas
    FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at();

ALTER TABLE public.perfiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proyectos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proyecto_miembros  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cuentas            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ventas             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abonos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gastos             ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.es_miembro_de_proyecto(p_proyecto_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.proyecto_miembros
        WHERE proyecto_id = p_proyecto_id AND usuario_id = auth.uid()
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE POLICY "perfiles_select_own" ON public.perfiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "perfiles_update_own" ON public.perfiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY "proyectos_select" ON public.proyectos FOR SELECT USING (public.es_miembro_de_proyecto(id));
CREATE POLICY "proyectos_insert" ON public.proyectos FOR INSERT WITH CHECK (creado_por = auth.uid());
CREATE POLICY "proyectos_update" ON public.proyectos FOR UPDATE USING (public.es_miembro_de_proyecto(id));
CREATE POLICY "proyectos_delete" ON public.proyectos FOR DELETE USING (creado_por = auth.uid());

CREATE POLICY "miembros_select" ON public.proyecto_miembros FOR SELECT USING (public.es_miembro_de_proyecto(proyecto_id));
CREATE POLICY "miembros_insert" ON public.proyecto_miembros FOR INSERT WITH CHECK (public.es_miembro_de_proyecto(proyecto_id));

CREATE POLICY "cuentas_select" ON public.cuentas FOR SELECT USING (public.es_miembro_de_proyecto(proyecto_id));
CREATE POLICY "cuentas_insert" ON public.cuentas FOR INSERT WITH CHECK (public.es_miembro_de_proyecto(proyecto_id));
CREATE POLICY "cuentas_update" ON public.cuentas FOR UPDATE USING (public.es_miembro_de_proyecto(proyecto_id));

CREATE POLICY "ventas_select" ON public.ventas FOR SELECT
    USING (public.es_miembro_de_proyecto((SELECT proyecto_id FROM public.cuentas WHERE id = cuenta_id)));
CREATE POLICY "ventas_insert" ON public.ventas FOR INSERT
    WITH CHECK (public.es_miembro_de_proyecto((SELECT proyecto_id FROM public.cuentas WHERE id = cuenta_id)));

CREATE POLICY "abonos_select" ON public.abonos FOR SELECT
    USING (public.es_miembro_de_proyecto((SELECT c.proyecto_id FROM public.cuentas c JOIN public.ventas v ON v.cuenta_id = c.id WHERE v.id = venta_id)));
CREATE POLICY "abonos_insert" ON public.abonos FOR INSERT
    WITH CHECK (public.es_miembro_de_proyecto((SELECT c.proyecto_id FROM public.cuentas c JOIN public.ventas v ON v.cuenta_id = c.id WHERE v.id = venta_id)));

CREATE POLICY "gastos_select" ON public.gastos FOR SELECT
    USING (public.es_miembro_de_proyecto((SELECT proyecto_id FROM public.cuentas WHERE id = cuenta_id)));
CREATE POLICY "gastos_insert" ON public.gastos FOR INSERT
    WITH CHECK (public.es_miembro_de_proyecto((SELECT proyecto_id FROM public.cuentas WHERE id = cuenta_id)));
