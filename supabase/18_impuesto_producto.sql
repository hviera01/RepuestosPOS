alter table productos add column if not exists impuesto_porcentaje numeric(5,2) not null default 15;
