import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/almacen_local.dart';

class PaletaMarca {
  final String id;
  final String nombre;
  final Color color;
  const PaletaMarca(this.id, this.nombre, this.color);
}

class Marca {
  static const Color primarioPorDefecto = Color(0xFF303846);

  static const List<PaletaMarca> paletas = [
    PaletaMarca('grafito', 'Grafito', Color(0xFF303846)),
    PaletaMarca('pizarra', 'Pizarra', Color(0xFF475569)),
    PaletaMarca('marino', 'Azul marino', Color(0xFF1E3A5F)),
    PaletaMarca('bosque', 'Verde bosque', Color(0xFF1F5F46)),
    PaletaMarca('vino', 'Vino', Color(0xFF7A1F2B)),
    PaletaMarca('ladrillo', 'Ladrillo', Color(0xFFA23E1E)),
    PaletaMarca('ocre', 'Ocre', Color(0xFF8A6414)),
    PaletaMarca('ciruela', 'Ciruela', Color(0xFF5B2A63)),
    PaletaMarca('turquesa', 'Turquesa', Color(0xFF0E6E78)),
  ];

  static Color primario = primarioPorDefecto;

  static Color get primarioClaro => Color.alphaBlend(Colors.white.withValues(alpha: 0.9), primario);

  static Color get primarioSuave => primario.withValues(alpha: 0.1);

  static Color get sobrePrimario => ThemeData.estimateBrightnessForColor(primario) == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A);

  static String aHex(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color? desdeHex(String? texto) {
    if (texto == null) return null;
    final limpio = texto.trim().replaceAll('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) return null;
    return Color(0xFF000000 | int.parse(limpio, radix: 16));
  }

  static Future<void> cargarGuardado() async {
    final caja = await AlmacenLocal.abrir('meta_sync');
    final guardado = desdeHex(caja?.get('tema_primario'));
    if (guardado != null) primario = guardado;
  }

  static Future<void> guardarLocal(Color color) async {
    final caja = await AlmacenLocal.abrir('meta_sync');
    await caja?.put('tema_primario', aHex(color));
  }

  static bool aplicarDesdeConfig(Map<String, dynamic>? tema) {
    final color = desdeHex(tema?['primario'] as String?) ?? primarioPorDefecto;
    if (color.toARGB32() == primario.toARGB32()) return false;
    primario = color;
    return true;
  }
}

class TemaVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refrescar() => state = state + 1;
}

final temaVersionProvider = NotifierProvider<TemaVersionNotifier, int>(TemaVersionNotifier.new);
