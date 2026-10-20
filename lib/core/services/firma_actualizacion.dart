import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

class FirmaActualizacion {
  static const llavePublicaBase64 = 'r7uJ1+V0Xob2w5iV/6h6cJJRe4qVaq28d7PgqZFEK+8=';

  static Future<void> verificar(File archivo, String urlFirma) async {
    final respuesta = await http.get(Uri.parse(urlFirma)).timeout(const Duration(seconds: 20));
    if (respuesta.statusCode != 200) {
      throw Exception('La actualización no trae firma válida (HTTP ${respuesta.statusCode}); se canceló la instalación.');
    }
    final valida = await comprobar(archivo, respuesta.body.trim());
    if (!valida) {
      throw Exception('La firma de la actualización no coincide; se canceló la instalación por seguridad.');
    }
  }

  static Future<bool> comprobar(File archivo, String firmaBase64) async {
    final firma = base64Decode(firmaBase64);
    final hash = await sha256.bind(archivo.openRead()).first;
    return Ed25519().verify(
      hash.bytes,
      signature: Signature(
        firma,
        publicKey: SimplePublicKey(base64Decode(llavePublicaBase64), type: KeyPairType.ed25519),
      ),
    );
  }
}
