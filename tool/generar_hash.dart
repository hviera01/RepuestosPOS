import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Genera sal + hash listos para insertar a mano en `usuarios` (clave, sal),
/// mismo esquema que ClaveHash (lib/core/utils/clave_hash.dart): sha256 de
/// "sal:clave" con sal aleatoria de 16 bytes en base64 URL-safe.
void main(List<String> args) {
  final clave = args.first;
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  final sal = base64UrlEncode(bytes);
  final hash = sha256.convert(utf8.encode('$sal:$clave')).toString();
  print('sal=$sal');
  print('hash=$hash');
}