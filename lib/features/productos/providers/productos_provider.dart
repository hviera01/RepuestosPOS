import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/producto_repository.dart';
import '../data/producto_model.dart';
import '../data/historial_stock_model.dart';
import '../data/historial_precio_compra_model.dart';
import '../data/historial_venta_producto_model.dart';
import '../data/lote_costo_model.dart';
import '../data/lote_costo_repository.dart';
import '../data/pendiente_reposicion_model.dart';
import '../data/pendiente_reposicion_repository.dart';

final productoRepositoryProvider = Provider((ref) => ProductoRepository());

final loteCostoRepositoryProvider = Provider((ref) => LoteCostoRepository());

final pendienteReposicionRepositoryProvider = Provider((ref) => PendienteReposicionRepository());

final pendientesReposicionStreamProvider = StreamProvider<List<PendienteReposicionModel>>((ref) {
  return ref.watch(pendienteReposicionRepositoryProvider).obtenerPendientes();
});

final lotesProductoProvider = StreamProvider.family<List<LoteCostoModel>, String>((ref, idProducto) {
  return ref.watch(loteCostoRepositoryProvider).obtenerLotes(idProducto);
});

final productosStreamProvider = StreamProvider<List<ProductoModel>>((ref) {
  return ref.watch(productoRepositoryProvider).obtenerProductos();
});

final historialStockProvider = StreamProvider.autoDispose.family<List<HistorialStockModel>, String>((ref, idProducto) {
  return ref.watch(productoRepositoryProvider).observarHistorialStock(idProducto);
});

final historialPreciosCompraProvider = FutureProvider.autoDispose.family<List<HistorialPrecioCompraModel>, String>((ref, idProducto) {
  return ref.watch(productoRepositoryProvider).obtenerHistorialPreciosCompra(idProducto);
});

final historialVentasProductoProvider = FutureProvider.autoDispose.family<List<HistorialVentaProductoModel>, String>((ref, idProducto) {
  return ref.watch(productoRepositoryProvider).obtenerHistorialVentas(idProducto);
});

class InventarioBusquedaNotifier extends Notifier<String> {
  @override
  String build() => '';
  void actualizar(String valor) => state = valor;
}

final inventarioBusquedaProvider = NotifierProvider<InventarioBusquedaNotifier, String>(InventarioBusquedaNotifier.new);

class InventarioVistaNotifier extends Notifier<String> {
  @override
  String build() => 'filtrados';
  void actualizar(String valor) => state = valor;
}

final inventarioVistaProvider = NotifierProvider<InventarioVistaNotifier, String>(InventarioVistaNotifier.new);