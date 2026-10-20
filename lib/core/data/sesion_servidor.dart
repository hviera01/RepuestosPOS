import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SesionServidor {
  SesionServidor._();

  static String? _token;
  static Timer? _renovacion;
  static final List<VoidCallback> _oyentes = [];

  static String? get token => _token;
  static bool get activa => _token != null;

  static void alCambiar(VoidCallback oyente) => _oyentes.add(oyente);

  static void establecer(String token) {
    _token = token;
    try {
      Supabase.instance.client.realtime.setAuth(token);
    } catch (e) {
      debugPrint('SesionServidor: no se pudo actualizar realtime: $e');
    }
    _renovacion?.cancel();
    _renovacion = Timer.periodic(const Duration(hours: 4), (_) => _renovar());
    for (final o in List.of(_oyentes)) {
      o();
    }
  }

  static void limpiar() {
    _renovacion?.cancel();
    _renovacion = null;
    _token = null;
  }

  static Future<void> _renovar() async {
    try {
      final r = await Supabase.instance.client.rpc('renovar_sesion');
      final nuevo = (r as Map?)?['token'] as String?;
      if (nuevo != null) {
        _token = nuevo;
        Supabase.instance.client.realtime.setAuth(nuevo);
      }
    } catch (e) {
      debugPrint('SesionServidor: no se pudo renovar la sesión: $e');
    }
  }
}
