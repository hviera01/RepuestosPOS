import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'traslado_model.dart';
import '../../negocio/data/negocio_model.dart';

class TrasladoExportService {
  Future<Uint8List> generarPdfTraslado(
    TrasladoModel traslado,
    NegocioModel negocio, {
    bool? forzarCopia,
    required Map<String, String> codigosPorProducto,
    PdfPageFormat? formatoImpresora,
  }) async {
    
    final doc = pw.Document();
    const logo = null;
    final anchoMm = _anchoValidoDesdeFormato(formatoImpresora) ?? negocio.anchoTicketMm.toDouble();

    if (forzarCopia != null) {
      doc.addPage(_construirPagina(traslado, negocio, logo, esCopia: forzarCopia, codigosPorProducto: codigosPorProducto, anchoMm: anchoMm));
      return doc.save();
    }

    doc.addPage(_construirPagina(traslado, negocio, logo, esCopia: false, codigosPorProducto: codigosPorProducto, anchoMm: anchoMm));
    doc.addPage(_construirPagina(traslado, negocio, logo, esCopia: true, codigosPorProducto: codigosPorProducto, anchoMm: anchoMm));
    return doc.save();
  }

  double? _anchoValidoDesdeFormato(PdfPageFormat? formato) {
    if (formato == null) return null;
    final anchoMm = formato.width / PdfPageFormat.mm;
    if (anchoMm < 40 || anchoMm > 120) return null;
    return anchoMm;
  }

  pw.Page _construirPagina(
    TrasladoModel t,
    NegocioModel negocio,
    pw.MemoryImage? logo, {
    required bool esCopia,
    required Map<String, String> codigosPorProducto,
    double? anchoMm,
  }) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    const fTitulo = 13.0;
    const fNormal = 10.5;
    const fChica = 9.0;

    final margenMm = (!kIsWeb && Platform.isWindows) ? 9.0 : 5.0;
    final anchoPaginaMm = anchoMm ?? 80.0;
    final alturaMm = _estimarAlturaMm(t, negocio, tieneLogo: logo != null);

    return pw.MultiPage(
      pageFormat: PdfPageFormat(anchoPaginaMm * PdfPageFormat.mm, alturaMm * PdfPageFormat.mm, marginAll: margenMm * PdfPageFormat.mm),
      footer: (context) {
        if (context.pagesCount <= 1) return pw.SizedBox();
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Center(
            child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold)),
          ),
        );
      },
      header: (context) {
        if (context.pageNumber <= 1) return pw.SizedBox();
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text('TRASLADO ${t.numero} (continuación)', style: pw.TextStyle(fontSize: fNormal, fontWeight: pw.FontWeight.bold)),
        );
      },
      build: (context) {
        return [
          pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Image(logo, width: 130))),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      negocio.nombre.isEmpty ? 'MI NEGOCIO' : negocio.nombre.toUpperCase(),
                      maxLines: 1,
                      style: pw.TextStyle(fontSize: fTitulo, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(esCopia ? 'COPIA' : 'ORIGINAL', style: pw.TextStyle(fontSize: fNormal, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Center(child: pw.Text('TRASLADO', style: pw.TextStyle(fontSize: fTitulo, fontWeight: pw.FontWeight.bold))),
            _separador(),
            _fila('Nº:', t.numero, fNormal),
            _fila('Fecha:', t.fecha != null ? formatoFecha.format(t.fecha!) : '-', fNormal),
            _fila('Estado:', t.estado.toUpperCase(), fNormal),
            _fila('Sucursal origen: ', t.nombreSucursalOrigen, fNormal),
            _fila('Sucursal destino:', t.nombreSucursalDestino, fNormal),
            _fila('Usuario crea:  ', t.usuarioCrea.isEmpty ? '-' : t.usuarioCrea, fNormal),
            _fila('Usuario recibe:', t.usuarioRecibe.isEmpty ? '-' : t.usuarioRecibe, fNormal),
            _separador(),
            pw.Row(
              children: [
                pw.SizedBox(width: 46, child: pw.Text('CÓDIGO', style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text('DESCRIPCIÓN', style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold))),
                pw.Text('CANT', style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            _separador(),
            ...t.detalle.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 46,
                            child: pw.Text(codigosPorProducto[item.idProducto] ?? '', style: pw.TextStyle(fontSize: fNormal)),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Expanded(
                            child: pw.Text(item.nombreProducto, style: pw.TextStyle(fontSize: fNormal)),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(_formatoCantidad(item.cantidad), style: pw.TextStyle(fontSize: fNormal, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 52, top: 1),
                        child: pw.Text(
                          'Ubicación: ${item.ubicacion.trim().isEmpty ? '-' : item.ubicacion}',
                          style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )),
            _separador(),
            if (t.observaciones.isNotEmpty) ...[
              pw.Text('OBSERVACIONES:', style: pw.TextStyle(fontSize: fChica, fontWeight: pw.FontWeight.bold)),
              pw.Text(t.observaciones, style: pw.TextStyle(fontSize: fNormal)),
              _separador(),
            ],
            pw.SizedBox(height: 20),
            _lineaFirma('Entrega Origen', fNormal),
            pw.SizedBox(height: 16),
            _lineaFirma('Recibe Destino', fNormal),
            _separador(),
            pw.Center(child: pw.Text('Documento generado por el sistema', style: pw.TextStyle(fontSize: fChica))),
          ],
          ),
        ];
      },
    );
  }

  double _estimarAlturaMm(TrasladoModel t, NegocioModel negocio, {required bool tieneLogo}) {
    double alto = 16.0
        + 44.0
        + 49.0
        + 8.0
        + 70.0
        + 30.0;
    if (tieneLogo) alto += 24.0;
    if (t.observaciones.isNotEmpty) alto += 16.0 + (t.observaciones.length / 30).ceil() * 7.0;
    for (final item in t.detalle) {
      alto += 26.0;
      if (item.nombreProducto.length > 24) {
        alto += ((item.nombreProducto.length - 24) / 13).ceil() * 6.5;
      }
    }
    return alto.clamp(0, 350);
  }

  pw.Widget _fila(String etiqueta, String valor, double tamano) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$etiqueta ', style: pw.TextStyle(fontSize: tamano, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: valor, style: pw.TextStyle(fontSize: tamano)),
          ],
        ),
      ),
    );
  }

  pw.Widget _lineaFirma(String etiqueta, double tamano) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: double.infinity, height: 1, color: PdfColor.fromInt(0xFF1A1A1A)),
        pw.SizedBox(height: 3),
        pw.Text(etiqueta, style: pw.TextStyle(fontSize: tamano)),
      ],
    );
  }

  pw.Widget _separador() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Container(height: 1, color: PdfColor.fromInt(0xFFBBBBBB)),
    );
  }

  String _formatoCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) return cantidad.toInt().toString();
    return cantidad.toStringAsFixed(2);
  }
}
