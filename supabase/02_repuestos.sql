create or replace function tg_touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists eliminados (
  id bigserial primary key,
  tabla text not null,
  id_fila text not null,
  eliminado_en timestamptz not null default now()
);
create index if not exists idx_eliminados_tabla_fecha on eliminados (tabla, eliminado_en);

create or replace function tg_registrar_eliminado() returns trigger
language plpgsql as $$
begin
  insert into eliminados (tabla, id_fila) values (tg_table_name, old.id::text);
  return old;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['productos', 'clientes', 'proveedores', 'categorias', 'promociones', 'negocio_config']
  loop
    execute format('alter table %I add column if not exists updated_at timestamptz not null default now()', t);
    execute format('create index if not exists idx_%s_updated_at on %I (updated_at)', t, t);
    execute format('drop trigger if exists tg_%s_touch on %I', t, t);
    execute format('create trigger tg_%s_touch before insert or update on %I for each row execute function tg_touch_updated_at()', t, t);
  end loop;
  foreach t in array array['productos', 'clientes', 'proveedores', 'categorias', 'promociones']
  loop
    execute format('drop trigger if exists tg_%s_eliminado on %I', t, t);
    execute format('create trigger tg_%s_eliminado after delete on %I for each row execute function tg_registrar_eliminado()', t, t);
  end loop;
end $$;

create table if not exists operaciones_aplicadas (
  op_id uuid primary key,
  funcion text not null,
  resultado jsonb,
  creado_en timestamptz not null default now()
);
create index if not exists idx_operaciones_aplicadas_creado_en on operaciones_aplicadas (creado_en);

alter table negocio_config add column if not exists tema jsonb not null default '{}'::jsonb;
alter table negocio_config add column if not exists tipo_documento_defecto text not null default 'Factura'
  check (tipo_documento_defecto in ('Factura', 'VentaSinFacturar'));

alter table productos add column if not exists nombre_base text not null default '';
alter table productos add column if not exists nombre_automatico boolean not null default false;
alter table productos add column if not exists compatibilidad jsonb not null default '[]'::jsonb;
create index if not exists idx_productos_compatibilidad on productos using gin (compatibilidad jsonb_path_ops);

create table sucursales (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  direccion text not null default '',
  estado boolean not null default true,
  fecha_registro timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_sucursales_nombre on sucursales (nombre);
create trigger tg_sucursales_touch before insert or update on sucursales for each row execute function tg_touch_updated_at();
create trigger tg_sucursales_eliminado after delete on sucursales for each row execute function tg_registrar_eliminado();

create table traslados (
  id uuid primary key default gen_random_uuid(),
  numero text not null,
  id_sucursal_origen uuid references sucursales (id) on delete restrict,
  nombre_sucursal_origen text not null default '',
  id_sucursal_destino uuid references sucursales (id) on delete restrict,
  nombre_sucursal_destino text not null default '',
  fecha timestamptz not null default now(),
  estado text not null default 'Pendiente' check (estado in ('Pendiente', 'Enviado', 'Entregado', 'Anulado')),
  observaciones text not null default '',
  usuario_crea text not null default '',
  usuario_recibe text not null default '',
  fecha_recepcion timestamptz,
  solicitud_impresion_en_vivo boolean not null default false,
  solicitud_impresion_es_copia boolean,
  total_items numeric(14, 3) not null default 0
);
create unique index uq_traslados_numero on traslados (numero);
create index idx_traslados_fecha on traslados (fecha desc);
create index idx_traslados_estado_fecha on traslados (estado, fecha desc);
create index idx_traslados_origen on traslados (id_sucursal_origen);
create index idx_traslados_destino on traslados (id_sucursal_destino);
create index idx_traslados_impresion on traslados (id) where solicitud_impresion_en_vivo;

create table traslado_items (
  id uuid primary key default gen_random_uuid(),
  id_traslado uuid not null references traslados (id) on delete cascade,
  id_producto uuid references productos (id) on delete restrict,
  nombre_producto text not null,
  cantidad numeric(14, 3) not null,
  ubicacion text not null default '',
  costo_unitario numeric(12, 2) not null default 0,
  orden integer not null default 0
);
create index idx_traslado_items_id_traslado on traslado_items (id_traslado);
create index idx_traslado_items_id_producto on traslado_items (id_producto);

create table producto_historial_traslados (
  id uuid primary key default gen_random_uuid(),
  id_producto uuid not null references productos (id) on delete cascade,
  id_traslado uuid not null references traslados (id) on delete cascade,
  numero text not null,
  cantidad numeric(14, 3) not null,
  sucursal_origen text not null default '',
  sucursal_destino text not null default '',
  usuario text not null default '',
  fecha timestamptz not null default now()
);
create index idx_producto_hist_traslados_producto on producto_historial_traslados (id_producto, fecha desc);

do $$
declare
  t text;
begin
  foreach t in array array['eliminados', 'operaciones_aplicadas', 'sucursales', 'traslados', 'traslado_items', 'producto_historial_traslados']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all using (true) with check (true)', t || '_allow_all_anon', t);
  end loop;
end $$;

alter publication supabase_realtime add table sucursales, traslados, eliminados, clientes, proveedores, categorias, promociones;

create or replace function registrar_traslado(payload jsonb) returns jsonb
language plpgsql as $$
declare
  v_id uuid := coalesce(nullif(payload->>'id', '')::uuid, gen_random_uuid());
  v_origen uuid := (payload->>'idSucursalOrigen')::uuid;
  v_destino uuid := (payload->>'idSucursalDestino')::uuid;
  v_nombre_origen text := coalesce(payload->>'nombreSucursalOrigen', '');
  v_nombre_destino text := coalesce(payload->>'nombreSucursalDestino', '');
  v_estado text := coalesce(nullif(payload->>'estadoInicial', ''), 'Pendiente');
  v_usuario text := coalesce(payload->>'usuarioCrea', '');
  v_usuario_recibe text := coalesce(payload->>'usuarioRecibe', '');
  v_numero integer;
  v_numero_txt text;
  v_total numeric := 0;
  v_cantidades jsonb := '{}'::jsonb;
  v_costos jsonb := '{}'::jsonb;
  v_id_txt text;
  v_cantidad numeric;
  v_stock_actual numeric;
  v_stock_nuevo numeric;
  v_precio_compra numeric;
  v_costo numeric;
  v_idx integer := 0;
  item jsonb;
begin
  if v_origen = v_destino then
    raise exception 'La sucursal origen y destino no pueden ser la misma';
  end if;
  if payload->'items' is null or jsonb_array_length(payload->'items') = 0 then
    raise exception 'Agregá al menos un producto';
  end if;
  if v_estado not in ('Pendiente', 'Enviado', 'Entregado') then
    raise exception 'Estado inicial inválido';
  end if;

  v_numero := incrementar_contador('traslado');
  v_numero_txt := 'TRAS-' || lpad(v_numero::text, 6, '0');

  for item in select * from jsonb_array_elements(payload->'items') loop
    v_id_txt := item->>'idProducto';
    v_cantidad := (item->>'cantidad')::numeric;
    v_total := v_total + v_cantidad;
    v_cantidades := jsonb_set(v_cantidades, array[v_id_txt], to_jsonb(coalesce((v_cantidades->>v_id_txt)::numeric, 0) + v_cantidad));
  end loop;

  insert into traslados (
    id, numero, id_sucursal_origen, nombre_sucursal_origen, id_sucursal_destino, nombre_sucursal_destino,
    fecha, estado, observaciones, usuario_crea, usuario_recibe, fecha_recepcion, total_items
  ) values (
    v_id, v_numero_txt, v_origen, v_nombre_origen, v_destino, v_nombre_destino,
    now(), v_estado, coalesce(payload->>'observaciones', ''), v_usuario,
    case when v_estado = 'Entregado' then v_usuario_recibe else '' end,
    case when v_estado = 'Entregado' then now() end, v_total
  );

  for v_id_txt in select k from jsonb_object_keys(v_cantidades) k order by k loop
    v_cantidad := (v_cantidades->>v_id_txt)::numeric;
    select stock, precio_compra into v_stock_actual, v_precio_compra from productos where id = v_id_txt::uuid for update;
    if not found then raise exception 'Un producto del traslado ya no existe'; end if;
    v_costo := consumir_fifo_lotes(v_id_txt::uuid, v_cantidad, coalesce(v_precio_compra, 0));
    v_costos := jsonb_set(v_costos, array[v_id_txt], to_jsonb(v_costo));
    v_stock_nuevo := greatest(coalesce(v_stock_actual, 0) - v_cantidad, 0);
    update productos set stock = v_stock_nuevo where id = v_id_txt::uuid;
    insert into producto_historial_stock (id_producto, stock_anterior, stock_nuevo, usuario, motivo, fecha)
    values (v_id_txt::uuid, coalesce(v_stock_actual, 0), v_stock_nuevo, v_usuario, 'Traslado ' || v_numero_txt || ' a ' || v_nombre_destino, now());
    insert into producto_historial_traslados (id_producto, id_traslado, numero, cantidad, sucursal_origen, sucursal_destino, usuario)
    values (v_id_txt::uuid, v_id, v_numero_txt, v_cantidad, v_nombre_origen, v_nombre_destino, v_usuario);
    perform sincronizar_precio_compra_activo(v_id_txt::uuid);
  end loop;

  for item in select * from jsonb_array_elements(payload->'items') loop
    insert into traslado_items (id_traslado, id_producto, nombre_producto, cantidad, ubicacion, costo_unitario, orden)
    values (
      v_id, (item->>'idProducto')::uuid, item->>'nombreProducto', (item->>'cantidad')::numeric,
      coalesce(item->>'ubicacion', ''), coalesce((v_costos->>(item->>'idProducto'))::numeric, 0), v_idx
    );
    v_idx := v_idx + 1;
  end loop;

  return jsonb_build_object('id', v_id, 'numero', v_numero_txt);
end;
$$;

create or replace function enviar_traslado(p_id uuid) returns void
language plpgsql as $$
declare
  v_estado text;
begin
  select estado into v_estado from traslados where id = p_id for update;
  if v_estado is distinct from 'Pendiente' then
    raise exception 'Solo se puede enviar un traslado que está Pendiente';
  end if;
  update traslados set estado = 'Enviado' where id = p_id;
end;
$$;

create or replace function recepcionar_traslado(p_id uuid, p_usuario text) returns void
language plpgsql as $$
declare
  v_estado text;
begin
  select estado into v_estado from traslados where id = p_id for update;
  if v_estado is distinct from 'Enviado' then
    raise exception 'Solo se puede recibir un traslado que está Enviado';
  end if;
  update traslados set estado = 'Entregado', usuario_recibe = p_usuario, fecha_recepcion = now() where id = p_id;
end;
$$;

create or replace function anular_traslado(p_id uuid, p_usuario text) returns void
language plpgsql as $$
declare
  v_estado text;
  v_numero text;
  rec record;
  v_stock_actual numeric;
  v_stock_nuevo numeric;
begin
  select estado, numero into v_estado, v_numero from traslados where id = p_id for update;
  if not found then raise exception 'El traslado no existe'; end if;
  if v_estado = 'Anulado' then raise exception 'Este traslado ya está anulado'; end if;
  update traslados set estado = 'Anulado' where id = p_id;
  for rec in
    select id_producto, sum(cantidad) as cantidad, sum(cantidad * costo_unitario) / nullif(sum(cantidad), 0) as costo
    from traslado_items where id_traslado = p_id and id_producto is not null
    group by id_producto order by id_producto
  loop
    select stock into v_stock_actual from productos where id = rec.id_producto for update;
    v_stock_nuevo := coalesce(v_stock_actual, 0) + rec.cantidad;
    update productos set stock = v_stock_nuevo where id = rec.id_producto;
    insert into producto_historial_stock (id_producto, stock_anterior, stock_nuevo, usuario, motivo, fecha)
    values (rec.id_producto, coalesce(v_stock_actual, 0), v_stock_nuevo, p_usuario, 'Anulación de traslado ' || v_numero, now());
    insert into producto_lotes_costo (id_producto, cantidad_original, cantidad_restante, costo_unitario, fecha, origen)
    values (rec.id_producto, rec.cantidad, rec.cantidad, coalesce(rec.costo, 0), now(), 'ajuste');
    perform sincronizar_precio_compra_activo(rec.id_producto);
  end loop;
end;
$$;

create or replace function marcar_solicitud_impresion_traslado(p_id uuid, p_valor boolean, p_es_copia boolean default null) returns void
language sql as $$
  update traslados set solicitud_impresion_en_vivo = p_valor, solicitud_impresion_es_copia = p_es_copia where id = p_id;
$$;
