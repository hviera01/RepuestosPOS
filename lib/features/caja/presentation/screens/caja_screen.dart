import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/marca.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/widgets/pdf_preview_dialog.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../data/caja_export_service.dart';
import '../../data/caja_model.dart';
import '../../providers/caja_provider.dart';

enum _ModoApertura { ahora, ultimoCierre, personalizada }

class CajaScreen extends ConsumerStatefulWidget {
  const CajaScreen({super.key});

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen> with SingleTickerProviderStateMixin {
  final _export = CajaExportService();
  final _fondoController = TextEditingController(text: '0');
  final _notasController = TextEditingController();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  CajaModel? _caja;
  List<CajaModel> _historial = [];
  bool _cargando = true;
  bool _ocupado = false;
  String? _error;
  _ModoApertura _modo = _ModoApertura.ahora;
  DateTime _fechaPersonalizada = DateTime.now();
  DateTime? _ultimoCierre;
  DateTimeRange _rango = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  String get _usuario => ref.read(authProvider).usuario?.nombreCompleto ?? '';
  bool get _esAdmin => ref.read(authProvider).usuario?.rol == 'Administrador';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _fondoController.dispose();
    _notasController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final repo = ref.read(cajaRepositoryProvider);
    try {
      final caja = await repo.cajaAbiertaDe(_usuario);
      final ultimo = caja == null ? await repo.ultimoCierreDe(_usuario) : null;
      final fin = DateTime(_rango.end.year, _rango.end.month, _rango.end.day, 23, 59, 59);
      final historial = await repo.historial(
        desde: DateTime(_rango.start.year, _rango.start.month, _rango.start.day),
        hasta: fin,
        usuario: _esAdmin ? null : _usuario,
      );
      if (!mounted) return;
      setState(() {
        _caja = caja;
        _ultimoCierre = ultimo;
        _historial = historial;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? Marca.primario : null),
    );
  }

  Future<DateTime?> _elegirFechaHora(DateTime inicial) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha == null || !mounted) return null;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(inicial));
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _abrirCaja() async {
    final fondo = double.tryParse(_fondoController.text.replaceAll(',', '.').trim());
    if (fondo == null || fondo < 0) {
      _mensaje('Escriba un fondo inicial válido (puede ser 0).', error: true);
      return;
    }
    DateTime desde;
    switch (_modo) {
      case _ModoApertura.ahora:
        desde = DateTime.now();
      case _ModoApertura.ultimoCierre:
        if (_ultimoCierre == null) {
          _mensaje('Todavía no tiene un cierre anterior.', error: true);
          return;
        }
        desde = _ultimoCierre!;
      case _ModoApertura.personalizada:
        desde = _fechaPersonalizada;
    }
    setState(() => _ocupado = true);
    try {
      final caja = await ref.read(cajaRepositoryProvider).abrir(
            usuario: _usuario,
            monto: fondo,
            notas: _notasController.text.trim(),
            abiertaEn: desde,
          );
      _notasController.clear();
      if (!mounted) return;
      setState(() => _caja = caja);
      _mensaje('Caja abierta.');
      _cargar();
    } catch (e) {
      _mensaje('$e', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _actualizar() async {
    final actual = _caja;
    if (actual == null) return;
    setState(() => _ocupado = true);
    try {
      final caja = await ref.read(cajaRepositoryProvider).resumen(actual.id);
      if (mounted) setState(() => _caja = caja);
    } catch (e) {
      _mensaje('$e', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _imprimir(CajaModel caja) async {
    final negocio = await ref.read(negocioRepositoryProvider).obtenerNegocioActual();
    if (!mounted) return;
    final tipo = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(caja.abierta ? 'Corte X' : 'Corte Z'),
        content: const Text('¿Cómo desea el reporte?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, 'pdf'), child: const Text('PDF')),
          FilledButton(onPressed: () => Navigator.pop(context, 'ticket'), child: const Text('Ticket')),
        ],
      ),
    );
    if (tipo == null || !mounted) return;
    if (tipo == 'ticket') {
      final impresora = negocio.impresoraTermicaUrl.isEmpty
          ? null
          : Printer(url: negocio.impresoraTermicaUrl, name: negocio.impresoraTermicaNombre);
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => PdfPreviewDialog(
          titulo: 'Ticket · ${caja.abierta ? 'Corte X' : 'Corte Z'}',
          nombreArchivo: 'caja_ticket.pdf',
          generarPdf: () => _export.generarTicket(caja, negocio),
          generarPdfConFormato: (formato) => _export.generarTicket(caja, negocio, formatoImpresora: formato),
          impresora: impresora,
        ),
      );
    } else {
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => PdfPreviewDialog(
          titulo: 'Vista previa · ${caja.abierta ? 'Corte X' : 'Corte Z'}',
          nombreArchivo: 'caja.pdf',
          generarPdf: () => _export.generarPdf(caja, negocio),
        ),
      );
    }
  }

  Future<void> _cerrarCaja() async {
    final actual = _caja;
    if (actual == null) return;
    await _actualizar();
    final fresca = _caja;
    if (fresca == null || !mounted) return;
    final resultado = await showDialog<_ResultadoCierre>(
      useRootNavigator: false,
      context: context,
      builder: (context) => _CerrarCajaDialog(caja: fresca),
    );
    if (resultado == null || !mounted) return;
    setState(() => _ocupado = true);
    try {
      final cerrada = await ref.read(cajaRepositoryProvider).cerrar(
            id: fresca.id,
            montoContado: resultado.contado,
            notas: resultado.notas,
            usuario: _usuario,
          );
      if (!mounted) return;
      setState(() {
        _caja = null;
        _ocupado = false;
      });
      _mensaje('Caja cerrada.');
      await _cargar();
      if (!mounted) return;
      await _imprimir(cerrada);
    } catch (e) {
      _mensaje('$e', error: true);
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _reabrir(CajaModel caja) async {
    final confirmar = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reabrir caja'),
        content: const Text('La caja volverá a quedar abierta y se borrará el conteo del cierre. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reabrir')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(cajaRepositoryProvider).reabrir(caja.id);
      _mensaje('Caja reabierta.');
      await _cargar();
      _tabs.animateTo(0);
    } catch (e) {
      _mensaje('$e', error: true);
    }
  }

  Future<void> _verDetalle(CajaModel caja) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Caja de ${caja.usuario}'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: _ResumenCaja(caja: caja, formatoFecha: _formatoFecha))),
        actions: [
          if (!caja.abierta && (_esAdmin || caja.usuario == _usuario) && _historial.isNotEmpty && _historial.first.id == caja.id)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reabrir(caja);
              },
              child: const Text('Reabrir'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _imprimir(caja);
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  Widget _vistaApertura() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tarjeta(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Abrir caja', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'No tiene una caja abierta. Indique con cuánto efectivo empieza y desde cuándo se cuentan sus ventas.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fondoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fondo inicial en efectivo (L)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              Text('Contar mis ventas desde', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<_ModoApertura>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _ModoApertura.ahora, label: Text('Ahora')),
                  ButtonSegment(value: _ModoApertura.ultimoCierre, label: Text('Último cierre')),
                  ButtonSegment(value: _ModoApertura.personalizada, label: Text('Otra fecha')),
                ],
                selected: {_modo},
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
              if (_modo == _ModoApertura.ultimoCierre)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _ultimoCierre == null
                        ? 'Todavía no tiene un cierre anterior.'
                        : 'Desde ${_formatoFecha.format(_ultimoCierre!)}',
                    style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700),
                  ),
                ),
              if (_modo == _ModoApertura.personalizada)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await _elegirFechaHora(_fechaPersonalizada);
                      if (f != null) setState(() => _fechaPersonalizada = f);
                    },
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(_formatoFecha.format(_fechaPersonalizada)),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _notasController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas (opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _ocupado ? null : _abrirCaja,
                  icon: const Icon(Icons.lock_open_outlined, size: 18),
                  label: const Text('Abrir caja'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vistaAbierta(CajaModel caja) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _actualizar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : () => _imprimir(caja),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Corte X'),
            ),
            FilledButton.icon(
              onPressed: _ocupado ? null : _cerrarCaja,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Cerrar caja (Corte Z)'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _tarjeta(_ResumenCaja(caja: caja, formatoFecha: _formatoFecha)),
      ],
    );
  }

  Widget _tarjeta(Widget hijo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E2E8)),
      ),
      child: hijo,
    );
  }

  Widget _vistaHistorial() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _rango,
                  );
                  if (r == null) return;
                  setState(() => _rango = r);
                  _cargar();
                },
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text('${DateFormat('dd/MM/yyyy').format(_rango.start)} - ${DateFormat('dd/MM/yyyy').format(_rango.end)}'),
              ),
              const Spacer(),
              Text('${_historial.length} cajas', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Expanded(
          child: _historial.isEmpty
              ? Center(child: Text('No hay cajas en este rango.', style: GoogleFonts.poppins(color: Colors.grey.shade600)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historial.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = _historial[i];
                    final color = c.abierta
                        ? const Color(0xFF2E7D32)
                        : (c.diferencia.abs() < 0.01 ? Colors.grey.shade700 : const Color(0xFFC62828));
                    return InkWell(
                      onTap: () => _verDetalle(c),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E2E8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.usuario, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                  Text(
                                    '${_formatoFecha.format(c.abiertaEn)} → ${c.cerradaEn == null ? 'abierta' : _formatoFecha.format(c.cerradaEn!)}',
                                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatearMoneda(c.totalVentas), style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                Text(
                                  c.abierta ? 'Abierta' : 'Dif. ${formatearMoneda(c.diferencia)}',
                                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Caja', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Mi caja'), Tab(text: 'Historial de cajas')]),
        actions: [IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh), tooltip: 'Recargar')],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _caja == null ? _vistaApertura() : _vistaAbierta(_caja!),
                    _vistaHistorial(),
                  ],
                ),
    );
  }
}

class _ResumenCaja extends StatelessWidget {
  final CajaModel caja;
  final DateFormat formatoFecha;

  const _ResumenCaja({required this.caja, required this.formatoFecha});

  Widget _fila(String etiqueta, double valor, {bool fuerte = false, Color? color}) {
    final estilo = GoogleFonts.poppins(
      fontSize: fuerte ? 14.5 : 13,
      fontWeight: fuerte ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(formatearMoneda(valor), style: estilo),
        ],
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(t.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.grey.shade600)),
      );

  @override
  Widget build(BuildContext context) {
    final c = caja;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abierta ${formatoFecha.format(c.abiertaEn)}${c.cerradaEn == null ? '' : '  ·  Cerrada ${formatoFecha.format(c.cerradaEn!)}'}',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (c.notas.isNotEmpty) Text('Notas: ${c.notas}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
        _titulo('Efectivo en caja'),
        _fila('Fondo inicial', c.montoApertura),
        _fila('Ventas en efectivo', c.ventasEfectivo),
        _fila('Abonos en efectivo', c.abonosEfectivo),
        _fila('Gastos en efectivo', -c.gastos),
        _fila('Pagos a proveedores en efectivo', -c.pagosProveedores),
        _fila('Compras en efectivo', -c.comprasEfectivo),
        const Divider(height: 18),
        _fila('Efectivo esperado', c.efectivoEsperado, fuerte: true),
        if (!c.abierta) ...[
          _fila('Efectivo contado', c.montoCierre ?? 0, fuerte: true),
          _fila(
            'Diferencia',
            c.diferencia,
            fuerte: true,
            color: c.diferencia.abs() < 0.01 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          if (c.notasCierre.isNotEmpty) Text('Notas de cierre: ${c.notasCierre}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
        ],
        _titulo('Ventas (${c.cantidadVentas})'),
        _fila('Efectivo', c.ventasEfectivo),
        _fila('Tarjeta', c.ventasTarjeta),
        _fila('Transferencia', c.ventasTransferencia),
        _fila('Cheque', c.ventasCheque),
        _fila('Crédito', c.ventasCredito),
        const Divider(height: 18),
        _fila('Total ventas', c.totalVentas, fuerte: true),
        _fila('Abonos con otros métodos', c.abonosOtros),
      ],
    );
  }
}

class _ResultadoCierre {
  final double contado;
  final String notas;

  const _ResultadoCierre(this.contado, this.notas);
}

class _CerrarCajaDialog extends StatefulWidget {
  final CajaModel caja;

  const _CerrarCajaDialog({required this.caja});

  @override
  State<_CerrarCajaDialog> createState() => _CerrarCajaDialogState();
}

class _CerrarCajaDialogState extends State<_CerrarCajaDialog> {
  static const _denominaciones = <double>[500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1, 0.05];

  final _cantidades = {for (final d in _denominaciones) d: TextEditingController()};
  final _directoController = TextEditingController();
  final _notasController = TextEditingController();
  bool _porDenominacion = true;
  String? _error;

  @override
  void dispose() {
    for (final c in _cantidades.values) {
      c.dispose();
    }
    _directoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _contado {
    if (!_porDenominacion) return double.tryParse(_directoController.text.replaceAll(',', '.').trim()) ?? 0;
    var total = 0.0;
    _cantidades.forEach((d, c) {
      total += d * (int.tryParse(c.text.trim()) ?? 0);
    });
    return double.parse(total.toStringAsFixed(2));
  }

  double get _diferencia => double.parse((_contado - widget.caja.efectivoEsperado).toStringAsFixed(2));

  void _confirmar() {
    if (_diferencia.abs() >= 0.01 && _notasController.text.trim().isEmpty) {
      setState(() => _error = 'Hay una diferencia: escriba una nota explicándola.');
      return;
    }
    Navigator.pop(context, _ResultadoCierre(_contado, _notasController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final dif = _diferencia;
    final color = dif.abs() < 0.01 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return AlertDialog(
      title: const Text('Cerrar caja (Corte Z)'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Efectivo esperado: ${formatearMoneda(widget.caja.efectivoEsperado)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Contar billetes')),
                  ButtonSegment(value: false, label: Text('Escribir total')),
                ],
                selected: {_porDenominacion},
                onSelectionChanged: (s) => setState(() => _porDenominacion = s.first),
              ),
              const SizedBox(height: 10),
              if (_porDenominacion)
                for (final d in _denominaciones)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 90, child: Text(d >= 1 ? 'L ${d.toStringAsFixed(0)}' : 'L ${d.toStringAsFixed(2)}')),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _cantidades[d],
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() => _error = null),
                              decoration: const InputDecoration(hintText: 'cantidad', isDense: true, border: OutlineInputBorder()),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            formatearMoneda(d * (int.tryParse(_cantidades[d]!.text.trim()) ?? 0)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )
              else
                TextField(
                  controller: _directoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(labelText: 'Efectivo contado (L)', border: OutlineInputBorder()),
                ),
              const Divider(height: 22),
              Text('Efectivo contado: ${formatearMoneda(_contado)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              Text(
                'Diferencia: ${formatearMoneda(dif)}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notasController,
                maxLines: 2,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: dif.abs() >= 0.01 ? 'Notas (obligatorias por la diferencia)' : 'Notas (opcional)',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirmar, child: const Text('Cerrar caja')),
      ],
    );
  }
}
