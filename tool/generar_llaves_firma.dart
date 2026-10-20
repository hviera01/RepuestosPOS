import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  final destino = args.isNotEmpty ? args.first : r'C:\Proyectos\repuestos_pos_secrets';
  final carpeta = Directory(destino)..createSync(recursive: true);
  final archivo = File('${carpeta.path}${Platform.pathSeparator}firma_actualizaciones.key');
  if (archivo.existsSync()) {
    stderr.writeln('Ya existe ${archivo.path}; no se sobrescribe.');
    exit(1);
  }
  final algoritmo = Ed25519();
  final par = await algoritmo.newKeyPair();
  final semilla = await par.extractPrivateKeyBytes();
  final publica = (await par.extractPublicKey()).bytes;
  archivo.writeAsStringSync(base64Encode(semilla));
  stdout.writeln('Llave privada guardada en ${archivo.path}');
  stdout.writeln('Llave publica (base64) para firma_config.dart:');
  stdout.writeln(base64Encode(publica));
}
