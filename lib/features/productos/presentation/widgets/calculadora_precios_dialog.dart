import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/marca.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/utils/texto_utils.dart';
import '../../../categorias/providers/categorias_provider.dart';
import '../../data/producto_model.dart';
import '../../providers/productos_provider.dart';

enum RedondeoPrecio { ninguno, entero, multiploCinco }

double _centavos(double x) => (x * 100 + 1e-7).roundToDouble() / 100;

class PrecioCalculado {
  final double base;
  final double isv;
  final double finalExacto;
  final double guardado;

  const PrecioCalculado({required this.base, required this.isv, required this.finalExacto, required this.guardado});

  bool get redondeado => (guardado - finalExacto).abs() > 0.004;
}

PrecioCalculado calcularPrecio({
  required double costo,
  required double porcentaje,
  required double impuesto,
  required RedondeoPrecio redondeo,
}) {
  final base = _centavos(costo * (1 + porcentaje / 100));
  final isv = _centavos(base * impuesto / 100);
  final finalExacto = _centavos(base + isv);
  final guardado = switch (redondeo) {
    RedondeoPrecio.ninguno => finalExacto,
    RedondeoPrecio.entero => (finalExacto - 1e-9).ceilToDouble(),
    RedondeoPrecio.multiploCinco => ((finalExacto / 5) - 1e-9).ceilToDouble() * 5,
  };
  return PrecioCalculado(base: base, isv: isv, finalExacto: finalExacto, guardado: guardado);
}

class NivelPrecio {
  bool activo;
  final TextEditingController porcentaje;
  NivelPrecio({required this.activo, String texto = ''}) : porcentaje = TextEditingController(text: texto);

  double? get valor => double.tryParse(porcentaje.text.trim().replaceAll(',', '.'));
  bool get valido => activo && valor != null && valor! >= 0;
}

class _MemoriaFormula {
  static final List<String> porcentajes = ['45', '', ''];
  static final List<bool> activos = [true, false, false];
  static RedondeoPrecio redondeo = RedondeoPrecio.multiploCinco;
}

List<NivelPrecio> _nivelesDesdeMemoria() => List.generate(
      3,
      (i) => NivelPrecio(activo: _MemoriaFormula.activos[i], texto: _MemoriaFormula.porcentajes[i]),
    );

void _guardarMemoria(List<NivelPrecio> niveles, RedondeoPrecio redondeo) {
  for (var i = 0; i < 3; i++) {
    _MemoriaFormula.activos[i] = niveles[i].activo;
    _MemoriaFormula.porcentajes[i] = niveles[i].porcentaje.text;
  }
  _MemoriaFormula.redondeo = redondeo;
}

class _PanelFormula extends StatelessWidget {
  final List<NivelPrecio> niveles;
  final int cantidadNiveles;
  final RedondeoPrecio redondeo;
  final bool bloqueado;
  final VoidCallback onCambio;
  final ValueChanged<RedondeoPrecio> onRedondeo;

  const _PanelFormula({
    required this.niveles,
    required this.cantidadNiveles,
    required this.redondeo,
    required this.bloqueado,
    required this.onCambio,
    required this.onRedondeo,
  });

  @override
  Widget build(BuildContext context) {
    final filas = List.generate(cantidadNiveles, (i) {
      final n = niveles[i];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: n.activo,
            activeColor: Marca.primario,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: bloqueado
                ? null
                : (v) {
                    n.activo = v ?? false;
                    onCambio();
                  },
          ),
          SizedBox(width: 66, child: Text('Precio ${i + 1}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
          Text('Costo +', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: TextField(
              controller: n.porcentaje,
              enabled: n.activo && !bloqueado,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => onCambio(),
              decoration: InputDecoration(
                isDense: true,
                suffixText: '%',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    });
    final desplegable = DropdownButton<RedondeoPrecio>(
      value: redondeo,
      isDense: true,
      isExpanded: true,
      onChanged: bloqueado ? null : (v) => onRedondeo(v ?? RedondeoPrecio.ninguno),
      items: const [
        DropdownMenuItem(value: RedondeoPrecio.multiploCinco, child: Text('Hacia arriba al 5 (33 → 35, 27 → 30)', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: RedondeoPrecio.entero, child: Text('Hacia arriba al entero (33.40 → 34)', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: RedondeoPrecio.ninguno, child: Text('Sin redondear')),
      ],
    );
    final etiquetaRedondeo = Text('Redondeo del precio final', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600));
    return LayoutBuilder(builder: (context, restr) {
      final ancho = restr.maxWidth >= 900;
      return Container(
        padding: EdgeInsets.fromLTRB(ancho ? 10 : 14, ancho ? 6 : 14, ancho ? 10 : 14, ancho ? 4 : 14),
        decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E4EA))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ancho
                  ? 'Precio = costo × (1 + porcentaje) + ISV del producto. El precio final es el que se guarda y se cobra.'
                  : 'Precio = costo × (1 + porcentaje). Después se suma el ISV del producto y el resultado es el precio final, que es el que se guarda y se cobra.',
              style: GoogleFonts.poppins(fontSize: ancho ? 11.5 : 12, color: Colors.grey.shade600),
            ),
            SizedBox(height: ancho ? 2 : 8),
            if (ancho)
              Wrap(
                spacing: 22,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...filas,
                  SizedBox(
                    width: 420,
                    child: Row(
                      children: [
                        etiquetaRedondeo,
                        const SizedBox(width: 10),
                        Expanded(child: desplegable),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              Wrap(spacing: 22, children: filas),
              const SizedBox(height: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [etiquetaRedondeo, desplegable]),
            ],
          ],
        ),
      );
    });
  }
}

const double _anchoNivel = 5 * 92.0;

Widget _envolverMovil(bool movil, Widget hijo) => movil ? SingleChildScrollView(child: hijo) : hijo;

class _ScrollHorizontal extends StatefulWidget {
  final Widget child;
  const _ScrollHorizontal({required this.child});

  @override
  State<_ScrollHorizontal> createState() => _ScrollHorizontalState();
}

class _ScrollHorizontalState extends State<_ScrollHorizontal> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 12,
      radius: const Radius.circular(6),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 16),
        child: widget.child,
      ),
    );
  }
}

Widget _celdaTexto(String texto, double ancho, {bool negrita = false, Color? color, Alignment alineacion = Alignment.centerRight, String? detalle, bool multilinea = false}) {
  return SizedBox(
    width: ancho,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(
        alignment: alineacion,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alineacion == Alignment.centerRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              maxLines: multilinea ? null : 1,
              overflow: multilinea ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: alineacion == Alignment.centerRight ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: negrita ? FontWeight.w700 : FontWeight.w400, color: color ?? const Color(0xFF1A1A1A)),
            ),
            if (detalle != null) Text(detalle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    ),
  );
}

List<Widget> _encabezadoNivel(int i, String porcentaje, {required bool conActual}) {
  Widget h(String t, {Color? color}) => _celdaTexto(t, 92, negrita: true, color: color ?? Colors.grey.shade700, multilinea: true);
  return [
    h('Precio $i (+$porcentaje%)'),
    h('ISV'),
    h('Precio final'),
    h('Se guardará', color: Marca.primario),
    if (conActual) h('Actual'),
  ];
}

List<Widget> _celdasNivel(PrecioCalculado r, double? actual) {
  return [
    _celdaTexto(formatearMoneda(r.base), 92),
    _celdaTexto(formatearMoneda(r.isv), 92),
    _celdaTexto(formatearMoneda(r.finalExacto), 92),
    _celdaTexto(formatearMoneda(r.guardado), 92, negrita: true, color: Marca.primario, detalle: r.redondeado ? 'redondeado' : null),
    if (actual != null) _celdaTexto(formatearMoneda(actual), 92, color: Colors.grey.shade600),
  ];
}

typedef _NivelVista = ({int nivel, String pct, PrecioCalculado r, double? actual});

Widget _tarjetaMovil({
  Widget? izquierda,
  required String titulo,
  required String sub,
  required double costo,
  required double impuesto,
  required List<_NivelVista> niveles,
  bool marcado = false,
  VoidCallback? onTap,
}) {
  Widget fila(String k, String v, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(k, style: GoogleFonts.poppins(fontSize: 12, fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400, color: fuerte ? Marca.primario : Colors.grey.shade700))),
            Text(v, style: GoogleFonts.poppins(fontSize: fuerte ? 14 : 12, fontWeight: fuerte ? FontWeight.w700 : FontWeight.w500, color: fuerte ? Marca.primario : const Color(0xFF1A1A1A))),
          ],
        ),
      );
  final pctImp = impuesto.toStringAsFixed(impuesto == impuesto.roundToDouble() ? 0 : 2);
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(color: marcado ? Marca.primario.withOpacity(0.05) : null, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (izquierda != null) izquierda,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                if (sub.isNotEmpty) Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Costo ${formatearMoneda(costo)} · ISV $pctImp%', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                for (final n in niveles) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE1E4EA))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Precio ${n.nivel} (+${n.pct}%)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        fila('Precio', formatearMoneda(n.r.base)),
                        fila('ISV', formatearMoneda(n.r.isv)),
                        fila('Precio final', formatearMoneda(n.r.finalExacto)),
                        fila(n.r.redondeado ? 'Se guardará (redondeado)' : 'Se guardará', formatearMoneda(n.r.guardado), fuerte: true),
                        if (n.actual != null) fila('Actual', formatearMoneda(n.actual!)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CalculadoraPreciosDialog extends ConsumerStatefulWidget {
  const CalculadoraPreciosDialog({super.key});

  @override
  ConsumerState<CalculadoraPreciosDialog> createState() => _CalculadoraPreciosDialogState();
}

class _CalculadoraPreciosDialogState extends ConsumerState<CalculadoraPreciosDialog> {
  final List<NivelPrecio> _niveles = _nivelesDesdeMemoria();
  RedondeoPrecio _redondeo = _MemoriaFormula.redondeo;
  final _busquedaController = TextEditingController();
  final Set<String> _seleccion = {};
  String _idCategoria = '';
  bool _aplicando = false;
  bool? _formulaManual;
  int _avance = 0;
  int _total = 0;
  String? _error;
  int? _resultado;

  @override
  void dispose() {
    _guardarMemoria(_niveles, _redondeo);
    _busquedaController.dispose();
    for (final n in _niveles) {
      n.porcentaje.dispose();
    }
    super.dispose();
  }

  bool get _hayNivelValido => _niveles.any((n) => n.valido);
  bool get _hayNivelIncompleto => _niveles.any((n) => n.activo && !n.valido);

  List<ProductoModel> _elegibles(List<ProductoModel> todos) {
    final consulta = _busquedaController.text.trim();
    return todos.where((p) {
      if (p.esCombo || p.precioCompra <= 0) return false;
      if (_idCategoria.isNotEmpty && p.idCategoria != _idCategoria) return false;
      if (consulta.isEmpty) return true;
      return coincideFuzzy('${p.codigo} ${p.nombre} ${p.marca}', consulta);
    }).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  PrecioCalculado? _calc(ProductoModel p, int nivel) {
    final n = _niveles[nivel];
    if (!n.valido) return null;
    return calcularPrecio(costo: p.precioCompra, porcentaje: n.valor!, impuesto: p.impuestoPorcentaje, redondeo: _redondeo);
  }

  String _resumenNiveles() {
    final partes = <String>[];
    for (var i = 0; i < _niveles.length; i++) {
      if (_niveles[i].valido) partes.add('Precio ${i + 1}: costo + ${_niveles[i].porcentaje.text.trim()}%');
    }
    return partes.join(', ');
  }

  Future<void> _aplicar(List<ProductoModel> todos) async {
    final elegidos = todos.where((p) => _seleccion.contains(p.id)).toList();
    final cambios = elegidos
        .map((p) => (
              id: p.id,
              precioVenta: _calc(p, 0)?.guardado,
              precioVenta2: _calc(p, 1)?.guardado,
              precioVenta3: _calc(p, 2)?.guardado,
            ))
        .toList();
    final confirmar = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aplicar nuevos precios', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Se van a cambiar los precios de ${cambios.length} producto${cambios.length == 1 ? '' : 's'} (${_resumenNiveles()}). Se guarda el precio final, con ISV incluido, y reemplaza el precio actual.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Marca.primario),
            child: const Text('Sí, aplicar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() {
      _aplicando = true;
      _error = null;
      _avance = 0;
      _total = cambios.length;
    });
    try {
      final hechos = await ref.read(productoRepositoryProvider).actualizarPreciosVenta(
        cambios,
        alAvanzar: (h) {
          if (mounted) setState(() => _avance = h);
        },
      );
      if (mounted) setState(() => _resultado = hechos);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo completar: $e');
    } finally {
      if (mounted) setState(() => _aplicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    final esMovil = tamano.width < 720;
    final formulaVisible = _formulaManual ?? true;
    final productosAsync = ref.watch(productosStreamProvider);
    final categorias = ref.watch(categoriasStreamProvider).asData?.value ?? const [];
    final todos = productosAsync.asData?.value ?? const <ProductoModel>[];
    final lista = _elegibles(todos);
    final sinCosto = todos.where((p) => !p.esCombo && p.precioCompra <= 0).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(8),
      child: Container(
        width: tamano.width - 16,
        constraints: BoxConstraints(maxHeight: tamano.height - 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Marca.primario.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                    child: Icon(Icons.calculate_outlined, color: Marca.primario, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Calculadora de precios', style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: _aplicando ? null : () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: _resultado != null
                  ? _vistaResultado()
                  : _envolverMovil(esMovil, Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formulaVisible)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                            child: _PanelFormula(
                              niveles: _niveles,
                              cantidadNiveles: 3,
                              redondeo: _redondeo,
                              bloqueado: _aplicando,
                              onCambio: () => setState(() {}),
                              onRedondeo: (v) => setState(() => _redondeo = v),
                            ),
                          ),
                        Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 0), child: _filtros(categorias, lista, esMovil)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_seleccion.length} seleccionados · ${lista.length} en la lista${sinCosto > 0 ? ' · $sinCosto sin costo no aparecen' : ''}${formulaVisible ? '' : ' · ${_resumenNiveles()}'}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _formulaManual = !formulaVisible),
                                icon: Icon(formulaVisible ? Icons.unfold_less : Icons.unfold_more, size: 18),
                                label: Text(formulaVisible ? 'Ocultar fórmula' : 'Mostrar fórmula', style: GoogleFonts.poppins(fontSize: 12)),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                        ),
                        esMovil ? _tabla(lista) : Flexible(child: _tabla(lista)),
                      ],
                    )),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFCE9E9), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12.5, color: Marca.primario)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
              child: _resultado != null
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(backgroundColor: Marca.primario, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Cerrar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _aplicando
                              ? Row(
                                  children: [
                                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                    const SizedBox(width: 10),
                                    Text('Aplicando $_avance de $_total...', style: GoogleFonts.poppins(fontSize: 12.5)),
                                  ],
                                )
                              : Text(
                                  _hayNivelIncompleto
                                      ? 'Escribe el porcentaje de cada precio marcado.'
                                      : (!_hayNivelValido ? 'Marca al menos un precio y escribe su porcentaje.' : ''),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Marca.primario),
                                ),
                        ),
                        OutlinedButton(
                          onPressed: _aplicando ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB6BCC7)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Cancelar', style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: (_aplicando || _hayNivelIncompleto || !_hayNivelValido || _seleccion.isEmpty) ? null : () => _aplicar(todos),
                          style: FilledButton.styleFrom(backgroundColor: Marca.primario, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(_seleccion.isEmpty ? 'Aplicar' : 'Aplicar a ${_seleccion.length}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaResultado() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 54),
          const SizedBox(height: 14),
          Text('Se actualizaron $_resultado productos', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_resumenNiveles(), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _filtros(List categorias, List<ProductoModel> lista, bool esMovil) {
    final buscador = TextField(
      controller: _busquedaController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por código, nombre o marca',
        prefixIcon: const Icon(Icons.search, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final categoria = DropdownButtonFormField<String>(
      key: ValueKey(_idCategoria),
      initialValue: _idCategoria,
      isExpanded: true,
      decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todas las categorías')),
        ...categorias.map((c) => DropdownMenuItem<String>(value: c.id as String, child: Text(c.descripcion as String, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (v) => setState(() => _idCategoria = v ?? ''),
    );
    final botones = Wrap(
      spacing: 8,
      children: [
        OutlinedButton(
          onPressed: _aplicando ? null : () => setState(() => _seleccion.addAll(lista.map((p) => p.id))),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text('Marcar los ${lista.length} de la lista', style: GoogleFonts.poppins(fontSize: 12)),
        ),
        OutlinedButton(
          onPressed: _aplicando ? null : () => setState(() => _seleccion.clear()),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text('Quitar todo', style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ],
    );
    if (esMovil) {
      return Column(children: [buscador, const SizedBox(height: 8), categoria, const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: botones)]);
    }
    return Row(
      children: [
        Expanded(flex: 3, child: buscador),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: categoria),
        const SizedBox(width: 10),
        botones,
      ],
    );
  }

  Widget _tabla(List<ProductoModel> lista) {
    if (lista.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(child: Text('No hay productos con esos filtros.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600))),
      );
    }
    final activos = [for (var i = 0; i < 3; i++) if (_niveles[i].valido) i];
    if (MediaQuery.of(context).size.width < 720) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final p = lista[i];
              final marcado = _seleccion.contains(p.id);
              final actuales = [p.precioVenta, p.precioVenta2, p.precioVenta3];
              return _tarjetaMovil(
                izquierda: Checkbox(value: marcado, activeColor: Marca.primario, onChanged: _aplicando ? null : (v) => setState(() => v == true ? _seleccion.add(p.id) : _seleccion.remove(p.id))),
                titulo: p.nombre,
                sub: [p.codigo, if (p.marca.isNotEmpty) p.marca].join(' · '),
                costo: p.precioCompra,
                impuesto: p.impuestoPorcentaje,
                niveles: [for (final n in activos) (nivel: n + 1, pct: _niveles[n].porcentaje.text.trim(), r: _calc(p, n)!, actual: actuales[n])],
                marcado: marcado,
                onTap: _aplicando ? null : () => setState(() => marcado ? _seleccion.remove(p.id) : _seleccion.add(p.id)),
              );
            },
          ),
        ),
      );
    }
    const anchoFijo = 48.0 + 92 + 70;
    return LayoutBuilder(builder: (context, restr) {
    final disponible = restr.maxWidth - 48;
    final anchoProducto = (disponible - anchoFijo - activos.length * _anchoNivel).clamp(260.0, 1000.0);
    final anchoTotal = anchoFijo + anchoProducto + activos.length * _anchoNivel;
    final encabezado = Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: const Color(0xFFECEEF3),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 48),
          _celdaTexto('Producto', anchoProducto, negrita: true, color: Colors.grey.shade700, alineacion: Alignment.centerLeft, multilinea: true),
          _celdaTexto('Costo', 92, negrita: true, color: Colors.grey.shade700, multilinea: true),
          _celdaTexto('ISV', 70, negrita: true, color: Colors.grey.shade700, multilinea: true),
          for (final i in activos) ..._encabezadoNivel(i + 1, _niveles[i].porcentaje.text.trim(), conActual: true),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _ScrollHorizontal(
          child: SizedBox(
            width: anchoTotal,
            child: Column(
              children: [
                encabezado,
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final p = lista[i];
                      final marcado = _seleccion.contains(p.id);
                      final actuales = [p.precioVenta, p.precioVenta2, p.precioVenta3];
                      return InkWell(
                        onTap: _aplicando ? null : () => setState(() => marcado ? _seleccion.remove(p.id) : _seleccion.add(p.id)),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 40),
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(color: marcado ? Marca.primario.withOpacity(0.05) : null, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Checkbox(
                                  value: marcado,
                                  activeColor: Marca.primario,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: _aplicando ? null : (v) => setState(() => v == true ? _seleccion.add(p.id) : _seleccion.remove(p.id)),
                                ),
                              ),
                              SizedBox(
                                width: anchoProducto,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nombre, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text([p.codigo, if (p.marca.isNotEmpty) p.marca].join(' · '), style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ),
                              _celdaTexto(formatearMoneda(p.precioCompra), 92),
                              _celdaTexto('${p.impuestoPorcentaje.toStringAsFixed(p.impuestoPorcentaje == p.impuestoPorcentaje.roundToDouble() ? 0 : 2)}%', 70),
                              for (final n in activos) ..._celdasNivel(_calc(p, n)!, actuales[n]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }
}

class CalculadoraPrecioProductoDialog extends StatefulWidget {
  final double costo;
  final double impuesto;
  final bool soloPrecio1;

  const CalculadoraPrecioProductoDialog({super.key, required this.costo, this.impuesto = 15, this.soloPrecio1 = false});

  @override
  State<CalculadoraPrecioProductoDialog> createState() => _CalculadoraPrecioProductoDialogState();
}

class _CalculadoraPrecioProductoDialogState extends State<CalculadoraPrecioProductoDialog> {
  final List<NivelPrecio> _niveles = _nivelesDesdeMemoria();
  RedondeoPrecio _redondeo = _MemoriaFormula.redondeo;

  @override
  void dispose() {
    _guardarMemoria(_niveles, _redondeo);
    for (final n in _niveles) {
      n.porcentaje.dispose();
    }
    super.dispose();
  }

  int get _cantidad => widget.soloPrecio1 ? 1 : 3;
  bool get _hayValido => [for (var i = 0; i < _cantidad; i++) _niveles[i]].any((n) => n.valido);
  bool get _hayIncompleto => [for (var i = 0; i < _cantidad; i++) _niveles[i]].any((n) => n.activo && !n.valido);

  PrecioCalculado? _calc(int i) {
    final n = _niveles[i];
    if (!n.valido) return null;
    return calcularPrecio(costo: widget.costo, porcentaje: n.valor!, impuesto: widget.impuesto, redondeo: _redondeo);
  }

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    final esMovil = tamano.width < 720;
    final activos = [for (var i = 0; i < _cantidad; i++) if (_niveles[i].valido) i];
    final anchoTabla = 92.0 + 70 + activos.length * (_anchoNivel - 92);
    final puedeUsar = widget.costo > 0 && _hayValido && !_hayIncompleto;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: esMovil ? tamano.width - 32 : 760,
        constraints: BoxConstraints(maxHeight: tamano.height - 60),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Marca.primario.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.calculate_outlined, color: Marca.primario),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Calculadora de precios', style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PanelFormula(
                      niveles: _niveles,
                      cantidadNiveles: _cantidad,
                      redondeo: _redondeo,
                      bloqueado: false,
                      onCambio: () => setState(() {}),
                      onRedondeo: (v) => setState(() => _redondeo = v),
                    ),
                    const SizedBox(height: 14),
                    if (widget.costo <= 0)
                      Text('Primero escribe el precio de compra (costo) del producto.', style: GoogleFonts.poppins(fontSize: 12.5, color: Marca.primario))
                    else if (activos.isEmpty)
                      Text('Marca un precio y escribe su porcentaje para ver el cálculo.', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600))
                    else if (esMovil)
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
                        child: _tarjetaMovil(
                          titulo: 'Este producto',
                          sub: '',
                          costo: widget.costo,
                          impuesto: widget.impuesto,
                          niveles: [for (final i in activos) (nivel: i + 1, pct: _niveles[i].porcentaje.text.trim(), r: _calc(i)!, actual: null)],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: anchoTabla,
                              child: Column(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(minHeight: 52),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    color: const Color(0xFFECEEF3),
                                    child: Row(
                                      children: [
                                        _celdaTexto('Costo', 92, negrita: true, color: Colors.grey.shade700),
                                        _celdaTexto('Impuesto', 70, negrita: true, color: Colors.grey.shade700),
                                        for (final i in activos) ..._encabezadoNivel(i + 1, _niveles[i].porcentaje.text.trim(), conActual: false),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minHeight: 50),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        _celdaTexto(formatearMoneda(widget.costo), 92),
                                        _celdaTexto('${widget.impuesto.toStringAsFixed(widget.impuesto == widget.impuesto.roundToDouble() ? 0 : 2)}%', 70),
                                        for (final i in activos) ..._celdasNivel(_calc(i)!, null),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB6BCC7)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancelar', style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: puedeUsar ? () => Navigator.pop(context, <double?>[_calc(0)?.guardado, _cantidad > 1 ? _calc(1)?.guardado : null, _cantidad > 1 ? _calc(2)?.guardado : null]) : null,
                    style: FilledButton.styleFrom(backgroundColor: Marca.primario, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(esMovil ? 'Usar precios' : 'Usar estos precios', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineaCalculoCompra {
  final String nombre;
  final String codigo;
  final double costo;
  final double impuesto;
  final double precioActual;

  const LineaCalculoCompra({
    required this.nombre,
    required this.codigo,
    required this.costo,
    required this.impuesto,
    required this.precioActual,
  });
}

class CalculadoraPreciosCompraDialog extends StatefulWidget {
  final List<LineaCalculoCompra> lineas;

  const CalculadoraPreciosCompraDialog({super.key, required this.lineas});

  @override
  State<CalculadoraPreciosCompraDialog> createState() => _CalculadoraPreciosCompraDialogState();
}

class _CalculadoraPreciosCompraDialogState extends State<CalculadoraPreciosCompraDialog> {
  final List<NivelPrecio> _niveles = _nivelesDesdeMemoria();
  RedondeoPrecio _redondeo = _MemoriaFormula.redondeo;

  @override
  void dispose() {
    _guardarMemoria(_niveles, _redondeo);
    for (final n in _niveles) {
      n.porcentaje.dispose();
    }
    super.dispose();
  }

  NivelPrecio get _nivel => _niveles[0];

  PrecioCalculado _calc(LineaCalculoCompra l) =>
      calcularPrecio(costo: l.costo, porcentaje: _nivel.valor!, impuesto: l.impuesto, redondeo: _redondeo);

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    final listo = _nivel.valido;
    const fijos = 92.0 + 70;
    const nivel = _anchoNivel;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(tamano.width < 720 ? 8 : 16),
      child: Container(
        width: tamano.width - (tamano.width < 720 ? 16 : 32),
        constraints: BoxConstraints(maxHeight: tamano.height - 32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Marca.primario.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.calculate_outlined, color: Marca.primario),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Calcular precios de venta de la compra', style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
              child: _PanelFormula(
                niveles: _niveles,
                cantidadNiveles: 1,
                redondeo: _redondeo,
                bloqueado: false,
                onCambio: () => setState(() {}),
                onRedondeo: (v) => setState(() => _redondeo = v),
              ),
            ),
            Flexible(
              child: !listo
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Marca el Precio 1 y escribe su porcentaje para ver el cálculo.', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
                    )
                  : tamano.width < 720
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.lineas.length,
                          itemBuilder: (context, i) {
                            final l = widget.lineas[i];
                            return _tarjetaMovil(
                              titulo: l.nombre,
                              sub: l.codigo,
                              costo: l.costo,
                              impuesto: l.impuesto,
                              niveles: [(nivel: 1, pct: _nivel.porcentaje.text.trim(), r: _calc(l), actual: l.precioActual)],
                            );
                          },
                        ),
                      ),
                    )
                  : LayoutBuilder(builder: (context, restr) {
                      final disponible = restr.maxWidth - 48;
                      final anchoProducto = (disponible - fijos - nivel).clamp(260.0, 1000.0);
                      final anchoTotal = anchoProducto + fijos + nivel;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7CBD3))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _ScrollHorizontal(
                            child: SizedBox(
                              width: anchoTotal,
                              child: Column(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(minHeight: 52),
                                    color: const Color(0xFFECEEF3),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        _celdaTexto('Producto', anchoProducto, negrita: true, color: Colors.grey.shade700, alineacion: Alignment.centerLeft, multilinea: true),
                                        _celdaTexto('Costo', 92, negrita: true, color: Colors.grey.shade700, multilinea: true),
                                        _celdaTexto('ISV', 70, negrita: true, color: Colors.grey.shade700, multilinea: true),
                                        ..._encabezadoNivel(1, _nivel.porcentaje.text.trim(), conActual: true),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: widget.lineas.length,
                                      itemBuilder: (context, i) {
                                        final l = widget.lineas[i];
                                        return Container(
                                          constraints: const BoxConstraints(minHeight: 52),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: anchoProducto,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(l.nombre, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                                      Text(l.codigo, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              _celdaTexto(formatearMoneda(l.costo), 92),
                                              _celdaTexto('${l.impuesto.toStringAsFixed(l.impuesto == l.impuesto.roundToDouble() ? 0 : 2)}%', 70),
                                              ..._celdasNivel(_calc(l), l.precioActual),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB6BCC7)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancelar', style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: listo ? () => Navigator.pop(context, widget.lineas.map((l) => _calc(l).guardado).toList()) : null,
                    style: FilledButton.styleFrom(backgroundColor: Marca.primario, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(tamano.width < 720 ? 'Aplicar a ${widget.lineas.length}' : 'Aplicar a los ${widget.lineas.length} productos', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
