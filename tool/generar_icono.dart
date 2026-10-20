import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

const tam = 1024;
const dientes = 10;
const radioCuerpo = 265.0;
const radioDiente = 375.0;
const radioHueco = 130.0;

double radioLimite(double angulo) {
  final paso = 2 * math.pi / dientes;
  var t = (angulo % paso) / paso;
  if (t < 0) t += 1;
  final d = (t - 0.5).abs() * 2;
  if (d < 0.38) return radioDiente;
  if (d < 0.6) {
    final k = (d - 0.38) / 0.22;
    return radioDiente + (radioCuerpo - radioDiente) * k;
  }
  return radioCuerpo;
}

double cobertura(int px, int py) {
  var dentro = 0;
  const n = 3;
  for (var sy = 0; sy < n; sy++) {
    for (var sx = 0; sx < n; sx++) {
      final x = px + (sx + 0.5) / n - tam / 2;
      final y = py + (sy + 0.5) / n - tam / 2;
      final r = math.sqrt(x * x + y * y);
      if (r < radioHueco) continue;
      if (r <= radioLimite(math.atan2(y, x))) dentro++;
    }
  }
  return dentro / (n * n);
}

void main() {
  final coberturas = List.generate(tam, (y) => List.generate(tam, (x) => cobertura(x, y)));

  final icono = img.Image(width: tam, height: tam, numChannels: 4);
  final primerPlano = img.Image(width: tam, height: tam, numChannels: 4);
  for (var y = 0; y < tam; y++) {
    for (var x = 0; x < tam; x++) {
      final c = coberturas[y][x];
      final r = (0x30 + (255 - 0x30) * c).round();
      final g = (0x38 + (255 - 0x38) * c).round();
      final b = (0x46 + (255 - 0x46) * c).round();
      icono.setPixelRgba(x, y, r, g, b, 255);
      primerPlano.setPixelRgba(x, y, 255, 255, 255, (c * 255).round());
    }
  }
  File('assets/icono/icono.png').writeAsBytesSync(img.encodePng(icono));
  final lienzo = img.Image(width: tam, height: tam, numChannels: 4);
  img.fill(lienzo, color: img.ColorRgba8(0, 0, 0, 0));
  final reducido = img.copyResize(primerPlano, width: 640, height: 640, interpolation: img.Interpolation.cubic);
  img.compositeImage(lienzo, reducido, dstX: 192, dstY: 192);
  File('assets/icono/icono_primer_plano.png').writeAsBytesSync(img.encodePng(lienzo));
}
