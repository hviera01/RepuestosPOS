import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'resumen_ventas_provider.dart';

class SerieDiaVenta {
  final String etiqueta;
  final double total;
  const SerieDiaVenta(this.etiqueta, this.total);
}

class DashboardAdminData {
  final double totalSemana;
  final int cantidadVentasSemana;
  final double ticketPromedioSemana;
  final List<SerieDiaVenta> serieUltimos7Dias;

  const DashboardAdminData({
    required this.totalSemana,
    required this.cantidadVentasSemana,
    required this.ticketPromedioSemana,
    required this.serieUltimos7Dias,
  });
}

const _diasCorto = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

final dashboardAdminHomeProvider = Provider.autoDispose<AsyncValue<DashboardAdminData>>((ref) {
  return ref.watch(resumenInicioProvider).whenData((r) {
    return DashboardAdminData(
      totalSemana: r.totalSemana,
      cantidadVentasSemana: r.cantidadSemana,
      ticketPromedioSemana: r.cantidadSemana == 0 ? 0.0 : r.totalSemana / r.cantidadSemana,
      serieUltimos7Dias: [for (final p in r.serie) SerieDiaVenta(_diasCorto[p.dia.weekday - 1], p.total)],
    );
  });
});
