import 'dart:convert';
import 'package:image/image.dart' as img;

final _cache = <String, img.Image?>{};

img.Image? decodificarLogoEscPos(String base64, {int maxDimension = 300}) {
  if (base64.isEmpty) return null;
  final clave = '$maxDimension:${base64.length}:${base64.substring(0, base64.length < 64 ? base64.length : 64)}';
  if (_cache.containsKey(clave)) return _cache[clave];
  try {
    final bytes = base64Decode(base64);
    final decodificada = img.decodeImage(bytes);
    if (decodificada == null) {
      _cache[clave] = null;
      return null;
    }
    final recortada = img.trim(decodificada);
    final necesitaReducir = recortada.width > maxDimension || recortada.height > maxDimension;
    final redimensionada = necesitaReducir
        ? img.copyResize(
            recortada,
            width: recortada.width >= recortada.height ? maxDimension : null,
            height: recortada.height > recortada.width ? maxDimension : null,
          )
        : recortada;
    final ditherizada = img.ditherImage(redimensionada, quantizer: img.BinaryQuantizer(), kernel: img.DitherKernel.floydSteinberg);
    final imagenFinal = ditherizada.convert(numChannels: 3);
    _cache[clave] = imagenFinal;
    return imagenFinal;
  } catch (_) {
    _cache[clave] = null;
    return null;
  }
}
