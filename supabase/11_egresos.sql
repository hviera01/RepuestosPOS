create table if not exists egreso_categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  estado boolean not null default true,
  fecha_registro timestamptz not null default now()
);

alter table egreso_categorias enable row level security;
drop policy if exists egreso_categorias_allow_all_anon on egreso_categorias;
create policy egreso_categorias_allow_all_anon on egreso_categorias for all using (true) with check (true);
revoke all on egreso_categorias from anon;
grant all on egreso_categorias to authenticated;

insert into egreso_categorias (nombre) values
  ('Alquiler'), ('Servicios básicos'), ('Planilla y salarios'), ('Transporte y fletes'), ('Alimentación del personal'),
  ('Mantenimiento y reparaciones'), ('Insumos y papelería'), ('Publicidad'), ('Impuestos y tasas'), ('Otros gastos')
on conflict (nombre) do nothing;

alter table egresos add column if not exists beneficiario text not null default '';
alter table egresos add column if not exists comprobante text not null default '';

update egresos set categoria = case
  when descripcion ilike 'ALQUILER%' then 'Alquiler'
  when descripcion ilike 'ENERGIA%' or descripcion ilike 'AGUA%' or descripcion ilike 'INTERNET%' or descripcion ilike 'RECARGA%' then 'Servicios básicos'
  when descripcion ilike 'PLANILLA%' then 'Planilla y salarios'
  when descripcion ilike 'COMBUSTIBLE%' or descripcion ilike 'FLETE%' or descripcion ilike 'MENSAJERIA%' then 'Transporte y fletes'
  when descripcion ilike 'ALMUERZO%' then 'Alimentación del personal'
  when descripcion ilike 'REPARACION%' then 'Mantenimiento y reparaciones'
  when descripcion ilike 'BOLSAS%' or descripcion ilike 'ARTICULOS%' then 'Insumos y papelería'
  else 'Otros gastos' end
where categoria in ('Negocio', 'Casa');

alter publication supabase_realtime add table egreso_categorias;
