import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const prefsFaceIdCredencial = 'faceId_credencial';
const prefsFaceIdCodigo = 'faceId_codigo';
const prefsFaceIdClave = 'faceId_clave';

Future<void> guardarCredencialesFaceId({
  required String credencialId,
  required String codigo,
  required String clave,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(prefsFaceIdCredencial, credencialId);
  await prefs.setString(prefsFaceIdCodigo, base64Encode(utf8.encode(codigo)));
  await prefs.setString(prefsFaceIdClave, base64Encode(utf8.encode(clave)));
}

Future<void> olvidarCredencialesFaceId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(prefsFaceIdCredencial);
  await prefs.remove(prefsFaceIdCodigo);
  await prefs.remove(prefsFaceIdClave);
}

Future<String?> credencialFaceIdGuardada() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(prefsFaceIdCredencial);
}

class CredencialesLogin {
  final String codigo;
  final String clave;
  CredencialesLogin({required this.codigo, required this.clave});
}

Future<CredencialesLogin?> credencialesLoginGuardadas() async {
  final prefs = await SharedPreferences.getInstance();
  final codigo = prefs.getString(prefsFaceIdCodigo);
  final clave = prefs.getString(prefsFaceIdClave);
  if (codigo == null || clave == null) return null;
  return CredencialesLogin(codigo: utf8.decode(base64Decode(codigo)), clave: utf8.decode(base64Decode(clave)));
}
