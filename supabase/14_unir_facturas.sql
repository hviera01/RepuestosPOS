create or replace function unir_facturas_credito(
  p_ids uuid[],
  p_documento text,
  p_nombre text,
  p_vencimiento timestamptz,
  p_numero text
) returns uuid
language plpgsql as $$
declare
  r ventas_credito%rowtype;
  v_total numeric := 0;
  v_origen jsonb := '[]'::jsonb;
  v_encontradas integer := 0;
  v_id uuid;
begin
  if p_ids is null or array_length(p_ids, 1) < 2 then
    raise exception 'Seleccione al menos dos facturas para unir';
  end if;
  for r in select * from ventas_credito where id = any(p_ids) order by id for update loop
    v_encontradas := v_encontradas + 1;
    if r.saldo_pendiente <= 0 then
      raise exception 'Solo se pueden unir facturas con saldo pendiente (%)', r.numero_documento;
    end if;
    v_total := v_total + r.saldo_pendiente;
    if jsonb_array_length(r.facturas_origen) > 0 then
      v_origen := v_origen || r.facturas_origen;
    else
      v_origen := v_origen || jsonb_build_array(jsonb_build_object('id', r.id, 'numeroDocumento', r.numero_documento, 'saldoPendiente', r.saldo_pendiente));
    end if;
  end loop;
  if v_encontradas <> array_length(p_ids, 1) then
    raise exception 'Alguna de las facturas ya no existe';
  end if;
  update ventas_credito set saldo_pendiente = 0, fusionada = true where id = any(p_ids);
  insert into ventas_credito (
    documento_cliente, nombre_cliente, numero_documento, monto_total, saldo_pendiente,
    fecha_vencimiento, sin_venta_origen, facturas_origen
  ) values (
    case when coalesce(trim(p_documento), '') = '' then 'N/A' else trim(p_documento) end,
    p_nombre, p_numero, round(v_total, 2), round(v_total, 2), p_vencimiento, true, v_origen
  ) returning id into v_id;
  return v_id;
end;
$$;

grant execute on function unir_facturas_credito(uuid[], text, text, timestamptz, text) to authenticated;
revoke execute on function unir_facturas_credito(uuid[], text, text, timestamptz, text) from public, anon;
