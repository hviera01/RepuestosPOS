import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/core/utils/formato_moneda.dart';

void main() {
  test('el precio final nunca sale con un centavo de mas o de menos al pasar por la base sin ISV', () {
    var fallos = 0;
    for (var centavos = 5; centavos <= 800000; centavos += 5) {
      final precio = centavos / 100;
      final base = double.parse((precio / 1.15).toStringAsFixed(6));
      final vuelta = redondearMoneda(base * 1.15);
      if ((vuelta - precio).abs() > 0.0001) fallos++;
    }
    expect(fallos, 0);
  });

  test('con la base redondeada a 2 decimales si habria diferencias de un centavo', () {
    var fallos = 0;
    for (var centavos = 5; centavos <= 20000; centavos += 1) {
      final precio = centavos / 100;
      final base = redondearMoneda(precio / 1.15);
      if ((redondearMoneda(base * 1.15) - precio).abs() > 0.0001) fallos++;
    }
    expect(fallos > 0, isTrue);
  });
}
