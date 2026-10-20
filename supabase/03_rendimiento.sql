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
