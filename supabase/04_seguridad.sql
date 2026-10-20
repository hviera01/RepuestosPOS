create schema if not exists extensions;

create table if not exists app_secretos (
  clave text primary key,
  valor text not null
);
alter table app_secretos enable row level security;
revoke all on app_secretos from anon, authenticated;

create table if not exists usuarios_credenciales (
  id_usuario uuid primary key references usuarios (id) on delete cascade,
  clave text not null,
  sal text not null default ''
);
alter table usuarios_credenciales enable row level security;
revoke all on usuarios_credenciales from anon, authenticated;

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'usuarios' and column_name = 'clave') then
    insert into usuarios_credenciales (id_usuario, clave, sal)
    select id, clave, coalesce(sal, '') from usuarios
    on conflict (id_usuario) do nothing;
    alter table usuarios drop column clave;
    alter table usuarios drop column sal;
  end if;
end $$;

alter table negocio_config add column if not exists tiene_clave_especial boolean not null default false;
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'negocio_config' and column_name = 'clave_especial_hash') then
    insert into app_secretos (clave, valor)
    select 'clave_especial', clave_especial_hash from negocio_config where id = 1 and clave_especial_hash <> ''
    on conflict (clave) do nothing;
    update negocio_config set tiene_clave_especial = (clave_especial_hash <> '');
    alter table negocio_config drop column clave_especial_hash;
  end if;
end $$;

create or replace function base64url(p_bytes bytea) returns text
language sql immutable as $$
  select translate(replace(rtrim(encode(p_bytes, 'base64'), '='), E'\n', ''), '+/', '-_');
$$;

create or replace function firmar_sesion(p_id uuid, p_rol text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_secreto text;
  v_exp bigint := extract(epoch from now() + interval '24 hours')::bigint;
  v_cabecera text := base64url(convert_to('{"alg":"HS256","typ":"JWT"}', 'utf8'));
  v_cuerpo text;
  v_firma text;
begin
  select valor into v_secreto from app_secretos where clave = 'jwt_secret';
  if v_secreto is null then
    raise exception 'Falta configurar el secreto de sesión';
  end if;
  v_cuerpo := base64url(convert_to(jsonb_build_object(
    'aud', 'authenticated',
    'role', 'authenticated',
    'sub', p_id,
    'iss', 'supabase',
    'iat', extract(epoch from now())::bigint,
    'exp', v_exp,
    'app_metadata', jsonb_build_object('rol', p_rol)
  )::text, 'utf8'));
  v_firma := base64url(hmac(convert_to(v_cabecera || '.' || v_cuerpo, 'utf8'), convert_to(v_secreto, 'utf8'), 'sha256'));
  return jsonb_build_object('token', v_cabecera || '.' || v_cuerpo || '.' || v_firma, 'expira', v_exp);
end;
$$;

create or replace function iniciar_sesion(p_documento text, p_clave text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  u usuarios%rowtype;
  c usuarios_credenciales%rowtype;
  v_coincide boolean;
  v_intentos integer;
  v_nueva_sal text;
  v_sesion jsonb;
begin
  select * into u from usuarios where documento = p_documento;
  if not found then
    return jsonb_build_object('error', 'Código de acceso no encontrado');
  end if;
  if not u.estado then
    return jsonb_build_object('error', 'Usuario inactivo, contacte al administrador');
  end if;
  if u.bloqueado_hasta is not null and u.bloqueado_hasta > now() then
    return jsonb_build_object('error', 'Demasiados intentos fallidos, espere ' || (ceil(extract(epoch from (u.bloqueado_hasta - now())) / 60))::int || ' minuto(s) e intente de nuevo');
  end if;
  select * into c from usuarios_credenciales where id_usuario = u.id;
  if not found then
    return jsonb_build_object('error', 'Contraseña incorrecta');
  end if;

  if c.sal <> '' then
    v_coincide := c.clave = encode(digest(c.sal || ':' || p_clave, 'sha256'), 'hex');
  else
    v_coincide := c.clave = encode(digest(p_clave, 'sha256'), 'hex');
    if v_coincide then
      v_nueva_sal := translate(replace(rtrim(encode(gen_random_bytes(16), 'base64'), '='), E'\n', ''), '+/', '-_');
      update usuarios_credenciales
      set sal = v_nueva_sal, clave = encode(digest(v_nueva_sal || ':' || p_clave, 'sha256'), 'hex')
      where id_usuario = u.id;
    end if;
  end if;

  if not v_coincide then
    v_intentos := u.intentos_fallidos + 1;
    if v_intentos >= 5 then
      update usuarios set intentos_fallidos = 0, bloqueado_hasta = now() + interval '5 minutes' where id = u.id;
    else
      update usuarios set intentos_fallidos = v_intentos where id = u.id;
    end if;
    return jsonb_build_object('error', 'Contraseña incorrecta');
  end if;

  if u.intentos_fallidos <> 0 or u.bloqueado_hasta is not null then
    update usuarios set intentos_fallidos = 0, bloqueado_hasta = null where id = u.id;
  end if;

  v_sesion := firmar_sesion(u.id, u.rol);
  return jsonb_build_object(
    'usuario', to_jsonb(u),
    'token', v_sesion->>'token',
    'expira', (v_sesion->>'expira')::bigint
  );
end;
$$;

create or replace function renovar_sesion() returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  u usuarios%rowtype;
begin
  select * into u from usuarios where id = nullif(auth.jwt()->>'sub', '')::uuid;
  if not found or not u.estado then
    return jsonb_build_object('error', 'Sesión no válida');
  end if;
  return firmar_sesion(u.id, u.rol);
end;
$$;

create or replace function es_administrador() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from usuarios
    where id = nullif(auth.jwt()->>'sub', '')::uuid and rol = 'Administrador' and estado
  );
$$;

create or replace function guardar_credencial(p_id uuid, p_clave text, p_sal text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not es_administrador() then
    raise exception 'Solo un administrador puede cambiar claves';
  end if;
  insert into usuarios_credenciales (id_usuario, clave, sal) values (p_id, p_clave, p_sal)
  on conflict (id_usuario) do update set clave = excluded.clave, sal = excluded.sal;
  update usuarios set intentos_fallidos = 0, bloqueado_hasta = null where id = p_id;
end;
$$;

create or replace function crear_usuario_con_clave(p_datos jsonb, p_clave text, p_sal text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if not es_administrador() then
    raise exception 'Solo un administrador puede crear usuarios';
  end if;
  if exists (select 1 from usuarios where documento = p_datos->>'documento') then
    raise exception 'El número de documento ya existe';
  end if;
  insert into usuarios (documento, nombre_completo, correo, rol, estado, pantallas_permitidas, acciones_permitidas)
  values (
    p_datos->>'documento', p_datos->>'nombre_completo', coalesce(p_datos->>'correo', ''), p_datos->>'rol',
    coalesce((p_datos->>'estado')::boolean, true),
    coalesce(p_datos->'pantallas_permitidas', '{}'::jsonb), coalesce(p_datos->'acciones_permitidas', '{}'::jsonb)
  ) returning id into v_id;
  insert into usuarios_credenciales (id_usuario, clave, sal) values (v_id, p_clave, p_sal);
  return v_id;
end;
$$;

create or replace function establecer_clave_especial(p_hash text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not es_administrador() then
    raise exception 'Solo un administrador puede cambiar la clave especial';
  end if;
  if coalesce(p_hash, '') = '' then
    delete from app_secretos where clave = 'clave_especial';
  else
    insert into app_secretos (clave, valor) values ('clave_especial', p_hash)
    on conflict (clave) do update set valor = excluded.valor;
  end if;
  update negocio_config set tiene_clave_especial = (coalesce(p_hash, '') <> '') where id = 1;
end;
$$;

create or replace function verificar_clave_especial(p_hash text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_secretos where clave = 'clave_especial' and valor = p_hash);
$$;

create or replace function crear_usuario_inicial(p_documento text, p_nombre text, p_clave text) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_id uuid;
  v_sal text := translate(replace(rtrim(encode(gen_random_bytes(16), 'base64'), '='), E'\n', ''), '+/', '-_');
begin
  insert into usuarios (documento, nombre_completo, rol, estado) values (p_documento, p_nombre, 'Administrador', true)
  on conflict (documento) do update set rol = 'Administrador', estado = true
  returning id into v_id;
  insert into usuarios_credenciales (id_usuario, clave, sal)
  values (v_id, encode(digest(v_sal || ':' || p_clave, 'sha256'), 'hex'), v_sal)
  on conflict (id_usuario) do update set clave = excluded.clave, sal = excluded.sal;
  return v_id;
end;
$$;

revoke all on all tables in schema public from anon;
grant all on all tables in schema public to authenticated;
revoke all on app_secretos, usuarios_credenciales from authenticated;
grant usage on all sequences in schema public to authenticated;

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on all functions in schema public to authenticated;
revoke execute on function firmar_sesion(uuid, text), crear_usuario_inicial(text, text, text), base64url(bytea) from authenticated;
revoke execute on function tg_touch_updated_at(), tg_registrar_eliminado() from authenticated;
grant execute on function iniciar_sesion(text, text) to anon;

grant select, insert, update, delete on escaneos_remotos, escaneo_remoto_eventos to anon;

alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke execute on functions from public, anon;
