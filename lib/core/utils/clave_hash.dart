import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class ClaveHash {
  static String generarSal() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String clave, String sal) {
    return sha256.convert(utf8.encode('$sal:$clave')).toString();
  }

  static String hashSinSal(String clave) {
    return sha256.convert(utf8.encode(clave)).toString();
  }
}
