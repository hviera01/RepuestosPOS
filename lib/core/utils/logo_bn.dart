import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'segundo_plano.dart';

Future<Uint8List?> convertirLogoABlancoYNegro(Uint8List bytes) {
  return enSegundoPlano(() => _convertir(bytes));
}

Uint8List? _convertir(Uint8List bytes) {
  final original = img.decodeImage(bytes);
  if (original == null) return null;
  final fondo = img.Image(width: original.width, height: original.height, numChannels: 4);
  img.fill(fondo, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(fondo, original);
  var trabajo = img.trim(fondo, mode: img.TrimMode.topLeftColor);
  const maximo = 600;
  if (trabajo.width > maximo || trabajo.height > maximo) {
    trabajo = img.copyResize(
      trabajo,
      width: trabajo.width >= trabajo.height ? maximo : null,
      height: trabajo.height > trabajo.width ? maximo : null,
      interpolation: img.Interpolation.cubic,
    );
  }
  var gris = img.grayscale(trabajo);
  if (_fondoOscuro(gris)) gris = img.invert(gris);
  gris = img.normalize(gris, min: 0, max: 255);
  gris = img.adjustColor(gris, contrast: 1.35, brightness: 1.02);
  return Uint8List.fromList(img.encodePng(gris));
}

final _cacheBn = <String, String>{};

String logoBnDesdeColorBase64(String colorBase64) {
  if (colorBase64.isEmpty) return '';
  final clave = '${colorBase64.length}:${colorBase64.hashCode}';
  final guardado = _cacheBn[clave];
  if (guardado != null) return guardado;
  try {
    final bn = _convertir(base64Decode(colorBase64));
    final resultado = bn == null ? colorBase64 : base64Encode(bn);
    _cacheBn[clave] = resultado;
    return resultado;
  } catch (_) {
    return colorBase64;
  }
}

bool _fondoOscuro(img.Image gris) {
  var suma = 0.0;
  var n = 0;
  void muestra(int x, int y) {
    suma += gris.getPixel(x, y).luminanceNormalized;
    n++;
  }
  for (var i = 0; i < gris.width; i += 4) {
    muestra(i, 0);
    muestra(i, gris.height - 1);
  }
  for (var j = 0; j < gris.height; j += 4) {
    muestra(0, j);
    muestra(gris.width - 1, j);
  }
  return n > 0 && suma / n < 0.35;
}
