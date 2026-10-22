import '../../../../core/theme/marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../data/venta_credito_model.dart';
import '../../../ventas/data/venta_ticket_escpos_service.dart';
import '../../../ventas/presentation/widgets/ticket_escpos_preview.dart';
import '../../providers/ventas_credito_provider.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/widgets/pdf_preview_dialog.dart';
import '../../../ventas/data/item_venta_model.dart';
import '../../../ventas/data/tipos_documento.dart';
import '../../../ventas/data/venta_model.dart';
import '../../../ventas/data/venta_export_service.dart';
import '../../../ventas/providers/ventas_provider.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class _ItemConsolidado {
  final String numeroFacturaOrigen;
  final ItemVentaModel item;

  _ItemConsolidado(this.numeroFacturaOrigen, this.item);
}

class FacturasOrigenDialog extends ConsumerStatefulWidget {
  final VentaCreditoModel credito;

  const FacturasOrigenDialog({super.key, required this.credito});

  @override
  ConsumerState<FacturasOrigenDialog> createState() =>
      _FacturasOrigenDialogState();
}

class _FacturasOrigenDialogState extends ConsumerState<FacturasOrigenDialog> {
  bool _cargando = true;
  bool _vistaAgrupada = false;
  List<VentaModel> _ventasOrigen = [];
  List<_ItemConsolidado> _items = [];
  List<String> _facturasSinDetalle = [];
  List<String> _numerosFacturasUnidas = [];

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }


  double _precioConIsv(ItemVentaModel item) =>
      redondearMoneda(item.precioVenta * 1.15);

  double _importeConIsv(ItemVentaModel item) => redondearMoneda(
    _precioConIsv(item) * item.cantidad * (1 - item.descuentoPorcentaje / 100),
  );

  Future<void> _resolverFactura(
    FacturaOrigenModel factura,
    List<VentaModel> ventas,
    List<String> sinDetalle,
    List<String> numeros,
    Set<String> visitados,
  ) async {
    if (factura.id.isEmpty || !visitados.add(factura.id)) {
      if (factura.id.isEmpty) {
        sinDetalle.add(factura.numeroDocumento);
        numeros.add(factura.numeroDocumento);
      }
      return;
    }
    try {
      final venta = await ref
          .read(ventaRepositoryProvider)
          .obtenerVentaPorId(factura.id);
      if (venta != null && venta.detalle.isNotEmpty) {
        ventas.add(venta);
        numeros.add(venta.numeroDocumento);
        return;
      }
      final creditoOrigen = await ref
          .read(ventaCreditoRepositoryProvider)
          .obtenerPorId(factura.id);
      if (creditoOrigen != null && creditoOrigen.facturasOrigen.isNotEmpty) {
        for (final sub in creditoOrigen.facturasOrigen) {
          await _resolverFactura(sub, ventas, sinDetalle, numeros, visitados);
        }
      } else {
        sinDetalle.add(factura.numeroDocumento);
        numeros.add(factura.numeroDocumento);
      }
    } catch (_) {
      sinDetalle.add(factura.numeroDocumento);
      numeros.add(factura.numeroDocumento);
    }
  }

  Future<void> _cargarDetalle() async {
    final ventas = <VentaModel>[];
    final sinDetalle = <String>[];
    final numeros = <String>[];
    final visitados = <String>{};
    for (final factura in widget.credito.facturasOrigen) {
      await _resolverFactura(factura, ventas, sinDetalle, numeros, visitados);
    }
    if (!mounted) return;
    setState(() {
      _ventasOrigen = ventas;
      _items = [
        for (final v in ventas)
          for (final item in v.detalle)
            _ItemConsolidado(v.numeroDocumento, item),
      ];
      _facturasSinDetalle = sinDetalle;
      _numerosFacturasUnidas = numeros;
      _cargando = false;
    });
  }

  Future<void> _imprimirPorSeparado() async {
    if (_ventasOrigen.isEmpty) return;
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    if (!mounted) return;
    final impresora = negocio.impresoraTermicaUrl.isEmpty
        ? null
        : Printer(
            url: negocio.impresoraTermicaUrl,
            name: negocio.impresoraTermicaNombre,
          );
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => PdfPreviewDialog(
        generarTicketEscPos: () async => [
          for (final v in _ventasOrigen) ...await VentaTicketEscPosService().generarTicket(v, negocio),
        ],
        nombreImpresoraWindows: negocio.impresoraUsbUsarDriverWindows ? null : negocio.impresoraTermicaNombre,
        vistaPreviaTicket: () => SingleChildScrollView(
          child: Column(
            children: [
              for (final v in _ventasOrigen) ...[
                TicketEscPosPreview(venta: v, negocio: negocio, esCopia: false),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        titulo: 'Vista previa · Facturas por separado',
        nombreArchivo: 'facturas_${widget.credito.numeroDocumento}.pdf',
        generarPdf: () => VentaExportService().generarPdfFacturasPorSeparado(
          _ventasOrigen,
          negocio,
        ),
        generarPdfConFormato: (formato) =>
            VentaExportService().generarPdfFacturasPorSeparado(
              _ventasOrigen,
              negocio,
              formatoImpresora: formato,
            ),
        impresora: impresora,
      ),
    );
  }

  List<ItemVentaModel> _consolidarItems() {
    final porClave = <String, ItemVentaModel>{};
    for (final c in _items) {
      final item = c.item;
      final clave =
          '${item.idProducto}|${item.precioVenta}|${item.descuentoPorcentaje}';
      final existente = porClave[clave];
      porClave[clave] = existente == null
          ? item
          : existente.copyWith(
              cantidad: existente.cantidad + item.cantidad,
              subtotal: existente.subtotal + item.subtotal,
            );
    }
    return porClave.values.toList();
  }

  VentaModel? _ventaSinteticaCache;

  Future<VentaModel> _obtenerVentaSintetica() async {
    final cache = _ventaSinteticaCache;
    if (cache != null) return cache;
    final numeroDocumento = await ref
        .read(ventaRepositoryProvider)
        .reservarProximoNumeroFactura();
    final usuario = ref.read(authProvider).usuario?.nombreCompleto ?? '';
    final itemsConsolidados = _consolidarItems();
    final totalAPagar = widget.credito.montoTotal;
    final subtotal = redondearMoneda(totalAPagar / 1.15);
    final impuesto = redondearMoneda(totalAPagar - subtotal);
    final venta = VentaModel(
      id: '',
      tipoDocumento: 'Factura',
      numeroDocumento: numeroDocumento,
      documentoCliente: widget.credito.documentoCliente,
      nombreCliente: widget.credito.nombreCliente,
      metodoPago: 'N/A',
      montoPago: 0,
      montoCambio: 0,
      subtotal: subtotal,
      impuesto: impuesto,
      totalAPagar: totalAPagar,
      condicion: 'Credito',
      fechaVencimiento: widget.credito.fechaVencimiento,
      fechaRegistro: DateTime.now(),
      estado: 'Activa',
      usuarioRegistro: usuario,
      cantidadProductos: itemsConsolidados.fold<double>(
        0,
        (s, i) => s + i.cantidad,
      ),
      oc: '',
      regExonerado: '',
      regSag: '',
      detalle: itemsConsolidados,
    );
    _ventaSinteticaCache = venta;
    return venta;
  }

  Future<void> _imprimirUnificado() async {
    if (_ventasOrigen.isEmpty) return;
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    if (!mounted) return;
    final ventaSintetica = await _obtenerVentaSintetica();
    if (!mounted) return;
    final impresora = negocio.impresoraTermicaUrl.isEmpty
        ? null
        : Printer(
            url: negocio.impresoraTermicaUrl,
            name: negocio.impresoraTermicaNombre,
          );
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => PdfPreviewDialog(
        generarTicketEscPos: () => VentaTicketEscPosService().generarTicket(ventaSintetica, negocio),
        nombreImpresoraWindows: negocio.impresoraUsbUsarDriverWindows ? null : negocio.impresoraTermicaNombre,
        vistaPreviaTicket: () => TicketEscPosPreview(venta: ventaSintetica, negocio: negocio, esCopia: false),
        titulo: 'Vista previa · ${ventaSintetica.numeroDocumento}',
        nombreArchivo: 'venta_${ventaSintetica.numeroDocumento}.pdf',
        generarPdf: () =>
            VentaExportService().generarPdfFactura(ventaSintetica, negocio),
        generarPdfConFormato: (formato) =>
            VentaExportService().generarPdfFactura(
              ventaSintetica,
              negocio,
              formatoImpresora: formato,
            ),
        impresora: impresora,
      ),
    );
  }

  Future<void> _descargarPdf() async {
    if (_ventasOrigen.isEmpty) return;
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    if (!mounted) return;
    final ventaSintetica = await _obtenerVentaSintetica();
    if (!mounted) return;
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => PdfPreviewDialog(
        titulo: 'Documento formal · ${ventaSintetica.numeroDocumento}',
        nombreArchivo:
            '${tiposDocumento[ventaSintetica.tipoDocumento] ?? ventaSintetica.tipoDocumento}_${ventaSintetica.numeroDocumento}.pdf',
        generarPdf: () => VentaExportService().generarPdfDetalleVenta(
          ventaSintetica,
          negocio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credito = widget.credito;
    final tamano = MediaQuery.of(context).size;
    final esMovil = tamano.width < 640;
    final anchoDialog = esMovil ? tamano.width - 24 : 640.0;
    final altoDialog = tamano.height < 700 ? tamano.height - 40 : 640.0;
    final totalItems = _items.fold<double>(
      0,
      (s, i) => s + _importeConIsv(i.item),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        width: anchoDialog,
        height: altoDialog,
        padding: EdgeInsets.all(esMovil ? 16 : 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Marca.primario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.call_merge_outlined,
                    color: Marca.primario,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle de Facturas Unidas',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${credito.numeroDocumento} · ${credito.nombreCliente}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Facturas unidas: ${(_numerosFacturasUnidas.isEmpty ? credito.facturasOrigen.map((f) => f.numeroDocumento) : _numerosFacturasUnidas).join(', ')}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (!_cargando && _items.isNotEmpty) ...[
              const SizedBox(height: 10),
              _selectorVista(),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: _cargando
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Marca.primario,
                      ),
                    )
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontró el detalle de productos de estas facturas',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                    )
                  : _tabla(),
            ),
            if (_facturasSinDetalle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sin detalle disponible: ${_facturasSinDetalle.join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _items.isEmpty
                        ? ''
                        : 'Suma de productos (c/ISV): ${formatearMoneda(totalItems)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  'Total unificado: ${formatearMoneda(credito.montoTotal)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (!_cargando && _ventasOrigen.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _imprimirPorSeparado,
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: Text(
                      'Imprimir factura por factura',
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFFB6BCC7)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _descargarPdf,
                    icon: const Icon(Icons.download_outlined, size: 17),
                    label: Text(
                      'Descargar PDF',
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFFB6BCC7)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _imprimirUnificado,
                    icon: const Icon(Icons.description_outlined, size: 17),
                    label: Text(
                      'Imprimir todo en un solo papel',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Marca.primario,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selectorVista() {
    Widget opcion(String texto, bool valor) {
      final activo = _vistaAgrupada == valor;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _vistaAgrupada = valor),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo ? Marca.primario : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : const Color(0xFF4B4F58),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          opcion('Por factura', false),
          opcion('Agrupado por producto', true),
        ],
      ),
    );
  }

  Widget _tabla() {
    final items = _vistaAgrupada
        ? _consolidarItems()
        : _items.map((c) => c.item).toList();
    final etiquetasFactura = _vistaAgrupada
        ? List<String?>.filled(items.length, null)
        : _items.map((c) => c.numeroFacturaOrigen).toList();
    final filas = [
      for (var i = 0; i < items.length; i++)
        _celdaProducto(items[i].nombreProducto, etiquetasFactura[i]),
    ];

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.6),
          3: FlexColumnWidth(1.6),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFB6BCC7))),
            ),
            children: [
              _celdaEncabezado('PRODUCTO'),
              _celdaEncabezado('CANT.', alinear: TextAlign.right),
              _celdaEncabezado('PRECIO (c/ISV)', alinear: TextAlign.right),
              _celdaEncabezado('IMPORTE (c/ISV)', alinear: TextAlign.right),
            ],
          ),
          for (var i = 0; i < items.length; i++)
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFECEEF3))),
              ),
              children: [
                filas[i],
                _celda(
                  items[i].cantidad.toStringAsFixed(
                    items[i].cantidad % 1 == 0 ? 0 : 2,
                  ),
                  alinear: TextAlign.right,
                ),
                _celda(
                  formatearMoneda(_precioConIsv(items[i])),
                  alinear: TextAlign.right,
                ),
                _celda(
                  formatearMoneda(_importeConIsv(items[i])),
                  alinear: TextAlign.right,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _celdaEncabezado(String texto, {TextAlign alinear = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        texto,
        textAlign: alinear,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _celda(String texto, {TextAlign alinear = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        texto,
        textAlign: alinear,
        style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _celdaProducto(String nombreProducto, String? numeroFacturaOrigen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nombreProducto, style: GoogleFonts.poppins(fontSize: 12.5)),
          if (numeroFacturaOrigen != null)
            Text(
              'Factura $numeroFacturaOrigen',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}
