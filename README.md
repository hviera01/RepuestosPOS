# Repuestos POS

Sistema de ventas, compras e inventario para un negocio de venta de repuestos. Flutter (Windows, Android y web) con Supabase (Postgres).

## Qué incluye

- Ventas (factura o venta simple, cotización, crédito, pago mixto), compras, créditos, caja, egresos y reportes.
- Inventario con búsqueda estricta, filtro por vehículo y año, y nombre de repuesto armado automáticamente desde los vehículos compatibles.
- Sucursales y traslados entre sucursales (el traslado descuenta existencias y se puede anular).
- Usuarios con roles, pantallas permitidas, acciones permitidas y clave especial para acciones sensibles.
- Color principal configurable desde Negocio y documento por defecto (Factura o Venta).
- Actualización automática desde GitHub Releases con instaladores firmados.

## Base de datos

Ejecutar en orden contra el proyecto de Supabase:

```
dart tool/supabase_sql.dart supabase/schema.sql
dart tool/supabase_sql.dart supabase/02_repuestos.sql
dart tool/supabase_sql.dart supabase/03_rendimiento.sql
```

`tool/supabase_sql.dart` lee `.env` (ver `.env.example`). Después poner la URL y la anon key en `lib/core/config/supabase_config.dart`.

## Rendimiento

- Las tablas grandes (productos, clientes, proveedores, categorías, créditos, cierres, negocio, sucursales) se guardan en el disco del equipo y solo se descargan los cambios nuevos (`updated_at`); Realtime avisa cuándo hay cambios.
- Los reportes se paginan y el resumen de inicio se calcula en la base de datos.
- Cada operación que cambia datos lleva un identificador único y se reintenta sola sin duplicarse (`ejecutar_idempotente`).

## Publicar una versión

```
powershell -File tool/publicar_release.ps1 -Version 2 -Notas "Que cambio"
```

Compila Windows y Android, genera el instalador, firma cada archivo con la llave privada (`tool/firmar_release.dart`) y crea la release. La app verifica la firma antes de instalar. La llave privada y el keystore de Android viven fuera del repositorio (`C:\Proyectos\repuestos_pos_secrets`).

## Web

El despliegue a GitHub Pages lo hace `.github/workflows/deploy-pages.yml` al subir a `main`.
