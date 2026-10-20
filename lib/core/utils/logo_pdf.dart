import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

final _cachePng = <String, Uint8List?>{};

pw.MemoryImage? decodificarLogoPdf(String base64, {int maxDimension = 160}) {
  if (base64.isEmpty) return null;
  final clave = '$maxDimension:${base64.length}:${base64.substring(0, base64.length < 64 ? base64.length : 64)}';
  if (_cachePng.containsKey(clave)) {
    final cacheado = _cachePng[clave];
    return cacheado == null ? null : pw.MemoryImage(cacheado);
  }
  try {
    final bytes = base64Decode(base64);
    final decodificada = img.decodeImage(bytes);
    if (decodificada == null) {
      _cachePng[clave] = null;
      return null;
    }

    final necesitaReducir = decodificada.width > maxDimension || decodificada.height > maxDimension;
    final imagenFinal = necesitaReducir
        ? img.copyResize(
            decodificada,
            width: decodificada.width >= decodificada.height ? maxDimension : null,
            height: decodificada.height > decodificada.width ? maxDimension : null,
          )
        : decodificada;

    final png = Uint8List.fromList(img.encodePng(imagenFinal));
    _cachePng[clave] = png;
    return pw.MemoryImage(png);
  } catch (_) {
    _cachePng[clave] = null;
    return null;
  }
}
