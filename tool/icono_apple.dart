import 'dart:io';
import 'package:image/image.dart' as img;
void main() {
  final o = img.decodeImage(File('assets/icono/icono.png').readAsBytesSync())!;
  final a = img.copyResize(o, width: 180, height: 180, interpolation: img.Interpolation.cubic);
  final plano = img.Image(width: 180, height: 180, numChannels: 3);
  img.fill(plano, color: img.ColorRgb8(11, 11, 11));
  img.compositeImage(plano, a);
  File('web/icons/apple-touch-icon.png').writeAsBytesSync(img.encodePng(plano));
}
