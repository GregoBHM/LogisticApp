-- GyL Logistic: Recreación de Vistas con Unidades Genéricas
-- Nota: Si la consola dijo 'column kilos_totales does not exist',
-- significa que las tablas ya habían sido migradas (o creadas nuevas) con las columnas correctas (stock_total, cantidad_vendida, etc).
-- Solo necesitamos arreglar y recrear las vistas.

DROP VIEW IF EXISTS public.resumen_cuentas CASCADE;
DROP VIEW IF EXISTS public.ventas_con_saldo CASCADE;

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
    v.created_at,
    v.updated_at
FROM public.ventas v
JOIN public.perfiles p ON p.id = v.registrado_por
LEFT JOIN public.abonos a ON a.venta_id = v.id
GROUP BY v.id, p.nombre;

CREATE OR REPLACE VIEW public.resumen_cuentas AS
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
