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
import '../../../caja/providers/caja_provider.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../../reportes/providers/reportes_provider.dart';
import '../../../usuarios/providers/usuarios_provider.dart';
import '../../data/resumen_dia_export_service.dart';
import '../../data/resumen_operaciones_model.dart';

DateTime _inicioDelDia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _finDelDia(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

class ResumenDiaScreen extends ConsumerStatefulWidget {
  const ResumenDiaScreen({super.key});

  @override
  ConsumerState<ResumenDiaScreen> createState() => _ResumenDiaScreenState();
}

class _ResumenDiaScreenState extends ConsumerState<ResumenDiaScreen> {
  final _export = ResumenDiaExportService();
  late DateTime _desde = _inicioDelDia(DateTime.now());
  late DateTime _hasta = _finDelDia(DateTime.now());
  String? _usuarioFiltro;
  ResumenOperaciones? _resumen;
  bool _cargando = true;
  String? _error;
  Timer? _debounce;
  bool _mostrarTodasOperaciones = false;
  String _filtroTipo = 'Todo';
  String _busquedaOps = '';
  final _formatoDia = DateFormat('dd/MM/yyyy');
  final _formatoHora = DateFormat('HH:mm');

  bool get _esAdmin => ref.read(authProvider).usuario?.rol == Roles.administrador;
  String get _miNombre => ref.read(authProvider).usuario?.nombreCompleto ?? '';
  String? get _usuarioEfectivo => _esAdmin ? _usuarioFiltro : _miNombre;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final r = await ref.read(cajaRepositoryProvider).operaciones(desde: _desde, hasta: _hasta, usuario: _usuarioEfectivo);
      if (!mounted) return;
      setState(() {
        _resumen = r;
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

  void _escuchar(String tabla) {
    ref.listen<AsyncValue<void>>(cambiosEnTablaProvider(tabla), (previous, next) {
      if (!next.hasValue || !mounted) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _cargar(silencioso: true);
      });
    });
  }

  void _rango(DateTime desde, DateTime hasta) {
    setState(() {
      _desde = desde;
      _hasta = hasta;
    });
    _cargar();
  }

  Future<void> _elegirFecha(bool inicio) async {
    final f = await showDatePicker(
      context: context,
      initialDate: inicio ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (f == null) return;
    setState(() {
      if (inicio) {
        _desde = _inicioDelDia(f);
        if (_hasta.isBefore(_desde)) _hasta = _finDelDia(f);
      } else {
        _hasta = _finDelDia(f);
        if (_desde.isAfter(_hasta)) _desde = _inicioDelDia(f);
      }
    });
    _cargar();
  }

  Future<void> _exportar(bool ticket) async {
    final r = _resumen;
    if (r == null) return;
    final negocio = await ref.read(negocioRepositoryProvider).obtenerNegocioActual();
    if (!mounted) return;
    final usuario = _usuarioEfectivo;
    if (ticket) {
      final impresora = negocio.impresoraTermicaUrl.isEmpty ? null : Printer(url: negocio.impresoraTermicaUrl, name: negocio.impresoraTermicaNombre);
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => RecibosTickets.dialogo(
          titulo: 'Ticket · Resumen del día',
          archivo: 'resumen_dia_ticket.pdf',
          pdf: () => _export.generarTicket(r, negocio, usuario: usuario),
          copias: [_export.lineasTicket(r, negocio, usuario: usuario)],
          negocio: negocio,
          impresora: impresora,
        ),
      );
    } else {
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => PdfPreviewDialog(
          titulo: 'Vista previa · Resumen del día',
          nombreArchivo: 'resumen_dia.pdf',
          generarPdf: () => _export.generarPdf(r, negocio, usuario: usuario),
        ),
      );
    }
  }

  Widget _chipRango(String etiqueta, DateTime desde, DateTime hasta) {
    final activo = _desde == desde && _hasta == hasta;
    return ChoiceChip(
      label: Text(etiqueta, style: GoogleFonts.poppins(fontSize: 12.5, color: activo ? Marca.sobrePrimario : null)),
      selected: activo,
      selectedColor: Marca.primario,
      showCheckmark: false,
      onSelected: (_) => _rango(desde, hasta),
    );
  }

  Widget _botonFecha(String etiqueta, DateTime f, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC9CDD6))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('$etiqueta ${_formatoDia.format(f)}', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(String titulo, Widget hijo, {IconData? icono}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E2E8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icono != null) ...[Icon(icono, size: 17, color: Marca.primario), const SizedBox(width: 8)],
            Text(titulo, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          hijo,
        ],
      ),
    );
  }

  Widget _kpi(String titulo, String valor, {Color? color}) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E2E8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(valor, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: color ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _filaDato(String a, String b, {bool fuerte = false, Color? color}) {
    final e = GoogleFonts.poppins(fontSize: 12.5, fontWeight: fuerte ? FontWeight.w800 : FontWeight.w500, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [Expanded(child: Text(a, style: e)), Text(b, style: e)]),
    );
  }

  Widget _barras(List<LineaTotal> lineas, {bool mostrarCantidad = true}) {
    if (lineas.isEmpty) return Text('Sin datos', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500));
    final maximo = lineas.map((l) => l.total).fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final l in lineas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(l.etiqueta, style: GoogleFonts.poppins(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  Text(mostrarCantidad ? '${l.cantidad} · ${formatearMoneda(l.total)}' : formatearMoneda(l.total), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: maximo <= 0 ? 0 : l.total / maximo, minHeight: 6, backgroundColor: const Color(0xFFEDEEF2), color: Marca.primario),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contenido(ResumenOperaciones r) {
    final formasPago = [
      LineaTotal('Efectivo', 0, r.efectivo),
      LineaTotal('Tarjeta', 0, r.tarjeta),
      LineaTotal('Transferencia', 0, r.transferencia),
      LineaTotal('Cheque', 0, r.cheque),
      LineaTotal('Crédito', 0, r.credito),
    ];
    final tokens = _busquedaOps.toLowerCase().split(RegExp(r's+')).where((t) => t.isNotEmpty).toList();
    final filtradas = r.operaciones.where((o) {
      if (_filtroTipo != 'Todo' && o.tipo != _filtroTipo) return false;
      if (tokens.isEmpty) return true;
      final texto = '${o.tipo} ${o.descripcion} ${o.usuario}'.toLowerCase();
      return tokens.every(texto.contains);
    }).toList();
    final operaciones = _mostrarTodasOperaciones ? filtradas : filtradas.take(40).toList();
    final tipos = <String>['Todo', ...{for (final o in r.operaciones) o.tipo}];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpi('Ventas del periodo', formatearMoneda(r.totalVentas)),
            _kpi('Cantidad de ventas', '${r.cantidadVentas}'),
            _kpi('Ticket promedio', formatearMoneda(r.ticketPromedio)),
            _kpi('Utilidad bruta', formatearMoneda(r.utilidadBruta), color: const Color(0xFF1E7B4B)),
            _kpi('Entró en efectivo', formatearMoneda(r.entradasEfectivo)),
            _kpi('Salió en efectivo', formatearMoneda(r.salidasEfectivo), color: const Color(0xFFC62828)),
            _kpi('Neto en efectivo', formatearMoneda(r.netoEfectivo)),
            _kpi('ISV cobrado', formatearMoneda(r.impuesto)),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final dosColumnas = c.maxWidth > 860;
            final ancho = dosColumnas ? (c.maxWidth - 14) / 2 : c.maxWidth;
            Widget col(List<Widget> hijos) => SizedBox(width: ancho, child: Column(children: [for (final h in hijos) Padding(padding: const EdgeInsets.only(bottom: 14), child: h)]));
            final izquierda = [
              _tarjeta('Ventas por forma de pago', _barras(formasPago, mostrarCantidad: false), icono: Icons.payments_outlined),
              _tarjeta('Por tipo de documento', _barras(r.porTipo), icono: Icons.receipt_long_outlined),
              _tarjeta(
                'Compras y pagos',
                Column(children: [
                  _filaDato('Compras (${r.comprasCantidad})', formatearMoneda(r.comprasTotal)),
                  _filaDato('   de contado', formatearMoneda(r.comprasContado)),
                  _filaDato('   a crédito', formatearMoneda(r.comprasCredito)),
                  _filaDato('Pagos a proveedores (${r.abonosProveedoresCantidad})', formatearMoneda(r.abonosProveedoresTotal)),
                  _filaDato('Abonos de clientes (${r.abonosClientesCantidad})', formatearMoneda(r.abonosClientesTotal)),
                ]),
                icono: Icons.local_shipping_outlined,
              ),
              _tarjeta(
                'Gastos y otros',
                Column(children: [
                  _filaDato('Egresos (${r.egresosCantidad})', formatearMoneda(r.egresosTotal)),
                  for (final c in r.egresosPorCategoria) _filaDato('   ${c.etiqueta}', formatearMoneda(c.total)),
                  _filaDato('Traslados (${r.trasladosCantidad})', '${r.trasladosUnidades.toStringAsFixed(0)} unidades'),
                  _filaDato('Ventas anuladas (${r.anuladasCantidad})', formatearMoneda(r.anuladasTotal), color: r.anuladasCantidad > 0 ? const Color(0xFFC62828) : null),
                  _filaDato('Cotizaciones (${r.cotizacionesCantidad})', formatearMoneda(r.cotizacionesTotal)),
                ]),
                icono: Icons.account_balance_wallet_outlined,
              ),
            ];
            final derecha = [
              _tarjeta('Ventas por hora', _barras(r.porHora), icono: Icons.schedule),
              _tarjeta('Ventas por usuario', _barras(r.porUsuario), icono: Icons.people_outline),
              _tarjeta('Productos más vendidos', _barras(r.topProductos.map((p) => LineaTotal(p.etiqueta, p.cantidad, p.total)).toList()), icono: Icons.inventory_2_outlined),
              _tarjeta('Mejores clientes', _barras(r.topClientes), icono: Icons.star_border),
            ];
            return dosColumnas
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [col(izquierda), const SizedBox(width: 14), col(derecha)])
                : Column(children: [...izquierda.map((w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w)), ...derecha.map((w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w))]);
          },
        ),
        _tarjeta(
          'Todo lo que se hizo (${filtradas.length}${filtradas.length == r.operaciones.length ? '' : ' de ${r.operaciones.length}'})',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, proveedor, recibo, documento, usuario…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setState(() {
                  _busquedaOps = v.trim();
                  _mostrarTodasOperaciones = false;
                }),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in tipos)
                    ChoiceChip(
                      label: Text(t, style: GoogleFonts.poppins(fontSize: 11.5, color: _filtroTipo == t ? Marca.sobrePrimario : null)),
                      selected: _filtroTipo == t,
                      selectedColor: Marca.primario,
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        _filtroTipo = t;
                        _mostrarTodasOperaciones = false;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (operaciones.isEmpty) Text('Sin movimientos en este periodo', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
              for (final o in operaciones)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 86,
                        child: Text(
                          _desde.day == _hasta.day && _desde.month == _hasta.month ? _formatoHora.format(o.fecha) : '${DateFormat('dd/MM').format(o.fecha)} ${_formatoHora.format(o.fecha)}',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Text('${o.tipo} · ${o.descripcion}  (${o.usuario})', style: GoogleFonts.poppins(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      Text(formatearMoneda(o.monto), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              if (!_mostrarTodasOperaciones && filtradas.length > 40)
                TextButton(onPressed: () => setState(() => _mostrarTodasOperaciones = true), child: Text('Ver las ${filtradas.length} operaciones')),
            ],
          ),
          icono: Icons.timeline,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final tabla in const ['ventas', 'venta_credito_abonos', 'egresos', 'compras', 'compra_credito_abonos', 'traslados']) {
      _escuchar(tabla);
    }
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    final usuarios = ref.watch(usuariosStreamProvider).value ?? const [];
    return Container(
      color: const Color(0xFFF2F3F7),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text('Resumen del Día', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700))),
              OutlinedButton.icon(onPressed: _resumen == null ? null : () => _exportar(false), icon: const Icon(Icons.picture_as_pdf_outlined, size: 18), label: const Text('PDF')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _resumen == null ? null : () => _exportar(true), icon: const Icon(Icons.receipt_long_outlined, size: 18), label: const Text('Ticket')),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _cargar(), icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chipRango('Hoy', _inicioDelDia(hoy), _finDelDia(hoy)),
              _chipRango('Ayer', _inicioDelDia(ayer), _finDelDia(ayer)),
              _chipRango('7 días', _inicioDelDia(hoy.subtract(const Duration(days: 6))), _finDelDia(hoy)),
              _chipRango('Este mes', DateTime(hoy.year, hoy.month, 1), _finDelDia(hoy)),
              _botonFecha('Del', _desde, () => _elegirFecha(true)),
              _botonFecha('al', _hasta, () => _elegirFecha(false)),
              if (_esAdmin)
                DropdownButton<String?>(
                  value: _usuarioFiltro,
                  hint: const Text('Todos los usuarios'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos los usuarios')),
                    for (final u in usuarios) DropdownMenuItem(value: u.nombreCompleto, child: Text(u.nombreCompleto)),
                  ],
                  onChanged: (v) {
                    setState(() => _usuarioFiltro = v);
                    _cargar();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_cargando && _resumen == null)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null && _resumen == null)
            Center(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red)))
          else if (_resumen != null)
            _contenido(_resumen!),
        ],
      ),
    );
  }
}
