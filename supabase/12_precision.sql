alter table venta_items alter column precio_venta type numeric(16, 6);
alter table producto_historial_ventas alter column precio_unitario type numeric(16, 6);
alter table compra_items alter column precio_compra type numeric(16, 6);
alter table producto_historial_precios_compra alter column precio_unitario type numeric(16, 6);
