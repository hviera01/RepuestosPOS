import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/features/ventas/data/presencia_impresion_repository.dart';

void main() {
  final ahora = DateTime(2026, 10, 21, 20, 21, 0);

  test('latido con hora local guardada como si fuera UTC se reconoce como reciente', () {
    final guardado = DateTime.parse('2026-10-21 20:20:40+00');
    expect(PresenciaImpresionRepository.latidoReciente(guardado, ahora), isTrue);
  });

  test('latido en UTC real se reconoce como reciente', () {
    final guardado = ahora.subtract(const Duration(seconds: 10)).toUtc();
    expect(PresenciaImpresionRepository.latidoReciente(guardado, ahora), isTrue);
  });

  test('latido viejo no cuenta como conectada', () {
    final guardado = DateTime.parse('2026-10-21 20:10:00+00');
    expect(PresenciaImpresionRepository.latidoReciente(guardado, ahora), isFalse);
  });
}
