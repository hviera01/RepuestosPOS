import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'caja_model.dart';
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/logo_pdf.dart';
import '../../negocio/data/negocio_model.dart';

class CajaExportService {
  static const _colorGrisClaro = PdfColor.fromInt(0xFFF2F3F7);
  static const _colorTexto = PdfColor.fromInt(0xFF303846);

  String titulo(CajaModel c) => c.abierta ? 'RESUMEN DE CAJA' : 'CIERRE DE CAJA';

  double? _anchoValido(PdfPageFormat? formato) {
    if (formato == null) return null;
    final mm = formato.width / PdfPageFormat.mm;
    if (mm < 40 || mm > 120) return null;
    return mm;
  }

  List<List<Object>> _filas(CajaModel c) {
    String nota(bool cuenta) => cuenta ? '' : ' (no se cuenta)';
    return [
      ['Fondo inicial', c.montoApertura],
      ['Ventas en efectivo${nota(c.config.ventasEfectivo)}', c.ventasEfectivo],
      ['Abonos en efectivo${nota(c.config.abonosEfectivo)}', c.abonosEfectivo],
      ['Gastos pagados en efectivo${nota(c.config.gastos)}', -c.gastos],
      ['Pagos a proveedores en efectivo${nota(c.config.pagosProveedores)}', -c.pagosProveedores],
      ['Compras en efectivo${nota(c.config.comprasEfectivo)}', -c.comprasEfectivo],
    ];
  }

  Future<Uint8List> generarTicket(CajaModel c, NegocioModel negocio, {PdfPageFormat? formatoImpresora}) async {
    final doc = pw.Document();
    final logo = decodificarLogoPdf(negocio.logoBnBase64);
    final fecha = DateFormat('dd/MM/yyyy HH:mm');
    const f = 8.0;
    final ancho = _anchoValido(formatoImpresora) ?? 80.0;
    final alto = 190.0 + (logo != null ? 20 : 0) + (c.notas.isNotEmpty || c.notasCierre.isNotEmpty ? 24 : 0);

    pw.Widget fila(String etiqueta, double valor, {bool negrita = false}) {
      final estilo = pw.TextStyle(fontSize: f, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal);
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Expanded(child: pw.Text(etiqueta, style: estilo)), pw.Text(formatearMoneda(valor), style: estilo)],
      );
    }

    pw.Widget sep() => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Divider(thickness: 0.7));

    doc.addPage(
      pw.MultiPage(
        maxPages: 2000,
        pageFormat: PdfPageFormat(ancho * PdfPageFormat.mm, alto * PdfPageFormat.mm, marginAll: 8 * PdfPageFormat.mm),
        build: (context) => [
          if (logo != null) pw.Center(child: pw.Image(logo, height: 50)),
          if (negocio.nombre.isNotEmpty)
            pw.Center(child: pw.Text(negocio.nombre.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          sep(),
          pw.Center(child: pw.Text(titulo(c), style: pw.TextStyle(fontSize: f + 1, fontWeight: pw.FontWeight.bold))),
          sep(),
          pw.Text('Cajero: ${c.usuario}', style: const pw.TextStyle(fontSize: f)),
          pw.Text('Desde: ${fecha.format(c.desdeEfectivo)}', style: const pw.TextStyle(fontSize: f)),
          pw.Text('Hasta: ${fecha.format(c.hastaEn ?? c.cerradaEn ?? DateTime.now())}', style: const pw.TextStyle(fontSize: f)),
          if (c.cerradaEn != null) pw.Text('Cerrada: ${fecha.format(c.cerradaEn!)}', style: const pw.TextStyle(fontSize: f)),
          sep(),
          pw.Text('EFECTIVO', style: pw.TextStyle(fontSize: f, fontWeight: pw.FontWeight.bold)),
          for (final r in _filas(c)) fila(r[0] as String, r[1] as double),
          sep(),
          fila('Efectivo esperado', c.efectivoEsperado, negrita: true),
          if (!c.abierta) ...[
            fila('Efectivo contado', c.montoCierre ?? 0, negrita: true),
            fila('Diferencia', c.diferencia, negrita: true),
          ],
          sep(),
          pw.Text('VENTAS (${c.cantidadVentas})', style: pw.TextStyle(fontSize: f, fontWeight: pw.FontWeight.bold)),
          fila('Efectivo', c.ventasEfectivo),
          fila('Tarjeta', c.ventasTarjeta),
          fila('Transferencia', c.ventasTransferencia),
          fila('Cheque', c.ventasCheque),
          fila('Crédito', c.ventasCredito),
          fila('Total ventas', c.totalVentas, negrita: true),
          sep(),
          fila('Abonos con otros métodos', c.abonosOtros),
          if (c.notas.isNotEmpty) ...[
            sep(),
            pw.Text('Notas de apertura:', style: pw.TextStyle(fontSize: f - 0.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(c.notas, style: const pw.TextStyle(fontSize: f - 0.5)),
          ],
          if (c.notasCierre.isNotEmpty) ...[
            sep(),
            pw.Text('Notas de cierre:', style: pw.TextStyle(fontSize: f - 0.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(c.notasCierre, style: const pw.TextStyle(fontSize: f - 0.5)),
          ],
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> generarPdf(CajaModel c, NegocioModel negocio) async {
    final doc = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm');

    pw.Widget celda(String t, {bool negrita = false, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 10, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );

    pw.Widget tabla(String encabezado, List<List<Object>> filas, {List<String> negritas = const []}) {
      return pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE0E2E8), width: 0.6),
        columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _colorGrisClaro),
            children: [celda(encabezado, negrita: true), celda('Monto', negrita: true, align: pw.TextAlign.right)],
          ),
          for (final r in filas)
            pw.TableRow(children: [
              celda(r[0] as String, negrita: negritas.contains(r[0])),
              celda(formatearMoneda(r[1] as double), negrita: negritas.contains(r[0]), align: pw.TextAlign.right),
            ]),
        ],
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(negocio.nombre.isEmpty ? 'MI NEGOCIO' : negocio.nombre.toUpperCase(),
                    style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _colorTexto)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: pw.BoxDecoration(color: _colorTexto, borderRadius: pw.BorderRadius.circular(8)),
                  child: pw.Text(titulo(c), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Cajero: ${c.usuario}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('Desde: ${fecha.format(c.desdeEfectivo)}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(
                child: pw.Text(
                  'Hasta: ${fecha.format(c.hastaEn ?? c.cerradaEn ?? DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ]),
            pw.SizedBox(height: 14),
            tabla('Efectivo en caja', [
              ..._filas(c),
              ['Efectivo esperado', c.efectivoEsperado],
              if (!c.abierta) ['Efectivo contado', c.montoCierre ?? 0],
              if (!c.abierta) ['Diferencia', c.diferencia],
            ], negritas: const ['Efectivo esperado', 'Efectivo contado', 'Diferencia']),
            pw.SizedBox(height: 14),
            tabla('Ventas (${c.cantidadVentas})', [
              ['Efectivo', c.ventasEfectivo],
              ['Tarjeta', c.ventasTarjeta],
              ['Transferencia', c.ventasTransferencia],
              ['Cheque', c.ventasCheque],
              ['Crédito', c.ventasCredito],
              ['Total ventas', c.totalVentas],
              ['Abonos con otros métodos', c.abonosOtros],
            ], negritas: const ['Total ventas']),
            pw.SizedBox(height: 14),
            if (c.notas.isNotEmpty) pw.Text('Notas de apertura: ${c.notas}', style: const pw.TextStyle(fontSize: 10)),
            if (c.notasCierre.isNotEmpty) pw.Text('Notas de cierre: ${c.notasCierre}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
