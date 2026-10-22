create or replace function tg_limpiar_eliminado() returns trigger
language plpgsql as $$
begin
  delete from eliminados where tabla = tg_table_name and id_fila::text = new.id::text;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['categorias', 'clientes', 'compras_credito', 'productos', 'promociones', 'proveedores', 'sucursales', 'ventas_credito', 'cierres_caja']
  loop
    execute format('update %I set updated_at = now() where id::text in (select id_fila::text from eliminados where tabla = %L)', t, t);
    execute format('delete from eliminados where tabla = %L and id_fila::text in (select id::text from %I)', t, t);
    execute format('drop trigger if exists tg_%s_limpiar_eliminado on %I', t, t);
    execute format('create trigger tg_%s_limpiar_eliminado after insert on %I for each row execute function tg_limpiar_eliminado()', t, t);
  end loop;
end $$;

revoke execute on function tg_limpiar_eliminado() from public, anon, authenticated;
