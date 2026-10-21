alter table cajas add column if not exists hasta_en timestamptz;
alter table cajas add column if not exists apertura_real timestamptz;
alter table cajas add column if not exists config jsonb not null default '{}'::jsonb;

create or replace function _config_caja(p jsonb) returns jsonb
language sql immutable as $$
  select jsonb_build_object(
    'soloDesdeApertura', coalesce((p->>'soloDesdeApertura')::boolean, false),
    'ventasEfectivo', coalesce((p->>'ventasEfectivo')::boolean, true),
    'abonosEfectivo', coalesce((p->>'abonosEfectivo')::boolean, true),
    'gastos', coalesce((p->>'gastos')::boolean, true),
    'pagosProveedores', coalesce((p->>'pagosProveedores')::boolean, true),
    'comprasEfectivo', coalesce((p->>'comprasEfectivo')::boolean, true)
  );
$$;

create or replace function _efectivo_esperado(p_fondo numeric, p_resumen jsonb, p_config jsonb) returns numeric
language sql immutable as $$
  select round(
    p_fondo
    + case when (_config_caja(p_config)->>'ventasEfectivo')::boolean then coalesce((p_resumen->>'ventasEfectivo')::numeric, 0) else 0 end
    + case when (_config_caja(p_config)->>'abonosEfectivo')::boolean then coalesce((p_resumen->>'abonosEfectivo')::numeric, 0) else 0 end
    - case when (_config_caja(p_config)->>'gastos')::boolean then coalesce((p_resumen->>'gastos')::numeric, 0) else 0 end
    - case when (_config_caja(p_config)->>'pagosProveedores')::boolean then coalesce((p_resumen->>'pagosProveedores')::numeric, 0) else 0 end
    - case when (_config_caja(p_config)->>'comprasEfectivo')::boolean then coalesce((p_resumen->>'comprasEfectivo')::numeric, 0) else 0 end
  , 2);
$$;

create or replace function _caja_a_json(c cajas, p_resumen jsonb) returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'id', c.id,
    'estado', c.estado,
    'usuario', c.usuario,
    'usuarioCierre', c.usuario_cierre,
    'abiertaEn', c.abierta_en,
    'hastaEn', c.hasta_en,
    'aperturaReal', coalesce(c.apertura_real, c.abierta_en),
    'cerradaEn', c.cerrada_en,
    'montoApertura', c.monto_apertura,
    'montoCierre', c.monto_cierre,
    'efectivoEsperado', coalesce(c.efectivo_esperado, _efectivo_esperado(c.monto_apertura, p_resumen, c.config)),
    'diferencia', c.diferencia,
    'notas', c.notas,
    'notasCierre', c.notas_cierre,
    'config', _config_caja(c.config)
  ) || p_resumen;
$$;

create or replace function _resumen_caja_abierta(c cajas) returns jsonb
language plpgsql stable as $$
declare
  v_desde timestamptz;
begin
  v_desde := case when (_config_caja(c.config)->>'soloDesdeApertura')::boolean
    then greatest(c.abierta_en, coalesce(c.apertura_real, c.abierta_en)) else c.abierta_en end;
  return calcular_resumen_caja(c.usuario, v_desde, c.hasta_en);
end;
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
    v_resumen := _resumen_caja_abierta(c);
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
  return _caja_a_json(c, _resumen_caja_abierta(c));
end;
$$;

drop function if exists abrir_caja(text, numeric, text, timestamptz);

create or replace function abrir_caja(
  p_usuario text,
  p_monto numeric,
  p_notas text,
  p_abierta_en timestamptz,
  p_hasta_en timestamptz default null,
  p_apertura_real timestamptz default null,
  p_config jsonb default '{}'::jsonb
) returns jsonb
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
  if p_hasta_en is not null and p_hasta_en < p_abierta_en then
    raise exception 'La fecha final no puede ser anterior a la inicial';
  end if;
  if exists (select 1 from cajas where usuario = p_usuario and estado = 'abierta') then
    raise exception 'Ya tienes una caja abierta';
  end if;
  insert into cajas (usuario, abierta_en, hasta_en, apertura_real, monto_apertura, notas, config)
  values (p_usuario, p_abierta_en, p_hasta_en, coalesce(p_apertura_real, p_abierta_en), p_monto, coalesce(p_notas, ''), _config_caja(p_config))
  returning * into c;
  return _caja_a_json(c, _resumen_caja_abierta(c));
end;
$$;

create or replace function editar_caja(
  p_id uuid,
  p_monto numeric,
  p_abierta_en timestamptz,
  p_hasta_en timestamptz,
  p_notas text,
  p_config jsonb
) returns jsonb
language plpgsql as $$
declare
  c cajas%rowtype;
begin
  select * into c from cajas where id = p_id for update;
  if not found then
    raise exception 'La caja no existe';
  end if;
  if c.estado <> 'abierta' then
    raise exception 'Solo se puede editar una caja abierta';
  end if;
  if p_monto < 0 then
    raise exception 'El fondo inicial no puede ser negativo';
  end if;
  if p_hasta_en is not null and p_hasta_en < p_abierta_en then
    raise exception 'La fecha final no puede ser anterior a la inicial';
  end if;
  update cajas set
    monto_apertura = p_monto,
    abierta_en = p_abierta_en,
    hasta_en = p_hasta_en,
    notas = coalesce(p_notas, ''),
    config = _config_caja(p_config)
  where id = p_id
  returning * into c;
  return _caja_a_json(c, _resumen_caja_abierta(c));
end;
$$;

create or replace function cerrar_caja(p_id uuid, p_monto_contado numeric, p_notas text, p_usuario_cierre text, p_cerrada_en timestamptz) returns jsonb
language plpgsql as $$
declare
  c cajas%rowtype;
  v_resumen jsonb;
  v_esperado numeric;
  v_desde timestamptz;
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
  v_desde := case when (_config_caja(c.config)->>'soloDesdeApertura')::boolean
    then greatest(c.abierta_en, coalesce(c.apertura_real, c.abierta_en)) else c.abierta_en end;
  v_resumen := calcular_resumen_caja(c.usuario, v_desde, coalesce(c.hasta_en, p_cerrada_en));
  v_esperado := _efectivo_esperado(c.monto_apertura, v_resumen, c.config);
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
  return _caja_a_json(c, _resumen_caja_abierta(c));
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
      return next _caja_a_json(c, _resumen_caja_abierta(c));
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
begin
  for c in select * from cajas where estado = 'abierta' loop
    v_total := v_total + _efectivo_esperado(c.monto_apertura, _resumen_caja_abierta(c), c.config);
  end loop;
  return v_total;
end;
$$;

grant execute on all functions in schema public to authenticated;
revoke execute on function firmar_sesion(uuid, text), crear_usuario_inicial(text, text, text), base64url(bytea) from authenticated;
revoke execute on function tg_touch_updated_at(), tg_registrar_eliminado() from authenticated;
