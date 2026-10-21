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
  gris = img.normalize(gris, min: 0, max: 255);
  gris = img.adjustColor(gris, contrast: 1.35, brightness: 1.02);
  return Uint8List.fromList(img.encodePng(gris));
}
