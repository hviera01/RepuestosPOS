import '../../../../core/services/recibos_tickets.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/roles.dart';
import '../../../../core/theme/marca.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/widgets/pdf_preview_dialog.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../negocio/data/negocio_model.dart';
import '../../../negocio/presentation/widgets/acceso_especial.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../../reportes/providers/reportes_provider.dart';
import '../../../resumen_dia/data/resumen_operaciones_model.dart';
import '../../data/caja_export_service.dart';
import '../../data/caja_model.dart';
import '../../providers/caja_provider.dart';

final _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
final _formatoDia = DateFormat('dd/MM/yyyy');
final _formatoHora = DateFormat('HH:mm');

DateTime _inicioDelDia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _finDelDia(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

class CajaScreen extends ConsumerStatefulWidget {
  const CajaScreen({super.key});

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen> with SingleTickerProviderStateMixin {
  final _export = CajaExportService();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  Timer? _debounce;

  CajaModel? _caja;
  List<CajaModel> _historial = [];
  bool _cargando = true;
  bool _ocupado = false;
  String? _error;
  DateTime? _ultimoCierre;
  DateTime _historialDesde = _inicioDelDia(DateTime.now());
  DateTime _historialHasta = _finDelDia(DateTime.now());

  String get _usuario => ref.read(authProvider).usuario?.nombreCompleto ?? '';
  bool get _esAdmin => ref.read(authProvider).usuario?.rol == Roles.administrador;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    final repo = ref.read(cajaRepositoryProvider);
    try {
      final caja = await repo.cajaAbiertaDe(_usuario);
      final ultimo = caja == null ? await repo.ultimoCierreDe(_usuario) : _ultimoCierre;
      final historial = await repo.historial(
        desde: _historialDesde,
        hasta: _historialHasta,
        usuario: _esAdmin ? null : _usuario,
      );
      if (!mounted) return;
      setState(() {
        _caja = caja;
        _ultimoCierre = ultimo;
        _historial = historial;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _programarRefresco() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted && !_ocupado) _cargar(silencioso: true);
    });
  }

  void _escuchar(String tabla) {
    ref.listen<AsyncValue<void>>(cambiosEnTablaProvider(tabla), (previous, next) {
      if (!next.hasValue || !mounted) return;
      _programarRefresco();
    });
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto), backgroundColor: Marca.primario));
  }

  Future<void> _abrirCaja(_DatosCaja datos) async {
    setState(() => _ocupado = true);
    try {
      final caja = await ref.read(cajaRepositoryProvider).abrir(
            usuario: _usuario,
            monto: datos.monto,
            notas: datos.notas,
            desde: datos.desde,
            hasta: datos.hasta,
            config: datos.config,
          );
      if (mounted) setState(() => _caja = caja);
      await _cargar(silencioso: true);
    } catch (e) {
      _mensaje('$e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _editarCaja() async {
    final actual = _caja;
    if (actual == null) return;
    final acceso = await verificarAccesoEspecial(context, ref, PermisosEspeciales.cajaEditar);
    if (!acceso.autorizado || !mounted) return;
    final datos = await showDialog<_DatosCaja>(
      useRootNavigator: false,
      context: context,
      builder: (context) => _EditarCajaDialog(caja: actual, esAdmin: _esAdmin, ultimoCierre: _ultimoCierre),
    );
    if (datos == null || !mounted) return;
    setState(() => _ocupado = true);
    try {
      final caja = await ref.read(cajaRepositoryProvider).editar(
            id: actual.id,
            monto: datos.monto,
            desde: datos.desde,
            hasta: datos.hasta,
            notas: datos.notas,
            config: datos.config,
          );
      if (mounted) setState(() => _caja = caja);
    } catch (e) {
      _mensaje('$e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cambiarConfig(CajaConfig config) async {
    final actual = _caja;
    if (actual == null) return;
    try {
      final caja = await ref.read(cajaRepositoryProvider).editar(
            id: actual.id,
            monto: actual.montoApertura,
            desde: actual.abiertaEn,
            hasta: actual.hastaEn,
            notas: actual.notas,
            config: config,
          );
      if (mounted) setState(() => _caja = caja);
    } catch (e) {
      _mensaje('$e');
    }
  }

  Future<void> _imprimir(CajaModel caja) async {
    final negocio = await ref.read(negocioRepositoryProvider).obtenerNegocioActual();
    if (!mounted) return;
    final tipo = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cierre de caja'),
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
        builder: (context) => RecibosTickets.dialogo(
          titulo: 'Ticket · Cierre de caja',
          archivo: 'caja_ticket.pdf',
          pdf: () => _export.generarTicket(caja, negocio),
          copias: [_export.lineasTicket(caja, negocio)],
          negocio: negocio,
          impresora: impresora,
        ),
      );
    } else {
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => PdfPreviewDialog(
          titulo: 'Vista previa · Cierre de caja',
          nombreArchivo: 'caja.pdf',
          generarPdf: () => _export.generarPdf(caja, negocio),
        ),
      );
    }
  }

  Future<void> _cerrarCaja() async {
    final actual = _caja;
    if (actual == null) return;
    await _cargar(silencioso: true);
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
      await _cargar(silencioso: true);
      if (!mounted) return;
      await _imprimir(cerrada);
    } catch (e) {
      _mensaje('$e');
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
      await _cargar(silencioso: true);
      _tabs.animateTo(0);
    } catch (e) {
      _mensaje('$e');
    }
  }

  Future<void> _verMovimientos(CajaModel caja) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => _MovimientosDialog(caja: caja),
    );
  }

  Future<void> _verDetalle(CajaModel caja) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Caja de ${caja.usuario}'),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: _ResumenCaja(caja: caja))),
        actions: [
          if (!caja.abierta && (_esAdmin || caja.usuario == _usuario) && _historial.isNotEmpty && _historial.first.id == caja.id)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reabrir(caja);
              },
              child: const Text('Reabrir'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _verMovimientos(caja);
            },
            child: const Text('Ver movimientos'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          if (!caja.abierta)
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

  Widget _vistaApertura() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tarjeta(
          _FormularioCaja(
            titulo: 'Abrir caja',
            subtitulo: 'Indique con cuánto efectivo empieza y qué periodo se cuenta. Todo se puede cambiar después.',
            textoBoton: 'Abrir caja',
            esAdmin: _esAdmin,
            ultimoCierre: _ultimoCierre,
            ocupado: _ocupado,
            alConfirmar: _abrirCaja,
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
              onPressed: _ocupado ? null : _editarCaja,
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Fondo y periodo'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : () => _verMovimientos(caja),
              icon: const Icon(Icons.list_alt_outlined, size: 18),
              label: const Text('Ver movimientos'),
            ),
            FilledButton.icon(
              onPressed: _ocupado ? null : _cerrarCaja,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Cerrar caja'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _tarjeta(_ResumenCaja(caja: caja)),
        if (_esAdmin) ...[
          const SizedBox(height: 14),
          _tarjeta(_ConfigConteo(config: caja.config, alCambiar: _cambiarConfig)),
        ],
      ],
    );
  }

  Widget _cajaFecha(String etiqueta, DateTime fecha, ValueChanged<DateTime> alCambiar) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final f = await showDatePicker(context: context, initialDate: fecha, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (f != null) alCambiar(f);
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC9CDD6)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$etiqueta ${_formatoDia.format(fecha)}',
                style: GoogleFonts.poppins(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaHistorial() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _cajaFecha('Del', _historialDesde, (f) {
                setState(() {
                  _historialDesde = _inicioDelDia(f);
                  if (_historialHasta.isBefore(_historialDesde)) _historialHasta = _finDelDia(f);
                });
                _cargar(silencioso: true);
              }),
              _cajaFecha('al', _historialHasta, (f) {
                setState(() {
                  _historialHasta = _finDelDia(f);
                  if (_historialDesde.isAfter(_historialHasta)) _historialDesde = _inicioDelDia(f);
                });
                _cargar(silencioso: true);
              }),
              for (final (etiqueta, dias) in const [('Hoy', 0), ('Ayer', 1), ('7 días', 6), ('30 días', 29)])
                ActionChip(
                  label: Text(etiqueta, style: GoogleFonts.poppins(fontSize: 12)),
                  onPressed: () {
                    final hoy = DateTime.now();
                    setState(() {
                      _historialDesde = _inicioDelDia(hoy.subtract(Duration(days: dias)));
                      _historialHasta = etiqueta == 'Ayer' ? _finDelDia(hoy.subtract(const Duration(days: 1))) : _finDelDia(hoy);
                    });
                    _cargar(silencioso: true);
                  },
                ),
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
                    Widget caja(String t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDADDE4)),
                          ),
                          child: Text(t, style: GoogleFonts.poppins(fontSize: 11)),
                        );
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
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      caja(_formatoFecha.format(c.desdeEfectivo)),
                                      Text('a', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                                      caja(c.cerradaEn == null ? 'abierta' : _formatoFecha.format(c.hastaEn ?? c.cerradaEn!)),
                                    ],
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
    for (final tabla in const ['ventas', 'venta_credito_abonos', 'egresos', 'compras', 'compra_credito_abonos', 'cajas']) {
      _escuchar(tabla);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Caja', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Mi caja'), Tab(text: 'Historial de cajas')]),
        actions: [IconButton(onPressed: () => _cargar(), icon: const Icon(Icons.refresh), tooltip: 'Recargar')],
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

class _DatosCaja {
  final double monto;
  final DateTime desde;
  final DateTime? hasta;
  final String notas;
  final CajaConfig config;

  const _DatosCaja({required this.monto, required this.desde, required this.hasta, required this.notas, required this.config});
}

class _FormularioCaja extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final String textoBoton;
  final bool esAdmin;
  final DateTime? ultimoCierre;
  final bool ocupado;
  final CajaModel? inicial;
  final ValueChanged<_DatosCaja> alConfirmar;

  const _FormularioCaja({
    required this.titulo,
    required this.subtitulo,
    required this.textoBoton,
    required this.esAdmin,
    required this.ultimoCierre,
    required this.ocupado,
    required this.alConfirmar,
    this.inicial,
  });

  @override
  State<_FormularioCaja> createState() => _FormularioCajaState();
}

class _FormularioCajaState extends State<_FormularioCaja> {
  late final TextEditingController _fondo;
  late final TextEditingController _notas;
  late DateTime _desde;
  DateTime? _hasta;
  late CajaConfig _config;
  String _rapido = '';

  @override
  void initState() {
    super.initState();
    final c = widget.inicial;
    _fondo = TextEditingController(text: c == null ? '0' : c.montoApertura.toStringAsFixed(2));
    _notas = TextEditingController(text: c?.notas ?? '');
    _desde = c?.abiertaEn ?? DateTime.now();
    _hasta = c?.hastaEn;
    _config = c?.config ?? const CajaConfig();
    _rapido = c == null ? 'ahora' : '';
  }

  @override
  void dispose() {
    _fondo.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _aplicarRapido(String clave) {
    final ahora = DateTime.now();
    setState(() {
      _rapido = clave;
      switch (clave) {
        case 'ahora':
          _desde = ahora;
          _hasta = null;
        case 'hoy':
          _desde = _inicioDelDia(ahora);
          _hasta = null;
        case 'ayer':
          _desde = _inicioDelDia(ahora.subtract(const Duration(days: 1)));
          _hasta = _finDelDia(ahora.subtract(const Duration(days: 1)));
        case 'semana':
          _desde = _inicioDelDia(ahora.subtract(Duration(days: ahora.weekday - 1)));
          _hasta = null;
        case 'mes':
          _desde = DateTime(ahora.year, ahora.month, 1);
          _hasta = null;
        case 'cierre':
          _desde = widget.ultimoCierre ?? ahora;
          _hasta = null;
      }
    });
  }

  Future<DateTime?> _elegir(DateTime base) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: 'ELIJA LA HORA',
    );
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Widget _botonFechaHora(String etiqueta, DateTime? valor, VoidCallback onTap, {String vacio = 'En vivo (hasta ahora)'}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC9CDD6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Text(valor == null ? vacio : '${_formatoDia.format(valor)}  ${_formatoHora.format(valor)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmar() {
    final fondo = double.tryParse(_fondo.text.replaceAll(',', '.').trim());
    if (fondo == null || fondo < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Escriba un fondo inicial válido (puede ser 0).'), backgroundColor: Marca.primario));
      return;
    }
    if (_hasta != null && _hasta!.isBefore(_desde)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('La fecha final no puede ser anterior a la inicial.'), backgroundColor: Marca.primario));
      return;
    }
    widget.alConfirmar(_DatosCaja(monto: fondo, desde: _desde, hasta: _hasta, notas: _notas.text.trim(), config: _config));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.titulo, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(widget.subtitulo, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
        const SizedBox(height: 14),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _fondo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fondo inicial en efectivo', prefixText: 'L. ', border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(height: 14),
        Text('Periodo que se cuenta', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final (clave, etiqueta) in [
              ('ahora', 'Desde ahora'),
              ('hoy', 'Hoy'),
              ('ayer', 'Ayer'),
              ('semana', 'Esta semana'),
              ('mes', 'Este mes'),
              if (widget.ultimoCierre != null) ('cierre', 'Desde mi último cierre'),
            ])
              ChoiceChip(
                label: Text(etiqueta, style: GoogleFonts.poppins(fontSize: 12, color: _rapido == clave ? Marca.sobrePrimario : null)),
                selected: _rapido == clave,
                selectedColor: Marca.primario,
                showCheckmark: false,
                onSelected: (_) => _aplicarRapido(clave),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _botonFechaHora('Desde', _desde, () async {
              final f = await _elegir(_desde);
              if (f != null) setState(() {
                    _desde = f;
                    _rapido = '';
                  });
            }),
            _botonFechaHora('Hasta', _hasta, () async {
              final f = await _elegir(_hasta ?? DateTime.now());
              if (f != null) setState(() {
                    _hasta = f;
                    _rapido = '';
                  });
            }),
            if (_hasta != null)
              TextButton.icon(
                onPressed: () => setState(() => _hasta = null),
                icon: const Icon(Icons.all_inclusive, size: 16),
                label: const Text('Hasta ahora'),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _config.soloDesdeApertura,
          onChanged: (v) => setState(() => _config = _config.copyWith(soloDesdeApertura: v)),
          title: Text('Contar solo lo que pase desde que abro la caja', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('Si lo apaga, se cuenta todo lo del periodo elegido aunque haya pasado antes de abrir.', style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600)),
        ),
        if (widget.esAdmin) ...[
          const Divider(),
          _ConfigConteo(config: _config, alCambiar: (c) => setState(() => _config = c), compacto: true),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _notas,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notas (opcional)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.ocupado ? null : _confirmar,
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            label: Text(widget.textoBoton),
          ),
        ),
      ],
    );
  }
}

class _EditarCajaDialog extends StatelessWidget {
  final CajaModel caja;
  final bool esAdmin;
  final DateTime? ultimoCierre;

  const _EditarCajaDialog({required this.caja, required this.esAdmin, required this.ultimoCierre});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _FormularioCaja(
            titulo: 'Fondo y periodo de la caja',
            subtitulo: 'Cambie el fondo inicial, desde y hasta cuándo se cuenta, o lo que entra en el efectivo.',
            textoBoton: 'Guardar cambios',
            esAdmin: esAdmin,
            ultimoCierre: ultimoCierre,
            ocupado: false,
            inicial: caja,
            alConfirmar: (datos) => Navigator.pop(context, datos),
          ),
        ),
      ),
    );
  }
}

class _ConfigConteo extends StatelessWidget {
  final CajaConfig config;
  final ValueChanged<CajaConfig> alCambiar;
  final bool compacto;

  const _ConfigConteo({required this.config, required this.alCambiar, this.compacto = false});

  Widget _fila(String titulo, bool valor, CajaConfig Function(bool) nuevo) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: valor,
      onChanged: (v) => alCambiar(nuevo(v)),
      title: Text(titulo, style: GoogleFonts.poppins(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Qué se cuenta en el efectivo (solo administrador)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
        if (!compacto)
          Text('Lo que apague no entra en el cálculo del efectivo esperado. Se sigue mostrando en el resumen.', style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600)),
        _fila('Ventas en efectivo', config.ventasEfectivo, (v) => config.copyWith(ventasEfectivo: v)),
        _fila('Abonos de clientes en efectivo', config.abonosEfectivo, (v) => config.copyWith(abonosEfectivo: v)),
        _fila('Gastos pagados en efectivo', config.gastos, (v) => config.copyWith(gastos: v)),
        _fila('Pagos a proveedores en efectivo', config.pagosProveedores, (v) => config.copyWith(pagosProveedores: v)),
        _fila('Compras de contado en efectivo', config.comprasEfectivo, (v) => config.copyWith(comprasEfectivo: v)),
      ],
    );
  }
}

String _dinero(double v) => v < 0 ? '-${formatearMoneda(-v)}' : formatearMoneda(v);

class _ResumenCaja extends StatelessWidget {
  final CajaModel caja;

  const _ResumenCaja({required this.caja});

  Widget _tabla(String titulo, List<Widget> filas) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADDE4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFECEEF3),
            child: Text(titulo.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF4B4F58))),
          ),
          ...filas,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, double valor, int indice, {bool tenue = false, Color? color}) {
    final estilo = GoogleFonts.poppins(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: tenue ? Colors.grey.shade500 : color ?? const Color(0xFF1A1A1A),
      decoration: tenue ? TextDecoration.lineThrough : null,
    );
    return Container(
      color: indice.isEven ? Colors.white : const Color(0xFFF7F8FA),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          const SizedBox(width: 16),
          Text(_dinero(valor), style: estilo.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _total(String etiqueta, double valor, {Color? fondo, Color? texto}) {
    final estilo = GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w800, color: texto ?? Colors.white);
    return Container(
      color: fondo ?? Marca.primario,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          const SizedBox(width: 16),
          Text(_dinero(valor), style: estilo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = caja;
    final fin = c.hastaEn ?? c.cerradaEn;
    final difOk = c.diferencia.abs() < 0.01;
    final efectivo = _tabla('Efectivo en caja', [
      _fila('Fondo inicial', c.montoApertura, 0),
      _fila('Ventas en efectivo', c.ventasEfectivo, 1, tenue: !c.config.ventasEfectivo),
      _fila('Abonos de clientes en efectivo', c.abonosEfectivo, 2, tenue: !c.config.abonosEfectivo),
      _fila('Gastos en efectivo', -c.gastos, 3, tenue: !c.config.gastos),
      _fila('Pagos a proveedores en efectivo', -c.pagosProveedores, 4, tenue: !c.config.pagosProveedores),
      _fila('Compras en efectivo', -c.comprasEfectivo, 5, tenue: !c.config.comprasEfectivo),
      _total('Efectivo esperado', c.efectivoEsperado),
      if (!c.abierta) ...[
        _fila('Efectivo contado', c.montoCierre ?? 0, 0),
        _total('Diferencia', c.diferencia, fondo: difOk ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6), texto: difOk ? const Color(0xFF1E7B4B) : const Color(0xFFC62828)),
      ],
    ]);
    final ventas = _tabla('Ventas (${c.cantidadVentas})', [
      _fila('Efectivo', c.ventasEfectivo, 0),
      _fila('Tarjeta', c.ventasTarjeta, 1),
      _fila('Transferencia', c.ventasTransferencia, 2),
      _fila('Cheque', c.ventasCheque, 3),
      _fila('Crédito', c.ventasCredito, 4),
      _total('Total ventas', c.totalVentas, fondo: const Color(0xFFECEEF3), texto: const Color(0xFF1A1A1A)),
      _fila('Abonos con otros métodos', c.abonosOtros, 1),
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contando del ${_formatoFecha.format(c.desdeEfectivo)} ${fin == null ? 'en adelante (en vivo)' : 'al ${_formatoFecha.format(fin)}'}',
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700),
        ),
        if (c.cerradaEn != null) Text('Cerrada ${_formatoFecha.format(c.cerradaEn!)}', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700)),
        if (c.notas.isNotEmpty) Text('Notas: ${c.notas}', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700)),
        if (c.notasCierre.isNotEmpty) Text('Notas de cierre: ${c.notasCierre}', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, cons) {
            if (cons.maxWidth >= 820) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: efectivo),
                  const SizedBox(width: 14),
                  Expanded(child: ventas),
                ],
              );
            }
            return Column(children: [efectivo, const SizedBox(height: 14), ventas]);
          },
        ),
      ],
    );
  }
}

class _MovimientosDialog extends ConsumerStatefulWidget {
  final CajaModel caja;

  const _MovimientosDialog({required this.caja});

  @override
  ConsumerState<_MovimientosDialog> createState() => _MovimientosDialogState();
}

class _MovimientosDialogState extends ConsumerState<_MovimientosDialog> {
  late Future<ResumenOperaciones> _futuro;

  @override
  void initState() {
    super.initState();
    final c = widget.caja;
    _futuro = ref.read(cajaRepositoryProvider).operaciones(
          desde: c.desdeEfectivo,
          hasta: c.hastaEn ?? c.cerradaEn ?? DateTime.now().add(const Duration(minutes: 1)),
          usuario: c.usuario,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    return Dialog(
      child: SizedBox(
        width: tamano.width < 720 ? tamano.width - 32 : 680,
        height: tamano.height < 640 ? tamano.height - 48 : 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(child: Text('Movimientos de ${widget.caja.usuario}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<ResumenOperaciones>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (snap.hasError) return Center(child: Text('${snap.error}'));
                  final ops = snap.data!.operaciones;
                  if (ops.isEmpty) return Center(child: Text('Sin movimientos en este periodo', style: GoogleFonts.poppins(color: Colors.grey.shade600)));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: ops.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final o = ops[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${o.tipo} · ${o.descripcion}', style: GoogleFonts.poppins(fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${_formatoFecha.format(o.fecha)} · ${o.usuario}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                        trailing: Text(formatearMoneda(o.monto), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                      );
                    },
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
      title: const Text('Cerrar caja'),
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
                  decoration: const InputDecoration(labelText: 'Efectivo contado', prefixText: 'L. ', border: OutlineInputBorder()),
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
