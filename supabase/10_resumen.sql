create or replace function resumen_operaciones(p_desde timestamptz, p_hasta timestamptz, p_usuario text default null) returns jsonb
language plpgsql stable as $$
declare
  v_ventas jsonb;
  v_tipos jsonb;
  v_metodos jsonb;
  v_anuladas jsonb;
  v_cotizaciones jsonb;
  v_abonos_c jsonb;
  v_compras jsonb;
  v_abonos_p jsonb;
  v_egresos jsonb;
  v_categorias jsonb;
  v_traslados jsonb;
  v_usuarios jsonb;
  v_horas jsonb;
  v_productos jsonb;
  v_clientes jsonb;
  v_operaciones jsonb;
  v_ef_ventas numeric := 0;
  v_ef_abonos numeric := 0;
  v_ef_gastos numeric := 0;
  v_ef_pagos numeric := 0;
  v_ef_compras numeric := 0;
  v_efectivo numeric := 0;
  v_tarjeta numeric := 0;
  v_transf numeric := 0;
  v_cheque numeric := 0;
  v_credito numeric := 0;
begin
  select
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Efectivo'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Tarjeta'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Transferencia'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Contado' and metodo_pago = 'Cheque'), 0),
    coalesce(sum(total_a_pagar) filter (where condicion = 'Credito'), 0)
  into v_efectivo, v_tarjeta, v_transf, v_cheque, v_credito
  from ventas
  where estado = 'Activa' and tipo_documento <> 'Cotizacion'
    and fecha_registro >= p_desde and fecha_registro <= p_hasta
    and (p_usuario is null or usuario_registro = p_usuario);

  select
    v_efectivo + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Efectivo'), 0),
    v_tarjeta + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Tarjeta'), 0),
    v_transf + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Transferencia'), 0),
    v_cheque + coalesce(sum((e->>'monto')::numeric) filter (where e->>'metodoPago' = 'Cheque'), 0)
  into v_efectivo, v_tarjeta, v_transf, v_cheque
  from ventas v, jsonb_array_elements(v.pagos_mixtos) e
  where v.estado = 'Activa' and v.tipo_documento <> 'Cotizacion' and v.condicion = 'Contado' and v.metodo_pago = 'Mixto'
    and v.fecha_registro >= p_desde and v.fecha_registro <= p_hasta
    and (p_usuario is null or v.usuario_registro = p_usuario);
  v_ef_ventas := v_efectivo;

  select jsonb_build_object(
    'efectivo', v_efectivo, 'tarjeta', v_tarjeta, 'transferencia', v_transf, 'cheque', v_cheque, 'credito', v_credito
  ) into v_metodos;

  select jsonb_build_object(
    'cantidad', count(*),
    'total', coalesce(sum(total_a_pagar), 0),
    'subtotal', coalesce(sum(subtotal), 0),
    'impuesto', coalesce(sum(impuesto), 0),
    'unidades', coalesce(sum(cantidad_productos), 0),
    'ticketPromedio', case when count(*) = 0 then 0 else round(sum(total_a_pagar) / count(*), 2) end,
    'mayorVenta', coalesce(max(total_a_pagar), 0)
  ) into v_ventas
  from ventas
  where estado = 'Activa' and tipo_documento <> 'Cotizacion'
    and fecha_registro >= p_desde and fecha_registro <= p_hasta
    and (p_usuario is null or usuario_registro = p_usuario);

  v_ventas := v_ventas || (
    select jsonb_build_object(
      'costo', coalesce(sum(i.precio_compra_usado * i.cantidad), 0),
      'utilidadBruta', coalesce(sum(i.subtotal - i.precio_compra_usado * i.cantidad), 0)
    )
    from venta_items i join ventas v on v.id = i.id_venta
    where v.estado = 'Activa' and v.tipo_documento <> 'Cotizacion'
      and v.fecha_registro >= p_desde and v.fecha_registro <= p_hasta
      and (p_usuario is null or v.usuario_registro = p_usuario)
  );

  select coalesce(jsonb_agg(jsonb_build_object('tipo', tipo_documento, 'cantidad', n, 'total', t) order by t desc), '[]'::jsonb)
  into v_tipos
  from (
    select tipo_documento, count(*) n, coalesce(sum(total_a_pagar), 0) t
    from ventas
    where estado = 'Activa' and fecha_registro >= p_desde and fecha_registro <= p_hasta
      and (p_usuario is null or usuario_registro = p_usuario)
    group by tipo_documento
  ) x;

  select jsonb_build_object('cantidad', count(*), 'total', coalesce(sum(total_a_pagar), 0)) into v_anuladas
  from ventas
  where estado = 'Anulada' and fecha_registro >= p_desde and fecha_registro <= p_hasta
    and (p_usuario is null or usuario_registro = p_usuario);

  select jsonb_build_object('cantidad', count(*), 'total', coalesce(sum(total_a_pagar), 0)) into v_cotizaciones
  from ventas
  where estado = 'Activa' and tipo_documento = 'Cotizacion' and fecha_registro >= p_desde and fecha_registro <= p_hasta
    and (p_usuario is null or usuario_registro = p_usuario);

  select jsonb_build_object(
    'cantidad', count(*),
    'total', coalesce(sum(monto_abonado), 0),
    'efectivo', coalesce(sum(monto_abonado) filter (where metodo_pago = 'Efectivo'), 0),
    'otros', coalesce(sum(monto_abonado) filter (where metodo_pago <> 'Efectivo'), 0)
  ) into v_abonos_c
  from venta_credito_abonos
  where fecha >= p_desde and fecha <= p_hasta and (p_usuario is null or usuario = p_usuario);
  v_ef_abonos := (v_abonos_c->>'efectivo')::numeric;

  select jsonb_build_object(
    'cantidad', count(*),
    'total', coalesce(sum(total_a_pagar), 0),
    'contado', coalesce(sum(total_a_pagar) filter (where condicion = 'Contado'), 0),
    'credito', coalesce(sum(total_a_pagar) filter (where condicion = 'Credito'), 0)
  ) into v_compras
  from compras
  where estado = 'Activa' and fecha_registro >= p_desde and fecha_registro <= p_hasta
    and (p_usuario is null or usuario_registro = p_usuario);

  select coalesce(sum(total_a_pagar), 0) into v_ef_compras
  from compras
  where estado = 'Activa' and condicion = 'Contado' and metodo_pago = 'Efectivo'
    and fecha_registro >= p_desde and fecha_registro <= p_hasta and (p_usuario is null or usuario_registro = p_usuario);

  select jsonb_build_object(
    'cantidad', count(*),
    'total', coalesce(sum(monto_abonado), 0),
    'efectivo', coalesce(sum(monto_abonado) filter (where metodo_pago = 'Efectivo'), 0),
    'otros', coalesce(sum(monto_abonado) filter (where metodo_pago <> 'Efectivo'), 0)
  ) into v_abonos_p
  from compra_credito_abonos
  where fecha >= p_desde and fecha <= p_hasta and (p_usuario is null or usuario = p_usuario);
  v_ef_pagos := (v_abonos_p->>'efectivo')::numeric;

  select jsonb_build_object(
    'cantidad', count(*),
    'total', coalesce(sum(monto), 0),
    'efectivo', coalesce(sum(monto) filter (where metodo_pago = 'Efectivo'), 0),
    'otros', coalesce(sum(monto) filter (where metodo_pago <> 'Efectivo'), 0)
  ) into v_egresos
  from egresos
  where es_pagado and coalesce(fecha_pago, fecha) >= p_desde and coalesce(fecha_pago, fecha) <= p_hasta
    and (p_usuario is null or usuario = p_usuario);
  v_ef_gastos := (v_egresos->>'efectivo')::numeric;

  select coalesce(jsonb_agg(jsonb_build_object('categoria', categoria, 'total', t) order by t desc), '[]'::jsonb)
  into v_categorias
  from (
    select categoria, sum(monto) t from egresos
    where es_pagado and coalesce(fecha_pago, fecha) >= p_desde and coalesce(fecha_pago, fecha) <= p_hasta
      and (p_usuario is null or usuario = p_usuario)
    group by categoria
  ) x;
  v_egresos := v_egresos || jsonb_build_object('porCategoria', v_categorias);

  select jsonb_build_object('cantidad', count(*), 'unidades', coalesce(sum(total_items), 0)) into v_traslados
  from traslados
  where estado <> 'Anulado' and fecha >= p_desde and fecha <= p_hasta
    and (p_usuario is null or usuario_crea = p_usuario);

  select coalesce(jsonb_agg(jsonb_build_object('usuario', usuario_registro, 'cantidad', n, 'total', t) order by t desc), '[]'::jsonb)
  into v_usuarios
  from (
    select usuario_registro, count(*) n, sum(total_a_pagar) t from ventas
    where estado = 'Activa' and tipo_documento <> 'Cotizacion' and fecha_registro >= p_desde and fecha_registro <= p_hasta
      and (p_usuario is null or usuario_registro = p_usuario)
    group by usuario_registro
  ) x;

  select coalesce(jsonb_agg(jsonb_build_object('hora', h, 'cantidad', n, 'total', t) order by h), '[]'::jsonb)
  into v_horas
  from (
    select extract(hour from fecha_registro)::int h, count(*) n, sum(total_a_pagar) t from ventas
    where estado = 'Activa' and tipo_documento <> 'Cotizacion' and fecha_registro >= p_desde and fecha_registro <= p_hasta
      and (p_usuario is null or usuario_registro = p_usuario)
    group by 1
  ) x;

  select coalesce(jsonb_agg(jsonb_build_object('nombre', nombre_producto, 'cantidad', c, 'monto', m) order by c desc), '[]'::jsonb)
  into v_productos
  from (
    select i.nombre_producto, sum(i.cantidad) c, round(sum(i.subtotal * case when v.impuesto > 0 then 1.15 else 1 end), 2) m
    from venta_items i join ventas v on v.id = i.id_venta
    where v.estado = 'Activa' and v.tipo_documento <> 'Cotizacion'
      and v.fecha_registro >= p_desde and v.fecha_registro <= p_hasta and (p_usuario is null or v.usuario_registro = p_usuario)
    group by i.nombre_producto order by sum(i.cantidad) desc limit 8
  ) x;

  select coalesce(jsonb_agg(jsonb_build_object('cliente', nombre_cliente, 'cantidad', n, 'total', t) order by t desc), '[]'::jsonb)
  into v_clientes
  from (
    select nombre_cliente, count(*) n, sum(total_a_pagar) t from ventas
    where estado = 'Activa' and tipo_documento <> 'Cotizacion' and upper(nombre_cliente) <> 'CONSUMIDOR FINAL' and nombre_cliente <> ''
      and fecha_registro >= p_desde and fecha_registro <= p_hasta and (p_usuario is null or usuario_registro = p_usuario)
    group by nombre_cliente order by sum(total_a_pagar) desc limit 5
  ) x;

  select coalesce(jsonb_agg(jsonb_build_object('fecha', f, 'tipo', tipo, 'descripcion', d, 'usuario', u, 'monto', m) order by f), '[]'::jsonb)
  into v_operaciones
  from (
    select * from (
      select fecha_registro f,
        case when estado = 'Anulada' then 'Venta anulada' when tipo_documento = 'Cotizacion' then 'Cotización' else 'Venta' end tipo,
        numero_documento || ' · ' || case when nombre_cliente = '' then 'CONSUMIDOR FINAL' else nombre_cliente end
          || ' · ' || case when condicion = 'Credito' then 'Crédito' when metodo_pago = '' then 'Sin pago' else metodo_pago end d,
        usuario_registro u, total_a_pagar m
      from ventas where fecha_registro >= p_desde and fecha_registro <= p_hasta and (p_usuario is null or usuario_registro = p_usuario)
      union all
      select fecha_registro, 'Compra', numero_documento || ' · ' || razon_social || ' · ' || case when condicion = 'Credito' then 'Crédito' else metodo_pago end,
        usuario_registro, total_a_pagar
      from compras where estado = 'Activa' and fecha_registro >= p_desde and fecha_registro <= p_hasta and (p_usuario is null or usuario_registro = p_usuario)
      union all
      select a.fecha, 'Abono de cliente',
        'Recibo ' || coalesce(nullif(a.numero_recibo, ''), '-') || ' · ' || coalesce(vc.nombre_cliente, 'Cliente') || ' · Doc. ' || coalesce(vc.numero_documento, '-')
          || ' · ' || a.metodo_pago || ' · saldo L.' || to_char(a.saldo_pendiente, 'FM999,999,990.00'),
        a.usuario, a.monto_abonado
      from venta_credito_abonos a left join ventas_credito vc on vc.id = a.id_venta_credito
      where a.fecha >= p_desde and a.fecha <= p_hasta and (p_usuario is null or a.usuario = p_usuario)
      union all
      select a.fecha, 'Pago a proveedor',
        'Recibo ' || coalesce(nullif(a.numero_recibo, ''), '-') || ' · ' || a.nombre_proveedor || ' · Doc. ' || coalesce(cc.numero_documento, '-')
          || ' · Factura ' || coalesce(nullif(cc.no_factura, ''), '-') || ' · ' || a.metodo_pago || ' · saldo L.' || to_char(a.saldo_pendiente, 'FM999,999,990.00'),
        a.usuario, a.monto_abonado
      from compra_credito_abonos a left join compras_credito cc on cc.id = a.id_compra_credito
      where a.fecha >= p_desde and a.fecha <= p_hasta and (p_usuario is null or a.usuario = p_usuario)
      union all
      select coalesce(fecha_pago, fecha), 'Egreso', descripcion || ' · ' || categoria || ' · ' || metodo_pago, usuario, monto
      from egresos where es_pagado and coalesce(fecha_pago, fecha) >= p_desde and coalesce(fecha_pago, fecha) <= p_hasta and (p_usuario is null or usuario = p_usuario)
      union all
      select fecha, 'Traslado', numero || ' → ' || nombre_sucursal_destino, usuario_crea, total_items
      from traslados where estado <> 'Anulado' and fecha >= p_desde and fecha <= p_hasta and (p_usuario is null or usuario_crea = p_usuario)
    ) todo
    order by f limit 600
  ) y;

  return jsonb_build_object(
    'desde', p_desde,
    'hasta', p_hasta,
    'ventas', v_ventas,
    'porTipo', v_tipos,
    'porMetodo', v_metodos,
    'anuladas', v_anuladas,
    'cotizaciones', v_cotizaciones,
    'abonosClientes', v_abonos_c,
    'compras', v_compras,
    'abonosProveedores', v_abonos_p,
    'egresos', v_egresos,
    'traslados', v_traslados,
    'flujoEfectivo', jsonb_build_object(
      'entradas', v_ef_ventas + v_ef_abonos,
      'salidas', v_ef_gastos + v_ef_pagos + v_ef_compras,
      'neto', v_ef_ventas + v_ef_abonos - v_ef_gastos - v_ef_pagos - v_ef_compras
    ),
    'porUsuario', v_usuarios,
    'porHora', v_horas,
    'topProductos', v_productos,
    'topClientes', v_clientes,
    'operaciones', v_operaciones
  );
end;
$$;

grant execute on function resumen_operaciones(timestamptz, timestamptz, text) to authenticated;
revoke execute on function resumen_operaciones(timestamptz, timestamptz, text) from public, anon;
