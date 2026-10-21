alter table negocio_config add column if not exists logo_en_ticket boolean not null default true;
alter table negocio_config add column if not exists logo_en_pdf boolean not null default true;
