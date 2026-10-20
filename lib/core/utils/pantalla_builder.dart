import '../../features/sucursales/presentation/screens/sucursales_screen.dart';
import '../../features/traslados/presentation/screens/registrar_traslado_screen.dart';
import '../../features/traslados/presentation/screens/detalle_traslado_screen.dart';
import '../../features/traslados/presentation/screens/reporte_traslados_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/placeholder_screen.dart';
import '../../features/categorias/presentation/screens/categorias_screen.dart';
import '../../features/productos/presentation/screens/inventario_screen.dart';
import '../../features/productos/presentation/screens/auditoria_inventario_screen.dart';
import '../../features/productos/presentation/screens/pendientes_reposicion_screen.dart';
import '../../features/usuarios/presentation/screens/usuarios_screen.dart';
import '../../features/negocio/presentation/screens/negocio_screen.dart';
import '../../features/clientes/presentation/screens/clientes_screen.dart';
import '../../features/proveedores/presentation/screens/proveedores_screen.dart';
import '../../features/ventas_credito/presentation/screens/ventas_credito_screen.dart';
import '../../features/compras_credito/presentation/screens/compras_credito_screen.dart';
import '../../features/reportes/presentation/screens/reporte_ventas_screen.dart';
import '../../features/reportes/presentation/screens/reporte_compras_screen.dart';
import '../../features/reportes/presentation/screens/reporte_financiero_screen.dart';
import '../../features/ventas/presentation/screens/registrar_venta_screen.dart';
import '../../features/ventas/presentation/screens/detalle_venta_screen.dart';
import '../../features/ventas/providers/carrito_provider.dart';
import '../../features/ventas/providers/usuario_venta_provider.dart';
import '../../features/compras/presentation/screens/registrar_compra_screen.dart';
import '../../features/compras/presentation/screens/detalle_compra_screen.dart';
import '../../features/compras/presentation/screens/hacer_pedido_screen.dart';
import '../../features/compras/providers/carrito_compra_provider.dart';
import '../../features/caja/presentation/screens/caja_screen.dart';
import '../../features/egresos/presentation/screens/ingresos_egresos_screen.dart';
import '../../features/dispositivos/presentation/screens/dispositivos_screen.dart';
import '../../features/promociones/presentation/screens/promociones_screen.dart';
import '../../features/productos/providers/productos_provider.dart';
import '../../features/categorias/providers/categorias_provider.dart';
import '../../features/clientes/providers/clientes_provider.dart';
import '../../features/proveedores/providers/proveedores_provider.dart';
import '../../features/ventas_credito/providers/ventas_credito_provider.dart';
import '../../features/compras_credito/providers/compras_credito_provider.dart';
import '../../features/promociones/providers/promociones_provider.dart';
import '../../features/usuarios/providers/usuarios_provider.dart';

class _NavegadorDePestana extends StatelessWidget {
  final Widget contenido;

  const _NavegadorDePestana({required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => contenido),
    );
  }
}

Widget construirPantalla(
  String moduleKey,
  String titulo,
  IconData icono,
  String tabId,
) {
  return _NavegadorDePestana(
    contenido: _construirContenidoPantalla(moduleKey, titulo, icono, tabId),
  );
}

Widget _construirContenidoPantalla(
  String moduleKey,
  String titulo,
  IconData icono,
  String tabId,
) {
  switch (moduleKey) {
    case 'ventas_registrar':
      return ProviderScope(
        overrides: [
          carritoVentaProvider.overrideWith(() => CarritoVentaNotifier()),
          usuarioVentaOverrideProvider,
        ],
        child: RegistrarVentaScreen(tabId: tabId),
      );
    case 'ventas_buscar_producto':
      return ProviderScope(
        overrides: [
          carritoVentaProvider.overrideWith(() => CarritoVentaNotifier()),
          usuarioVentaOverrideProvider,
        ],
        child: RegistrarVentaScreen(tabId: tabId, autoAbrirBusqueda: true),
      );
    case 'ventas_detalle':
      return const DetalleVentaScreen(esDialogo: false);
    case 'compras_registrar':
      return ProviderScope(
        overrides: [
          carritoCompraProvider.overrideWith(() => CarritoCompraNotifier()),
        ],
        child: RegistrarCompraScreen(tabId: tabId),
      );
    case 'compras_detalle':
      return const DetalleCompraScreen(esDialogo: false);
    case 'compras_pedido':
      return const HacerPedidoScreen();
    case 'categorias':
      return ProviderScope(
        overrides: [categoriaBusquedaProvider],
        child: const CategoriasScreen(),
      );
    case 'inventario':
      return ProviderScope(
        overrides: [inventarioBusquedaProvider, inventarioVistaProvider],
        child: const InventarioScreen(),
      );
    case 'auditoria_inventario':
      return const AuditoriaInventarioScreen();
    case 'pendientes_reposicion':
      return const PendientesReposicionScreen();
    case 'usuarios':
      return ProviderScope(
        overrides: [usuarioBusquedaProvider],
        child: const UsuariosScreen(),
      );
    case 'negocio':
      return const NegocioScreen();
    case 'clientes':
      return ProviderScope(
        overrides: [clientesBusquedaProvider, clientesVistaProvider],
        child: const ClientesScreen(),
      );
    case 'proveedores':
      return ProviderScope(
        overrides: [proveedoresBusquedaProvider, proveedoresVistaProvider],
        child: const ProveedoresScreen(),
      );
    case 'ventas_credito':
      return ProviderScope(
        overrides: [ventasCreditoBusquedaProvider, ventasCreditoVistaProvider],
        child: const VentasCreditoScreen(),
      );
    case 'compras_credito':
      return ProviderScope(
        overrides: [
          comprasCreditoBusquedaProvider,
          comprasCreditoVistaProvider,
        ],
        child: const ComprasCreditoScreen(),
      );
    case 'sucursales':
      return const SucursalesScreen();
    case 'traslados_registrar':
      return const RegistrarTrasladoScreen();
    case 'traslados_detalle':
      return const DetalleTrasladoScreen(esDialogo: false);
    case 'reporte_traslados':
      return const ReporteTrasladosScreen();
    case 'reporte_ventas':
      return const ReporteVentasScreen();
    case 'reporte_compras':
      return const ReporteComprasScreen();
    case 'reporte_financiero':
      return const ReporteFinancieroScreen();
    case 'cierre_caja':
      return const CajaScreen();
    case 'ingresos_egresos':
      return const IngresosEgresosScreen();
    case 'dispositivos':
      return const DispositivosScreen();
    case 'promociones':
      return ProviderScope(
        overrides: [promocionesBusquedaProvider],
        child: const PromocionesScreen(),
      );
    default:
      return PlaceholderScreen(titulo: titulo, icono: icono);
  }
}
