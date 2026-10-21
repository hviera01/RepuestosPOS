import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:repuestos_pos/core/utils/logo_bn.dart';

void main() {
  test('el logo con fondo transparente sale con fondo blanco y trazo oscuro', () async {
    final logo = img.Image(width: 200, height: 120, numChannels: 4);
    img.fill(logo, color: img.ColorRgba8(0, 0, 0, 0));
    img.fillCircle(logo, x: 100, y: 60, radius: 40, color: img.ColorRgba8(200, 30, 30, 255));
    final bytes = Uint8List.fromList(img.encodePng(logo));
    final resultado = await convertirLogoABlancoYNegro(bytes);
    expect(resultado, isNotNull);
    final salida = img.decodePng(resultado!)!;
    final esquina = salida.getPixel(1, 1);
    expect(esquina.r > 240, isTrue);
    final centro = salida.getPixel(salida.width ~/ 2, salida.height ~/ 2);
    expect(centro.r < 140, isTrue);
  });

  test('un logo con fondo negro sale con fondo blanco para no gastar tinta en el ticket', () async {
    final logo = img.Image(width: 200, height: 200, numChannels: 4);
    img.fill(logo, color: img.ColorRgba8(0, 0, 0, 255));
    img.fillCircle(logo, x: 100, y: 100, radius: 50, color: img.ColorRgba8(250, 200, 20, 255));
    final resultado = await convertirLogoABlancoYNegro(Uint8List.fromList(img.encodePng(logo)));
    final salida = img.decodePng(resultado!)!;
    expect(salida.getPixel(2, 2).r > 220, isTrue);
    expect(salida.getPixel(salida.width ~/ 2, salida.height ~/ 2).r < 140, isTrue);
  });
}
