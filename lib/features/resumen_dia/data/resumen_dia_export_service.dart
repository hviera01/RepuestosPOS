import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/logo_pdf.dart';
import '../../negocio/data/negocio_model.dart';
import 'resumen_operaciones_model.dart';

class ResumenDiaExportService {
  static const _colorTexto = PdfColor.fromInt(0xFF303846);
  static const _colorGris = PdfColor.fromInt(0xFFF2F3F7);
  static const _colorBorde = PdfColor.fromInt(0xFFE0E2E8);

  String _periodo(ResumenOperaciones r) {
    final f = DateFormat('dd/MM/yyyy');
    final h = DateFormat('HH:mm');
    final mismoDia = f.format(r.desde) == f.format(r.hasta);
    return mismoDia ? '${f.format(r.desde)}  ${h.format(r.desde)} - ${h.format(r.hasta)}' : '${f.format(r.desde)} al ${f.format(r.hasta)}';
  }

  List<(String, String)> _filasPrincipales(ResumenOperaciones r) => [
        ('Ventas (${r.cantidadVentas})', formatearMoneda(r.totalVentas)),
        ('Ticket promedio', formatearMoneda(r.ticketPromedio)),
        ('Utilidad bruta', formatearMoneda(r.utilidadBruta)),
        ('ISV cobrado', formatearMoneda(r.impuesto)),
        ('Unidades vendidas', r.unidades.toStringAsFixed(r.unidades == r.unidades.roundToDouble() ? 0 : 2)),
      ];

  Future<Uint8List> generarTicket(ResumenOperaciones r, NegocioModel negocio, {String? usuario, PdfPageFormat? formatoImpresora}) async {
    final doc = pw.Document();
    final logo = negocio.logoEnTicket ? decodificarLogoPdf(negocio.logoBnBase64) : null;
    const f = 8.0;
    final anchoMm = formatoImpresora == null ? 80.0 : (formatoImpresora.width / PdfPageFormat.mm).clamp(40, 120).toDouble();

    pw.Widget fila(String a, String b, {bool negrita = false}) {
      final e = pw.TextStyle(fontSize: f, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal);
      return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Expanded(child: pw.Text(a, style: e)), pw.Text(b, style: e)]);
    }

    pw.Widget sep() => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Divider(thickness: 0.7));
    pw.Widget titulo(String t) => pw.Padding(padding: const pw.EdgeInsets.only(top: 2, bottom: 2), child: pw.Text(t, style: pw.TextStyle(fontSize: f, fontWeight: pw.FontWeight.bold)));

    doc.addPage(
      pw.MultiPage(
        maxPages: 2000,
        pageFormat: PdfPageFormat(anchoMm * PdfPageFormat.mm, (250 + (r.porUsuario.length + (r.topProductos.length > 5 ? 5 : r.topProductos.length)) * 6 + (logo != null ? 24 : 0)) * PdfPageFormat.mm, marginAll: 8 * PdfPageFormat.mm),
        build: (context) => [
          if (logo != null) pw.Center(child: pw.Image(logo, height: 46)),
          if (negocio.nombre.isNotEmpty) pw.Center(child: pw.Text(negocio.nombre.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          sep(),
          pw.Center(child: pw.Text('RESUMEN DEL DÍA', style: pw.TextStyle(fontSize: f + 1, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text(_periodo(r), style: const pw.TextStyle(fontSize: f))),
          if (usuario != null) pw.Center(child: pw.Text('Usuario: $usuario', style: const pw.TextStyle(fontSize: f))),
          sep(),
          for (final (a, b) in _filasPrincipales(r)) fila(a, b),
          sep(),
          titulo('FORMAS DE PAGO'),
          fila('Efectivo', formatearMoneda(r.efectivo)),
          fila('Tarjeta', formatearMoneda(r.tarjeta)),
          fila('Transferencia', formatearMoneda(r.transferencia)),
          fila('Cheque', formatearMoneda(r.cheque)),
          fila('Crédito', formatearMoneda(r.credito)),
          sep(),
          titulo('DINERO EN EFECTIVO'),
          fila('Entradas', formatearMoneda(r.entradasEfectivo)),
          fila('Salidas', formatearMoneda(r.salidasEfectivo)),
          fila('Neto', formatearMoneda(r.netoEfectivo), negrita: true),
          sep(),
          titulo('OTRAS OPERACIONES'),
          fila('Abonos de clientes (${r.abonosClientesCantidad})', formatearMoneda(r.abonosClientesTotal)),
          fila('Compras (${r.comprasCantidad})', formatearMoneda(r.comprasTotal)),
          fila('Pagos a proveedores (${r.abonosProveedoresCantidad})', formatearMoneda(r.abonosProveedoresTotal)),
          fila('Egresos (${r.egresosCantidad})', formatearMoneda(r.egresosTotal)),
          fila('Traslados (${r.trasladosCantidad})', '${r.trasladosUnidades.toStringAsFixed(0)} u.'),
          fila('Ventas anuladas (${r.anuladasCantidad})', formatearMoneda(r.anuladasTotal)),
          fila('Cotizaciones (${r.cotizacionesCantidad})', formatearMoneda(r.cotizacionesTotal)),
          if (r.porUsuario.isNotEmpty) ...[
            sep(),
            titulo('POR USUARIO'),
            for (final u in r.porUsuario) fila('${u.etiqueta} (${u.cantidad})', formatearMoneda(u.total)),
          ],
          if (r.topProductos.isNotEmpty) ...[
            sep(),
            titulo('MÁS VENDIDOS'),
            for (final p in r.topProductos.take(5)) fila('${p.cantidad} x ${p.etiqueta}', formatearMoneda(p.total)),
          ],
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> generarPdf(ResumenOperaciones r, NegocioModel negocio, {String? usuario}) async {
    final doc = pw.Document();
    final logo = negocio.logoEnPdf ? decodificarLogoPdf(negocio.logoColorBase64) : null;

    pw.Widget celda(String t, {bool negrita = false, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 9.5, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );

    pw.Widget tabla(String titulo, List<List<String>> filas, {List<String> columnas = const ['Concepto', 'Monto']}) {
      if (filas.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Table(
          border: pw.TableBorder.all(color: _colorBorde, width: 0.6),
          columnWidths: {0: const pw.FlexColumnWidth(4), for (var i = 1; i < columnas.length; i++) i: const pw.FlexColumnWidth(1.6)},
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _colorGris),
              children: [
                celda(titulo, negrita: true),
                for (var i = 1; i < columnas.length; i++) celda(columnas[i], negrita: true, align: pw.TextAlign.right),
              ],
            ),
            for (final fila in filas)
              pw.TableRow(children: [
                celda(fila[0]),
                for (var i = 1; i < fila.length; i++) celda(fila[i], align: pw.TextAlign.right),
              ]),
          ],
        ),
      );
    }

    pw.Widget kpi(String t, String v) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 6),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: _colorGris, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(t, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _colorTexto)),
            ]),
          ),
        );

    final f = DateFormat('HH:mm');
    doc.addPage(
      pw.MultiPage(
        maxPages: 200,
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
        header: (context) => context.pageNumber > 1
            ? pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Resumen del día · ${_periodo(r)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)))
            : pw.SizedBox(),
        footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(children: [
                if (logo != null) pw.Padding(padding: const pw.EdgeInsets.only(right: 10), child: pw.Image(logo, height: 40)),
                pw.Text(negocio.nombre.isEmpty ? 'MI NEGOCIO' : negocio.nombre.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _colorTexto)),
              ]),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(color: _colorTexto, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Text('RESUMEN DEL DÍA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Periodo: ${_periodo(r)}${usuario == null ? '' : '   ·   Usuario: $usuario'}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            kpi('Ventas del periodo', formatearMoneda(r.totalVentas)),
            kpi('Cantidad de ventas', '${r.cantidadVentas}'),
            kpi('Ticket promedio', formatearMoneda(r.ticketPromedio)),
            kpi('Utilidad bruta', formatearMoneda(r.utilidadBruta)),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            kpi('Entró en efectivo', formatearMoneda(r.entradasEfectivo)),
            kpi('Salió en efectivo', formatearMoneda(r.salidasEfectivo)),
            kpi('Neto en efectivo', formatearMoneda(r.netoEfectivo)),
            kpi('ISV cobrado', formatearMoneda(r.impuesto)),
          ]),
          pw.SizedBox(height: 14),
          tabla('Ventas por forma de pago', [
            ['Efectivo', formatearMoneda(r.efectivo)],
            ['Tarjeta', formatearMoneda(r.tarjeta)],
            ['Transferencia', formatearMoneda(r.transferencia)],
            ['Cheque', formatearMoneda(r.cheque)],
            ['Crédito', formatearMoneda(r.credito)],
          ]),
          tabla('Ventas por tipo de documento', [for (final t in r.porTipo) [t.etiqueta, '${t.cantidad}', formatearMoneda(t.total)]], columnas: const ['Tipo', 'Cantidad', 'Total']),
          tabla('Otras operaciones', [
            ['Abonos de clientes (${r.abonosClientesCantidad})', formatearMoneda(r.abonosClientesTotal)],
            ['Compras (${r.comprasCantidad}): contado ${formatearMoneda(r.comprasContado)} · crédito ${formatearMoneda(r.comprasCredito)}', formatearMoneda(r.comprasTotal)],
            ['Pagos a proveedores (${r.abonosProveedoresCantidad})', formatearMoneda(r.abonosProveedoresTotal)],
            ['Egresos (${r.egresosCantidad})', formatearMoneda(r.egresosTotal)],
            ['Traslados (${r.trasladosCantidad}) · ${r.trasladosUnidades.toStringAsFixed(0)} unidades', '-'],
            ['Ventas anuladas (${r.anuladasCantidad})', formatearMoneda(r.anuladasTotal)],
            ['Cotizaciones (${r.cotizacionesCantidad})', formatearMoneda(r.cotizacionesTotal)],
          ]),
          tabla('Egresos por categoría', [for (final c in r.egresosPorCategoria) [c.etiqueta, formatearMoneda(c.total)]]),
          tabla('Ventas por usuario', [for (final u in r.porUsuario) [u.etiqueta, '${u.cantidad}', formatearMoneda(u.total)]], columnas: const ['Usuario', 'Ventas', 'Total']),
          tabla('Ventas por hora', [for (final h in r.porHora) [h.etiqueta, '${h.cantidad}', formatearMoneda(h.total)]], columnas: const ['Hora', 'Ventas', 'Total']),
          tabla('Productos más vendidos', [for (final p in r.topProductos) [p.etiqueta, '${p.cantidad}', formatearMoneda(p.total)]], columnas: const ['Producto', 'Unidades', 'Monto']),
          tabla('Mejores clientes', [for (final c in r.topClientes) [c.etiqueta, '${c.cantidad}', formatearMoneda(c.total)]], columnas: const ['Cliente', 'Compras', 'Total']),
          if (r.operaciones.isNotEmpty)
            tabla('Todo lo que se hizo en el sistema', [
              for (final o in r.operaciones) ['${f.format(o.fecha)}  ${o.tipo} · ${o.descripcion} (${o.usuario})', formatearMoneda(o.monto)],
            ]),
        ],
      ),
    );
    return doc.save();
  }
}
