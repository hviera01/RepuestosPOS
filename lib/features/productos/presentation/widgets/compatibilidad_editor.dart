import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/marca.dart';
import '../../../../core/utils/texto_utils.dart';
import '../../data/compatibilidad_model.dart';
import '../../providers/productos_provider.dart';

class SugerenciasVehiculo {
  final List<String> marcas;
  final Map<String, List<String>> modelosPorMarca;
  const SugerenciasVehiculo(this.marcas, this.modelosPorMarca);
}

final sugerenciasVehiculoProvider = Provider<SugerenciasVehiculo>((ref) {
  final productos = ref.watch(productosStreamProvider).value ?? const [];
  final porMarca = <String, Set<String>>{};
  for (final p in productos) {
    for (final c in p.compatibilidad) {
      final marca = c.marca.trim().toUpperCase();
      if (marca.isEmpty) continue;
      final modelos = porMarca.putIfAbsent(marca, () => <String>{});
      if (c.modelo.trim().isNotEmpty) modelos.add(c.modelo.trim().toUpperCase());
    }
  }
  final marcas = porMarca.keys.toList()..sort();
  return SugerenciasVehiculo(marcas, {for (final e in porMarca.entries) e.key: (e.value.toList()..sort())});
});

class CompatibilidadEditor extends ConsumerStatefulWidget {
  final List<CompatibilidadModel> inicial;
  final bool nombreAutomatico;
  final TextEditingController nombreBaseCtrl;
  final void Function(List<CompatibilidadModel> lista) alCambiarLista;
  final void Function(bool valor) alCambiarAutomatico;

  const CompatibilidadEditor({
    super.key,
    required this.inicial,
    required this.nombreAutomatico,
    required this.nombreBaseCtrl,
    required this.alCambiarLista,
    required this.alCambiarAutomatico,
  });

  @override
  ConsumerState<CompatibilidadEditor> createState() => _CompatibilidadEditorState();
}

class _FilaVehiculo {
  final TextEditingController marca;
  final TextEditingController modelo;
  final TextEditingController desde;
  final TextEditingController hasta;
  final FocusNode focoMarca = FocusNode();
  final FocusNode focoModelo = FocusNode();

  _FilaVehiculo(CompatibilidadModel c)
      : marca = TextEditingController(text: c.marca),
        modelo = TextEditingController(text: c.modelo),
        desde = TextEditingController(text: c.anioDesde?.toString() ?? ''),
        hasta = TextEditingController(text: c.anioHasta?.toString() ?? '');

  CompatibilidadModel aModelo() => CompatibilidadModel(
        marca: marca.text.trim().toUpperCase(),
        modelo: modelo.text.trim().toUpperCase(),
        anioDesde: int.tryParse(desde.text.trim()),
        anioHasta: int.tryParse(hasta.text.trim()),
      );

  void liberar() {
    marca.dispose();
    modelo.dispose();
    desde.dispose();
    hasta.dispose();
    focoMarca.dispose();
    focoModelo.dispose();
  }
}

class _CompatibilidadEditorState extends ConsumerState<CompatibilidadEditor> {
  late final List<_FilaVehiculo> _filas;
  late bool _usar;

  @override
  void initState() {
    super.initState();
    _filas = widget.inicial.map(_FilaVehiculo.new).toList();
    _usar = widget.nombreAutomatico || widget.inicial.isNotEmpty;
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.liberar();
    }
    super.dispose();
  }

  void _notificar() {
    final lista = _filas.map((f) => f.aModelo()).where((c) => c.marca.isNotEmpty || c.modelo.isNotEmpty).toList();
    widget.alCambiarLista(lista);
  }

  void _agregar() {
    setState(() => _filas.add(_FilaVehiculo(const CompatibilidadModel(marca: '', modelo: ''))));
  }

  void _quitar(int i) {
    setState(() {
      _filas.removeAt(i).liberar();
    });
    _notificar();
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _autocompletar({
    required TextEditingController ctrl,
    required FocusNode foco,
    required String etiqueta,
    required List<String> Function() opciones,
    required VoidCallback alCambiar,
  }) {
    return RawAutocomplete<String>(
      textEditingController: ctrl,
      focusNode: foco,
      optionsBuilder: (valor) {
        final q = normalizarTexto(valor.text);
        final todas = opciones();
        if (q.isEmpty) return todas.take(8);
        return todas.where((o) => normalizarTexto(o).contains(q)).take(8);
      },
      onSelected: (_) => alCambiar(),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _deco(etiqueta),
          onChanged: (_) => alCambiar(),
        );
      },
      optionsViewBuilder: (context, onSelected, opciones) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 240),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final o in opciones)
                    InkWell(
                      onTap: () => onSelected(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(o, style: GoogleFonts.poppins(fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _campoAnio(TextEditingController ctrl, String etiqueta) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _deco(etiqueta),
      onChanged: (_) => _notificar(),
    );
  }

  Widget _filaWidget(int i, SugerenciasVehiculo sug) {
    final f = _filas[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, c) {
          final estrecho = c.maxWidth < 520;
          final marca = _autocompletar(
            ctrl: f.marca,
            foco: f.focoMarca,
            etiqueta: 'Marca',
            opciones: () => sug.marcas,
            alCambiar: _notificar,
          );
          final modelo = _autocompletar(
            ctrl: f.modelo,
            foco: f.focoModelo,
            etiqueta: 'Modelo',
            opciones: () => sug.modelosPorMarca[f.marca.text.trim().toUpperCase()] ?? const [],
            alCambiar: _notificar,
          );
          final borrar = IconButton(
            tooltip: 'Quitar vehículo',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _quitar(i),
          );
          if (estrecho) {
            return Column(
              children: [
                Row(children: [Expanded(child: marca), const SizedBox(width: 8), Expanded(child: modelo), borrar]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _campoAnio(f.desde, 'Año desde')),
                  const SizedBox(width: 8),
                  Expanded(child: _campoAnio(f.hasta, 'Año hasta')),
                  const SizedBox(width: 48),
                ]),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: marca),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: modelo),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _campoAnio(f.desde, 'Año desde')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _campoAnio(f.hasta, 'Año hasta')),
              borrar,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sug = ref.watch(sugerenciasVehiculoProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Marca.primarioClaro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 20, color: Marca.primario),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehículos compatibles (opcional)',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: _usar,
                onChanged: (v) {
                  setState(() => _usar = v);
                  if (!v) widget.alCambiarAutomatico(false);
                },
              ),
            ],
          ),
          if (!_usar)
            Text(
              'Actívalo para indicar en qué marcas, modelos y años sirve este repuesto. Así se puede buscar por vehículo y año.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
          if (_usar) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < _filas.length; i++) _filaWidget(i, sug),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _agregar,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Agregar vehículo', style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: widget.nombreAutomatico,
              onChanged: widget.alCambiarAutomatico,
              title: Text('Armar el nombre automáticamente', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Pone al final del Nombre de arriba los vehículos compatibles. Si prefiere escribir todo el nombre a mano, apague esta opción.',
                style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
