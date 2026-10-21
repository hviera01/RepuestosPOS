do $$
declare
  t text;
begin
  foreach t in array array[
    'usuarios', 'producto_lotes_costo', 'pendientes_reposicion', 'compras', 'ventas_en_espera', 'compras_en_espera',
    'compra_credito_abonos', 'egresos', 'cajas', 'producto_historial_stock', 'compra_items', 'venta_items',
    'traslado_items', 'producto_historial_ventas', 'producto_historial_precios_compra', 'producto_historial_traslados'
  ] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
