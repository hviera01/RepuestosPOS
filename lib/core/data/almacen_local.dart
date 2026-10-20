import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class AlmacenLocal {
  static bool _iniciado = false;
  static final Map<String, Box<String>> _cajas = {};

  static Future<void> iniciar() async {
    if (_iniciado) return;
    try {
      await Hive.initFlutter('repuestos_pos');
      _iniciado = true;
    } catch (e) {
      debugPrint('AlmacenLocal: no se pudo iniciar, se usa solo memoria: $e');
    }
  }

  static Future<Box<String>?> abrir(String nombre) async {
    final existente = _cajas[nombre];
    if (existente != null && existente.isOpen) return existente;
    if (!_iniciado) return null;
    try {
      final caja = await Hive.openBox<String>(nombre);
      _cajas[nombre] = caja;
      return caja;
    } catch (e) {
      debugPrint('AlmacenLocal: caja $nombre dañada, se recrea: $e');
      try {
        await Hive.deleteBoxFromDisk(nombre);
        final caja = await Hive.openBox<String>(nombre);
        _cajas[nombre] = caja;
        return caja;
      } catch (_) {
        return null;
      }
    }
  }

  static Future<void> limpiarTodo() async {
    for (final caja in _cajas.values) {
      if (caja.isOpen) await caja.clear();
    }
  }
}
