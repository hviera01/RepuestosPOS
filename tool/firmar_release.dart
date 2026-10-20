import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart tool/firmar_release.dart <archivo> [<archivo>...]');
    exit(2);
  }
  final rutaLlave = Platform.environment['FIRMA_LLAVE'] ?? r'C:\Proyectos\repuestos_pos_secrets\firma_actualizaciones.key';
  final llave = File(rutaLlave);
  if (!llave.existsSync()) {
    stderr.writeln('No se encuentra la llave privada: $rutaLlave');
    exit(1);
  }
  final semilla = base64Decode(llave.readAsStringSync().trim());
  final algoritmo = Ed25519();
  final par = await algoritmo.newKeyPairFromSeed(semilla);
  for (final ruta in args) {
    final archivo = File(ruta);
    final hash = await sha256.bind(archivo.openRead()).first;
    final firma = await algoritmo.sign(hash.bytes, keyPair: par);
    final salida = File('$ruta.firma')..writeAsStringSync(base64Encode(firma.bytes));
    stdout.writeln('${salida.path}  sha256=$hash');
  }
}
