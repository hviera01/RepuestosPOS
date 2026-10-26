-- Agregar campos marca y origen a la tabla productos
alter table productos add column if not exists marca text not null default '';
alter table productos add column if not exists origen text not null default '';

create index if not exists idx_productos_marca on productos (marca);
create index if not exists idx_productos_origen on productos (origen);
