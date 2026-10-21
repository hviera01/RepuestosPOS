alter table productos add column if not exists ubicacion text not null default '';
update productos p set ubicacion = 'PASILLO ' || (1 + abs(hashtext(p.id_categoria::text)) % 6) || ' - ESTANTE ' || chr(65 + abs(hashtext(p.id::text)) % 5) || ' - NIVEL ' || (1 + abs(hashtext(p.codigo)) % 4)
where p.ubicacion = '' and exists (select 1 from ventas limit 1);
