import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/promocion_model.dart';
import '../data/promocion_repository.dart';

final promocionRepositoryProvider = Provider((ref) => PromocionRepository());

final promocionesStreamProvider = StreamProvider<List<PromocionModel>>((ref) {
  return ref.watch(promocionRepositoryProvider).obtenerPromociones();
});

class PromocionesBusquedaNotifier extends Notifier<String> {
  @override
  String build() => '';
  void actualizar(String valor) => state = valor;
}

final promocionesBusquedaProvider = NotifierProvider<PromocionesBusquedaNotifier, String>(PromocionesBusquedaNotifier.new);

List<PromocionModel> promocionesVigentes(List<PromocionModel> todas) {
  final ahora = DateTime.now();
  return todas.where((p) => p.vigente(ahora)).toList();
}

PromocionModel? mejorPromoPrecio({
  required List<PromocionModel> promociones,
  required String idProducto,
  required double precioActual,
  required String condicion,
  required String metodoPago,
  DateTime? ahora,
}) {
  final momento = ahora ?? DateTime.now();
  final aplicables = promociones.where((p) =>
      p.esPorcentajeOFijo &&
      p.vigente(momento) &&
      p.aplicaCondicion(condicion) &&
      p.aplicaMetodoPago(metodoPago) &&
      p.aplicaAlProducto(idProducto));
  if (aplicables.isEmpty) return null;

  double precioFinal(PromocionModel p) {
    if (p.tipo == TipoPromocion.porcentaje) return precioActual * (1 - p.valor / 100);
    return p.valor;
  }

  return aplicables.reduce((mejor, actual) => precioFinal(actual) < precioFinal(mejor) ? actual : mejor);
}

PromocionModel? promoComboORegaloAplicable({
  required List<PromocionModel> promociones,
  required String idProducto,
  required double cantidadEnCarrito,
  required String condicion,
  required String metodoPago,
  DateTime? ahora,
}) {
  final momento = ahora ?? DateTime.now();
  final aplicables = promociones
      .where((p) =>
          p.esComboORegalo &&
          p.vigente(momento) &&
          p.aplicaCondicion(condicion) &&
          p.aplicaMetodoPago(metodoPago) &&
          p.aplicaAlProducto(idProducto) &&
          cantidadEnCarrito >= p.cantidadRequerida)
      .toList();
  if (aplicables.isEmpty) return null;
  aplicables.sort((a, b) => b.cantidadRequerida.compareTo(a.cantidadRequerida));
  return aplicables.first;
}

PromocionModel? promoComboMultiproductoAplicable({
  required List<PromocionModel> promociones,
  required String idProducto,
  required Map<String, double> cantidadesEnCarrito,
  required String condicion,
  required String metodoPago,
  DateTime? ahora,
}) {
  final momento = ahora ?? DateTime.now();
  final aplicables = promociones.where((p) =>
      p.tipo == TipoPromocion.comboMultiproducto &&
      p.vigente(momento) &&
      p.aplicaCondicion(condicion) &&
      p.aplicaMetodoPago(metodoPago) &&
      p.idsProductosCombo.contains(idProducto));
  for (final p in aplicables) {
    final completo = p.idsProductosCombo.every((id) => (cantidadesEnCarrito[id] ?? 0) >= 1);
    if (completo) return p;
  }
  return null;
}

PromocionModel? promoParaBadge({
  required List<PromocionModel> promociones,
  required String idProducto,
  required String condicion,
  required String metodoPago,
  DateTime? ahora,
}) {
  final momento = ahora ?? DateTime.now();
  final vigentesAplicables = promociones
      .where((p) => p.vigente(momento) && p.aplicaCondicion(condicion) && p.aplicaMetodoPago(metodoPago) && p.aplicaAlProducto(idProducto))
      .toList();
  if (vigentesAplicables.isEmpty) return null;
  vigentesAplicables.sort((a, b) => (a.esPorcentajeOFijo ? 0 : 1).compareTo(b.esPorcentajeOFijo ? 0 : 1));
  return vigentesAplicables.first;
}
