create table if not exists cajas (
  id uuid primary key default gen_random_uuid(),
  estado text not null default 'abierta' check (estado in ('abierta', 'cerrada')),
  usuario text not null,
  usuario_cierre text not null default '',
  abierta_en timestamptz not null,
  cerrada_en timestamptz,
  monto_apertura numeric(12, 2) not null default 0,
  monto_cierre numeric(12, 2),
  efectivo_esperado numeric(12, 2),
  diferencia numeric(12, 2) not null default 0,
  notas text not null default '',
  notas_cierre text not null default '',
  resumen jsonb not null default '{}'::jsonb,
  creado_en timestamptz not null default now()
);
create index if not exists idx_cajas_estado on cajas (estado);
create index if not exists idx_cajas_usuario_abierta on cajas (usuario, abierta_en desc);
create index if not exists idx_cajas_abierta_en on cajas (abierta_en desc);

alter table cajas enable row level security;
drop policy if exists cajas_allow_all_anon on cajas;
create policy cajas_allow_all_anon on cajas for all using (true) with check (true);

create or replace function calcular_resumen_caja(p_usuario text, p_desde timestamptz, p_hasta timestamptz) returns jsonb
language plpgsql stable as $$
declare
  v_hasta timestamptz := coalesce(p_hasta, 'infinity'::timestamptz);
  v_dia_desde timestamptz := date_trunc('day', p_desde);
  v_dia_hasta timestamptz := case when p_hasta is null then 'infinity'::timestamptz else date_trunc('day', p_hasta) end;
  v_efectivo numeric := 0;
  v_tarjeta numeric := 0;
  v_transferencia numeric := 0;
  v_cheque numeric := 0;
  v_credito numeric := 0;
  v_cantidad integer := 0;
  v_abonos_efectivo numeric := 0;
  v_abonos_otros numeric := 0;
  v_gastos numeric := 0;
  v_pagos_proveedores numeric := 0;
  v_compras_efectivo numeric := 0;
begin
  select
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Efectivo'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Tarjeta'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Transferencia'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Cheque'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Credito'), 0),
    count(*)
  into v_efectivo, v_tarjeta, v_transferencia, v_cheque, v_credito, v_cantidad
  from ventas
  where estado = 'Activa' and tipo_documento <> 'Cotizacion'
    and usuario_registro = p_usuario
    and fecha_registro >= p_desde and fecha_registro <= v_hasta;

  select
    v_efectivo + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Efectivo'), 0),
    v_tarjeta + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Tarjeta'), 0),
    v_transferencia + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Transferencia'), 0),
    v_cheque + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Cheque'), 0)
  into v_efectivo, v_tarjeta, v_transferencia, v_cheque
  from ventas v, jsonb_array_elements(v.pagos_mixtos) e
  where v.estado = 'Activa' and v.tipo_documento <> 'Cotizacion' and v.condicion = 'Contado' and v.metodo_pago = 'Mixto'
    and v.usuario_registro = p_usuario
    and v.fecha_registro >= p_desde and v.fecha_registro <= v_hasta;

  select
    coalesce(sum(monto_abonado) filter (where metodo_pago = 'Efectivo'), 0),
    coalesce(sum(monto_abonado) filter (where metodo_pago <> 'Efectivo'), 0)
  into v_abonos_efectivo, v_abonos_otros
  from venta_credito_abonos
  where usuario = p_usuario
    and (fecha >= p_desde or (fecha = date_trunc('day', fecha) and fecha >= v_dia_desde))
    and (fecha <= v_hasta or (fecha = date_trunc('day', fecha) and fecha <= v_dia_hasta));

  select coalesce(sum(monto), 0) into v_gastos
  from egresos
  where usuario = p_usuario and es_pagado and metodo_pago = 'Efectivo'
    and (coalesce(fecha_pago, fecha) >= p_desde or (coalesce(fecha_pago, fecha) = date_trunc('day', coalesce(fecha_pago, fecha)) and coalesce(fecha_pago, fecha) >= v_dia_desde))
    and (coalesce(fecha_pago, fecha) <= v_hasta or (coalesce(fecha_pago, fecha) = date_trunc('day', coalesce(fecha_pago, fecha)) and coalesce(fecha_pago, fecha) <= v_dia_hasta));

  select coalesce(sum(monto_abonado), 0) into v_pagos_proveedores
  from compra_credito_abonos
  where usuario = p_usuario and metodo_pago = 'Efectivo'
    and (fecha >= p_desde or (fecha = date_trunc('day', fecha) and fecha >= v_dia_desde))
    and (fecha <= v_hasta or (fecha = date_trunc('day', fecha) and fecha <= v_dia_hasta));

  select coalesce(sum(total_a_pagar), 0) into v_compras_efectivo
  from compras
  where estado = 'Activa' and condicion = 'Contado' and metodo_pago = 'Efectivo'
    and usuario_registro = p_usuario
    and fecha_registro >= p_desde and fecha_registro <= v_hasta;

  return jsonb_build_object(
    'ventasEfectivo', v_efectivo,
    'ventasTarjeta', v_tarjeta,
    'ventasTransferencia', v_transferencia,
    'ventasCheque', v_cheque,
    'ventasCredito', v_credito,
    'totalVentas', v_efectivo + v_tarjeta + v_transferencia + v_cheque + v_credito,
    'cantidadVentas', v_cantidad,
    'abonosEfectivo', v_abonos_efectivo,
    'abonosOtros', v_abonos_otros,
    'gastos', v_gastos,
    'pagosProveedores', v_pagos_proveedores,
    'comprasEfectivo', v_compras_efectivo
  );
end;
$$;

create or replace function _caja_a_json(c cajas, p_resumen jsonb) returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'id', c.id,
    'estado', c.estado,
    'usuario', c.usuario,
    'usuarioCierre', c.usuario_cierre,
    'abiertaEn', c.abierta_en,
    'cerradaEn', c.cerrada_en,
    'montoApertura', c.monto_apertura,
    'montoCierre', c.monto_cierre,
    'efectivoEsperado', coalesce(c.efectivo_esperado, c.monto_apertura
      + coalesce((p_resumen->>'ventasEfectivo')::numeric, 0) + coalesce((p_resumen->>'abonosEfectivo')::numeric, 0)
      - coalesce((p_resumen->>'gastos')::numeric, 0) - coalesce((p_resumen->>'pagosProveedores')::numeric, 0)
      - coalesce((p_resumen->>'comprasEfectivo')::numeric, 0)),
    'diferencia', c.diferencia,
    'notas', c.notas,
    'notasCierre', c.notas_cierre
  ) || p_resumen;
$$;

create or replace function resumen_caja(p_id uuid) returns jsonb
language plpgsql stable as $$
declare
  c cajas%rowtype;
  v_resumen jsonb;
begin
  select * into c from cajas where id = p_id;
  if not found then
    raise exception 'La caja no existe';
  end if;
  if c.estado = 'abierta' then
    v_resumen := calcular_resumen_caja(c.usuario, c.abierta_en, null);
  else
    v_resumen := c.resumen;
  end if;
  return _caja_a_json(c, v_resumen);
end;
$$;

create or replace function caja_abierta_de(p_usuario text) returns jsonb
language plpgsql stable as $$
declare
  c cajas%rowtype;
begin
  select * into c from cajas where usuario = p_usuario and estado = 'abierta' order by abierta_en desc limit 1;
  if not found then
    return null;
  end if;
  return _caja_a_json(c, calcular_resumen_caja(c.usuario, c.abierta_en, null));
end;
$$;

create or replace function ultimo_cierre_de(p_usuario text) returns timestamptz
language sql stable as $$
  select max(cerrada_en) from cajas where usuario = p_usuario and estado = 'cerrada';
$$;

create or replace function abrir_caja(p_usuario text, p_monto numeric, p_notas text, p_abierta_en timestamptz) returns jsonb
language plpgsql as $$
declare
  c cajas%rowtype;
begin
  if coalesce(trim(p_usuario), '') = '' then
    raise exception 'Falta el usuario de la caja';
  end if;
  if p_monto < 0 then
    raise exception 'El fondo inicial no puede ser negativo';
  end if;
  if exists (select 1 from cajas where usuario = p_usuario and estado = 'abierta') then
    raise exception 'Ya tenés una caja abierta';
  end if;
  if exists (
    select 1 from cajas
    where usuario = p_usuario and estado = 'cerrada' and cerrada_en > p_abierta_en
  ) then
    raise exception 'Esa fecha se solapa con una caja que ya cerraste';
  end if;
  insert into cajas (usuario, abierta_en, monto_apertura, notas)
  values (p_usuario, p_abierta_en, p_monto, coalesce(p_notas, ''))
  returning * into c;
  return _caja_a_json(c, calcular_resumen_caja(c.usuario, c.abierta_en, null));
end;
$$;

create or replace function cerrar_caja(p_id uuid, p_monto_contado numeric, p_notas text, p_usuario_cierre text, p_cerrada_en timestamptz) returns jsonb
language plpgsql as $$
declare
  c cajas%rowtype;
  v_resumen jsonb;
  v_esperado numeric;
begin
  select * into c from cajas where id = p_id for update;
  if not found then
    raise exception 'La caja no existe';
  end if;
  if c.estado <> 'abierta' then
    raise exception 'Esta caja ya está cerrada';
  end if;
  if p_cerrada_en < c.abierta_en then
    raise exception 'La hora de cierre no puede ser anterior a la apertura';
  end if;
  v_resumen := calcular_resumen_caja(c.usuario, c.abierta_en, p_cerrada_en);
  v_esperado := c.monto_apertura
    + (v_resumen->>'ventasEfectivo')::numeric + (v_resumen->>'abonosEfectivo')::numeric
    - (v_resumen->>'gastos')::numeric - (v_resumen->>'pagosProveedores')::numeric
    - (v_resumen->>'comprasEfectivo')::numeric;
  update cajas set
    estado = 'cerrada',
    cerrada_en = p_cerrada_en,
    monto_cierre = p_monto_contado,
    efectivo_esperado = v_esperado,
    diferencia = round(p_monto_contado - v_esperado, 2),
    notas_cierre = coalesce(p_notas, ''),
    usuario_cierre = coalesce(p_usuario_cierre, ''),
    resumen = v_resumen
  where id = p_id
  returning * into c;
  return _caja_a_json(c, v_resumen);
end;
$$;

create or replace function reabrir_caja(p_id uuid) returns jsonb
language plpgsql as $$
declare
  c cajas%rowtype;
begin
  select * into c from cajas where id = p_id for update;
  if not found then
    raise exception 'La caja no existe';
  end if;
  if c.estado <> 'cerrada' then
    raise exception 'Esta caja ya está abierta';
  end if;
  if exists (select 1 from cajas where usuario = c.usuario and estado = 'abierta') then
    raise exception 'Ya hay otra caja abierta para este usuario; ciérrela primero';
  end if;
  if exists (select 1 from cajas where usuario = c.usuario and estado = 'cerrada' and id <> c.id and abierta_en >= c.cerrada_en) then
    raise exception 'Solo se puede reabrir la última caja cerrada';
  end if;
  update cajas set
    estado = 'abierta', cerrada_en = null, monto_cierre = null, efectivo_esperado = null,
    diferencia = 0, notas_cierre = '', usuario_cierre = '', resumen = '{}'::jsonb
  where id = p_id
  returning * into c;
  return _caja_a_json(c, calcular_resumen_caja(c.usuario, c.abierta_en, null));
end;
$$;

create or replace function historial_cajas(p_desde timestamptz, p_hasta timestamptz, p_usuario text default null) returns setof jsonb
language plpgsql stable as $$
declare
  c cajas%rowtype;
begin
  for c in
    select * from cajas
    where abierta_en >= p_desde and abierta_en <= p_hasta
      and (p_usuario is null or usuario = p_usuario)
    order by abierta_en desc
    limit 1000
  loop
    if c.estado = 'abierta' then
      return next _caja_a_json(c, calcular_resumen_caja(c.usuario, c.abierta_en, null));
    else
      return next _caja_a_json(c, c.resumen);
    end if;
  end loop;
end;
$$;

create or replace function efectivo_estimado_cajas() returns numeric
language plpgsql stable as $$
declare
  c cajas%rowtype;
  v_total numeric := 0;
  v_json jsonb;
begin
  for c in select * from cajas where estado = 'abierta' loop
    v_json := _caja_a_json(c, calcular_resumen_caja(c.usuario, c.abierta_en, null));
    v_total := v_total + (v_json->>'efectivoEsperado')::numeric;
  end loop;
  return v_total;
end;
$$;

revoke all on cajas from anon;
grant all on cajas to authenticated;
revoke execute on function calcular_resumen_caja(text, timestamptz, timestamptz), _caja_a_json(cajas, jsonb), resumen_caja(uuid), caja_abierta_de(text), ultimo_cierre_de(text), abrir_caja(text, numeric, text, timestamptz), cerrar_caja(uuid, numeric, text, text, timestamptz), reabrir_caja(uuid), historial_cajas(timestamptz, timestamptz, text), efectivo_estimado_cajas() from public, anon;
grant execute on function calcular_resumen_caja(text, timestamptz, timestamptz), _caja_a_json(cajas, jsonb), resumen_caja(uuid), caja_abierta_de(text), ultimo_cierre_de(text), abrir_caja(text, numeric, text, timestamptz), cerrar_caja(uuid, numeric, text, text, timestamptz), reabrir_caja(uuid), historial_cajas(timestamptz, timestamptz, text), efectivo_estimado_cajas() to authenticated;
