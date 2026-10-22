import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/core/services/ticket_generico.dart';

void main() {
  test('envolver no corta palabras largas y respeta el ancho', () {
    final lineas = TicketGenerico.envolver('FILTRO DE ACEITE PARA MOTOR TOYOTA HILUX 2.5 TURBO DIESEL', 32);
    expect(lineas.every((l) => l.length <= 32), isTrue);
    expect(lineas.join(' ').replaceAll(RegExp(r'\s+'), ' '), 'FILTRO DE ACEITE PARA MOTOR TOYOTA HILUX 2.5 TURBO DIESEL');
  });

  test('par largo se parte sin pasar de las columnas', () {
    final r = TicketGenerico.renderizar([const LPar('PASTILLAS DE FRENO DELANTERAS CERAMICAS PREMIUM', 'L. 1,250.00')], 32);
    expect(r.every((l) => l.texto.length <= 32), isTrue);
    expect(r.last.texto.endsWith('L. 1,250.00'), isTrue);
  });
}
