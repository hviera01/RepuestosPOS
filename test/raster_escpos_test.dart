import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:repuestos_pos/core/utils/logo_escpos.dart';

void main() {
  test('raster propio genera GS v 0 con tamaño correcto', () {
    final im = img.Image(width: 20, height: 3, numChannels: 3);
    img.fill(im, color: img.ColorRgb8(255, 255, 255));
    im.setPixelRgb(0, 0, 0, 0, 0);
    final b = rasterEscPos(im);
    expect(b.sublist(3, 7), [0x1D, 0x76, 0x30, 0x00]);
    expect(b.sublist(7, 11), [3, 0, 3, 0]);
    expect(b[11], 0x80);
    expect(b.length, 3 + 8 + 9 + 3);
  });
}
