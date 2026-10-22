create table if not exists impresiones_remotas (
  id uuid primary key default gen_random_uuid(),
  descripcion text not null default '',
  datos text not null,
  creado timestamptz not null default now()
);

alter table impresiones_remotas enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'impresiones_remotas' and policyname = 'impresiones_remotas_all') then
    create policy impresiones_remotas_all on impresiones_remotas for all using (true) with check (true);
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'impresiones_remotas') then
    alter publication supabase_realtime add table impresiones_remotas;
  end if;
end $$;
grant all on impresiones_remotas to anon, authenticated;
