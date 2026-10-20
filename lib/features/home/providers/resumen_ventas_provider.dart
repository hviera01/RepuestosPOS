import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reportes/data/reporte_repository.dart';
import '../../reportes/providers/reportes_provider.dart';

class ResumenVentasHome {
  final double totalDia;
  final double totalMes;
  final int cantidadVentasDia;

  const ResumenVentasHome({
    required this.totalDia,
    required this.totalMes,
    required this.cantidadVentasDia,
  });
}

final resumenInicioProvider = StreamProvider.autoDispose<ResumenInicioVentas>((ref) {
  return ref.watch(reporteRepositoryProvider).observarResumenInicio();
});

final resumenVentasHomeProvider = Provider.autoDispose<AsyncValue<ResumenVentasHome>>((ref) {
  return ref.watch(resumenInicioProvider).whenData(
        (r) => ResumenVentasHome(totalDia: r.totalDia, totalMes: r.totalMes, cantidadVentasDia: r.cantidadDia),
      );
});
