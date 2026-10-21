import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) {
  final origen = args.first;
  final original = img.decodeImage(File(origen).readAsBytesSync())!;
  final cuadrado = img.copyResize(original, width: 1024, height: 1024, interpolation: img.Interpolation.cubic);
  File('assets/icono/icono.png').writeAsBytesSync(img.encodePng(cuadrado));
  final lienzo = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(lienzo, color: img.ColorRgba8(0, 0, 0, 0));
  final reducido = img.copyResize(cuadrado, width: 700, height: 700, interpolation: img.Interpolation.cubic);
  img.compositeImage(lienzo, reducido, dstX: 162, dstY: 162);
  File('assets/icono/icono_primer_plano.png').writeAsBytesSync(img.encodePng(lienzo));
  final app = img.copyResize(original, width: 720, height: 720, interpolation: img.Interpolation.cubic);
  File('assets/images/logo_danli.jpg').writeAsBytesSync(img.encodeJpg(app, quality: 90));
  final negocio = img.copyResize(original, width: 520, height: 520, interpolation: img.Interpolation.cubic);
  File('assets/images/logo_negocio.jpg').writeAsBytesSync(img.encodeJpg(negocio, quality: 88));
}
