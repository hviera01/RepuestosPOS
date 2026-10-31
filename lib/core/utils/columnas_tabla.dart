import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/marca.dart';

class ConfigColumnasTabla {
  final String clave;
  final Set<String> porDefecto;
  final ValueNotifier<Set<String>> visibles;

  ConfigColumnasTabla(this.clave, this.porDefecto) : visibles = ValueNotifier(Set.of(porDefecto));

  static final inventario = ConfigColumnasTabla('inventario', {
    'descripcion',
    'categoria',
    'ubicacion',
    'existencia',
    'precioVenta',
    'precioCompra',
    'estado',
  });

  static final buscarProducto = ConfigColumnasTabla('buscar_producto', {
    'categoria',
    'ubicacion',
    'existencia',
  });

  static Future<void> iniciar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final c in [inventario, buscarProducto]) {
        final guardado = prefs.getStringList('cols_${c.clave}');
        if (guardado != null) c.visibles.value = guardado.toSet();
      }
    } catch (_) {}
  }

  bool ver(String columna) => visibles.value.contains(columna);

  Future<void> establecer(Set<String> nuevo) async {
    visibles.value = nuevo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cols_$clave', nuevo.toList());
    } catch (_) {}
  }
}

Future<void> mostrarElegirColumnas(
  BuildContext context,
  ConfigColumnasTabla config,
  Map<String, String> opciones,
) {
  return showDialog(
    useRootNavigator: false,
    context: context,
    builder: (ctx) => ValueListenableBuilder<Set<String>>(
      valueListenable: config.visibles,
      builder: (ctx, visibles, _) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Columnas de la tabla', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige qué columnas ver. Se guarda solo en este equipo.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                for (final e in opciones.entries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Marca.primario,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(e.value, style: GoogleFonts.poppins(fontSize: 13)),
                    value: visibles.contains(e.key),
                    onChanged: (v) {
                      final nuevo = Set.of(visibles);
                      if (v == true) {
                        nuevo.add(e.key);
                      } else {
                        nuevo.remove(e.key);
                      }
                      config.establecer(nuevo);
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => config.establecer(Set.of(config.porDefecto)),
            child: const Text('Restablecer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: Marca.primario),
            child: const Text('Listo'),
          ),
        ],
      ),
    ),
  );
}
