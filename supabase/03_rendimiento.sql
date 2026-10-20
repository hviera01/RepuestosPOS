create or replace function ejecutar_idempotente(p_op_id uuid, p_funcion text, p_args jsonb) returns jsonb
language plpgsql as $$
declare
  v_previo operaciones_aplicadas%rowtype;
  v_resultado jsonb;
  v_es_void boolean;
  v_payload_funcs text[] := array[
    'registrar_cierre_caja', 'registrar_compra', 'registrar_abono_compra_credito', 'editar_abono_compra_credito',
    'registrar_abono_general_compra_credito', 'registrar_ingreso_stock', 'registrar_salida_stock', 'descontar_stock',
    'registrar_venta', 'guardar_venta_en_espera_manual', 'registrar_abono_venta_credito', 'editar_abono_venta_credito',
    'registrar_traslado'
  ];
begin
  perform pg_advisory_xact_lock(hashtextextended(p_op_id::text, 0));
  select * into v_previo from operaciones_aplicadas where op_id = p_op_id;
  if found then
    return v_previo.resultado;
  end if;

  if p_funcion = any (v_payload_funcs) then
    select (p.prorettype = 'void'::regtype) into v_es_void
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = p_funcion limit 1;
    if v_es_void then
      execute format('select %I($1)', p_funcion) using p_args->'payload';
      v_resultado := null;
    else
      execute format('select to_jsonb(%I($1))', p_funcion) into v_resultado using p_args->'payload';
    end if;
  elsif p_funcion = 'anular_venta' then
    perform anular_venta((p_args->>'p_id')::uuid, p_args->>'p_usuario', coalesce(p_args->>'p_motivo', ''));
  elsif p_funcion = 'anular_compra' then
    perform anular_compra((p_args->>'p_id')::uuid, p_args->>'p_usuario', coalesce(p_args->>'p_motivo', ''));
  elsif p_funcion = 'eliminar_abono_compra_credito' then
    perform eliminar_abono_compra_credito((p_args->>'p_id_compra')::uuid, (p_args->>'p_id_abono')::uuid, (p_args->>'p_monto_total')::numeric);
  elsif p_funcion = 'eliminar_abono_venta_credito' then
    perform eliminar_abono_venta_credito((p_args->>'p_id_credito')::uuid, (p_args->>'p_id_abono')::uuid, (p_args->>'p_monto_total')::numeric);
  elsif p_funcion = 'eliminar_venta_en_espera' then
    perform eliminar_venta_en_espera((p_args->>'p_id')::uuid, coalesce(p_args->>'p_usuario', ''));
  elsif p_funcion = 'anular_traslado' then
    perform anular_traslado((p_args->>'p_id')::uuid, coalesce(p_args->>'p_usuario', ''));
  elsif p_funcion = 'enviar_traslado' then
    perform enviar_traslado((p_args->>'p_id')::uuid);
  elsif p_funcion = 'recepcionar_traslado' then
    perform recepcionar_traslado((p_args->>'p_id')::uuid, coalesce(p_args->>'p_usuario', ''));
  else
    raise exception 'Función no permitida: %', p_funcion;
  end if;

  insert into operaciones_aplicadas (op_id, funcion, resultado) values (p_op_id, p_funcion, v_resultado);
  return v_resultado;
end;
$$;

create or replace function limpiar_operaciones_viejas() returns void
language sql as $$
  delete from operaciones_aplicadas where creado_en < now() - interval '30 days';
  delete from eliminados where eliminado_en < now() - interval '90 days';
$$;

do $$
declare
  t text;
begin
  foreach t in array array['ventas_credito', 'compras_credito', 'cierres_caja']
  loop
    execute format('alter table %I add column if not exists updated_at timestamptz not null default now()', t);
    execute format('create index if not exists idx_%s_updated_at on %I (updated_at)', t, t);
    execute format('drop trigger if exists tg_%s_touch on %I', t, t);
    execute format('create trigger tg_%s_touch before insert or update on %I for each row execute function tg_touch_updated_at()', t, t);
    execute format('drop trigger if exists tg_%s_eliminado on %I', t, t);
    execute format('create trigger tg_%s_eliminado after delete on %I for each row execute function tg_registrar_eliminado()', t, t);
  end loop;
end $$;

alter publication supabase_realtime add table compras_credito;

create index if not exists idx_ventas_activas_fecha on ventas (fecha_registro) include (total_a_pagar, tipo_documento) where estado = 'Activa';
create index if not exists idx_compras_activas_fecha on compras (fecha_registro) include (total_a_pagar) where estado = 'Activa';
create index if not exists idx_ventas_nombre_cliente on ventas (nombre_cliente);
create index if not exists idx_ventas_creditos_saldo on ventas_credito (saldo_pendiente) where saldo_pendiente > 0;
create index if not exists idx_compras_creditos_saldo on compras_credito (saldo_pendiente) where saldo_pendiente > 0;
create index if not exists idx_venta_items_venta_orden on venta_items (id_venta, orden);
create index if not exists idx_compra_items_compra_orden on compra_items (id_compra, orden);
create index if not exists idx_producto_historial_stock_prod_fecha on producto_historial_stock (id_producto, fecha desc);
create index if not exists idx_producto_hist_ventas_prod_fecha on producto_historial_ventas (id_producto, fecha desc);
create index if not exists idx_producto_hist_compras_prod_fecha on producto_historial_precios_compra (id_producto, fecha desc);
create index if not exists idx_egresos_fecha_metodo on egresos (fecha, metodo_pago);

create or replace function resumen_ventas_inicio(p_hoy timestamptz) returns jsonb
language sql stable as $$
  with v as (
    select fecha_registro, total_a_pagar
    from ventas
    where estado = 'Activa' and tipo_documento <> 'Cotizacion'
      and fecha_registro >= least(date_trunc('month', p_hoy), date_trunc('week', p_hoy), p_hoy - interval '6 days')
      and fecha_registro < p_hoy + interval '1 day'
  )
  select jsonb_build_object(
    'totalDia', coalesce(sum(total_a_pagar) filter (where fecha_registro >= p_hoy), 0),
    'cantidadDia', count(*) filter (where fecha_registro >= p_hoy),
    'totalMes', coalesce(sum(total_a_pagar) filter (where fecha_registro >= date_trunc('month', p_hoy)), 0),
    'totalSemana', coalesce(sum(total_a_pagar) filter (where fecha_registro >= date_trunc('week', p_hoy)), 0),
    'cantidadSemana', count(*) filter (where fecha_registro >= date_trunc('week', p_hoy)),
    'serie', (
      select jsonb_agg(jsonb_build_object('dia', d::date, 'total', coalesce((
        select sum(total_a_pagar) from v where fecha_registro >= d and fecha_registro < d + interval '1 day'
      ), 0)) order by d)
      from generate_series(p_hoy - interval '6 days', p_hoy, interval '1 day') d
    )
  ) from v;
$$;
