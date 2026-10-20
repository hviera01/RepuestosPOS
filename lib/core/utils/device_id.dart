import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> obtenerIdDispositivo() async {
  if (!kIsWeb && Platform.isWindows) {
    final host = Platform.localHostname.trim();
    if (host.isNotEmpty) return host;
  }
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('idDispositivo');
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString('idDispositivo', id);
  }
  return id;
}

Future<bool> esteEquipoEsPcPrincipal(String pcPrincipalHostname) async {
  if (pcPrincipalHostname.isEmpty) return true;
  final id = await obtenerIdDispositivo();
  return id == pcPrincipalHostname;
}

String obtenerPlataforma() {
  if (kIsWeb) return 'Web';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  return 'Desconocida';
}
