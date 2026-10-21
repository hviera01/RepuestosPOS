import '../../../../core/theme/marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../reportes/data/reporte_compra_model.dart';
import '../../../reportes/providers/reportes_provider.dart';
import '../../../../core/utils/texto_utils.dart';
import '../../../../core/utils/formato_moneda.dart';
import 'detalle_compra_screen.dart';

class VerComprasScreen extends ConsumerStatefulWidget {
  const VerComprasScreen({super.key});

  @override
  ConsumerState<VerComprasScreen> createState() => _VerComprasScreenState();
}

class _VerComprasScreenState extends ConsumerState<VerComprasScreen> {
  final _busquedaController = TextEditingController();
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  String _busqueda = '';
  String? _estadoFiltro;
  String? _condicionFiltro;
  bool _cargando = false;
  String? _error;
  List<ReporteCompraModel>? _compras;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaInicio = DateTime(hoy.year, hoy.month, hoy.day);
    _fechaFin = DateTime(hoy.year, hoy.month, hoy.day);
    _buscar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final fin = DateTime(_fechaFin.year, _fechaFin.month, _fechaFin.day, 23, 59, 59);
      final compras = await ref.read(reporteRepositoryProvider).obtenerReporteCompras(_fechaInicio, fin);
      if (mounted) setState(() => _compras = compras);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar la lista');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _verDetalle(ReporteCompraModel compra) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => DetalleCompraScreen(compraIdInicial: compra.id)),
    );
  }

  void _aplicarRango(DateTime inicio, DateTime fin) {
    setState(() {
      _fechaInicio = inicio;
      _fechaFin = fin;
    });
    _buscar();
  }

  Future<void> _elegirFecha(bool inicio) async {
    final f = await showDatePicker(
      context: context,
      initialDate: inicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (f == null) return;
    setState(() {
      if (inicio) {
        _fechaInicio = f;
        if (_fechaFin.isBefore(f)) _fechaFin = f;
      } else {
        _fechaFin = f;
        if (_fechaInicio.isAfter(f)) _fechaInicio = f;
      }
    });
    _buscar();
  }

  List<ReporteCompraModel> get _filtradas {
    final base = _compras ?? const <ReporteCompraModel>[];
    final tokens = normalizarTexto(_busqueda).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    return base.where((c) {
      if (_estadoFiltro != null && c.estado != _estadoFiltro) return false;
      if (_condicionFiltro != null && c.condicion != _condicionFiltro) return false;
      if (tokens.isEmpty) return true;
      final texto = normalizarTexto(c.textoBusqueda);
      return tokens.every(texto.contains);
    }).toList()
      ..sort((a, b) => (b.fechaRegistro ?? DateTime(2000)).compareTo(a.fechaRegistro ?? DateTime(2000)));
  }

  Widget _chipRango(String etiqueta, DateTime inicio, DateTime fin) {
    final activo = _fechaInicio == inicio && _fechaFin == fin;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(etiqueta, style: GoogleFonts.poppins(fontSize: 12.5, color: activo ? Marca.sobrePrimario : null)),
        selected: activo,
        selectedColor: Marca.primario,
        showCheckmark: false,
        onSelected: (_) => _aplicarRango(inicio, fin),
      ),
    );
  }

  Widget _botonFecha(String etiqueta, DateTime fecha, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 15),
      label: Text('$etiqueta: ${DateFormat('dd/MM/yyyy').format(fecha)}', style: GoogleFonts.poppins(fontSize: 12.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final hoyDia = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = hoyDia.subtract(const Duration(days: 1));
    final lista = _filtradas;
    final total = lista.where((c) => c.esActiva).fold<double>(0, (s, c) => s + c.montoTotal);
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: Text('Compras', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [IconButton(onPressed: _buscar, icon: const Icon(Icons.refresh), tooltip: 'Actualizar')],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipRango('Hoy', hoyDia, hoyDia),
                  _chipRango('Ayer', ayer, ayer),
                  _chipRango('7 días', hoyDia.subtract(const Duration(days: 6)), hoyDia),
                  _chipRango('Este mes', DateTime(hoy.year, hoy.month, 1), hoyDia),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _botonFecha('Desde', _fechaInicio, () => _elegirFecha(true)),
                _botonFecha('Hasta', _fechaFin, () => _elegirFecha(false)),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _busquedaController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Proveedor, factura o número',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) => setState(() => _busqueda = v.trim()),
                  ),
                ),
                DropdownButton<String?>(
                  value: _estadoFiltro,
                  hint: const Text('Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos los estados')),
                    DropdownMenuItem(value: 'Activa', child: Text('Activas')),
                    DropdownMenuItem(value: 'Anulada', child: Text('Anuladas')),
                  ],
                  onChanged: (v) => setState(() => _estadoFiltro = v),
                ),
                DropdownButton<String?>(
                  value: _condicionFiltro,
                  hint: const Text('Condición'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Contado y crédito')),
                    DropdownMenuItem(value: 'Contado', child: Text('Contado')),
                    DropdownMenuItem(value: 'Credito', child: Text('Crédito')),
                  ],
                  onChanged: (v) => setState(() => _condicionFiltro = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${lista.length} compras · total ${formatearMoneda(total)}', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando && _compras == null
                  ? Center(child: CircularProgressIndicator(color: Marca.primario))
                  : _error != null
                      ? Center(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red)))
                      : lista.isEmpty
                          ? Center(child: Text('No hay compras en este rango', style: GoogleFonts.poppins(color: Colors.grey.shade500)))
                          : ListView.separated(
                              itemCount: lista.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final c = lista[i];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _verDetalle(c),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFD5D8DF)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.razonSocial.isEmpty ? 'Sin proveedor' : c.razonSocial,
                                                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700),
                                              ),
                                              Text(
                                                '${c.numeroDocumento} · Factura ${c.noFactura.isEmpty ? '-' : c.noFactura} · ${c.fechaRegistro == null ? '-' : formatoFecha.format(c.fechaRegistro!)}',
                                                style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(formatearMoneda(c.montoTotal), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                                            Text(
                                              c.esActiva ? (c.condicion == 'Credito' ? 'Crédito' : 'Contado') : 'Anulada',
                                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.esActiva ? Colors.grey.shade600 : const Color(0xFFC62828)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
    );
  }
}
