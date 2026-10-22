import '../../../core/services/ticket_generico.dart';
import '../../negocio/data/negocio_model.dart';
import 'dart:typed_data';
import '../../../core/utils/segundo_plano.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart' as bc;
import 'producto_model.dart';
import '../../../core/utils/formato_moneda.dart';

Map<String, String> Function(ProductoModel) _valoresColumna(Map<String, String> mapaCategorias) {
  return (p) => {
    'codigo': p.codigo,
    'codigoBarras': p.codigoBarras,
    'nombre': p.nombre,
    'descripcion': p.descripcion.isEmpty ? '-' : p.descripcion,
    'categoria': mapaCategorias[p.idCategoria] ?? '-',
    'existencia': p.stock.toString(),
    'precioVenta': formatearMoneda(p.precioVenta),
    'precioCompra': formatearMoneda(p.precioCompra),
    'estado': p.estado ? 'Activo' : 'Inactivo',
  };
}

const _etiquetasColumna = {
  'codigo': 'Código',
  'codigoBarras': 'Cód. Barras',
  'nombre': 'Nombre',
  'descripcion': 'Descripción',
  'categoria': 'Categoría',
  'existencia': 'Existencia',
  'precioVenta': 'P. Venta',
  'precioCompra': 'P. Compra',
  'estado': 'Estado',
};

const _ordenColumnas = ['codigo', 'codigoBarras', 'nombre', 'descripcion', 'categoria', 'existencia', 'precioVenta', 'precioCompra', 'estado'];

class ProductoExportService {
  Uint8List generarExcel(List<ProductoModel> lista, Map<String, String> mapaCategorias, {Set<String>? columnas}) {
    final claves = _ordenColumnas.where((c) => columnas == null || columnas.contains(c)).toList();
    final valores = _valoresColumna(mapaCategorias);
    final libro = xls.Excel.createExcel();
    final hoja = libro['Inventario'];
    libro.delete('Sheet1');

    hoja.appendRow([for (final c in claves) xls.TextCellValue(_etiquetasColumna[c]!)]);

    for (final p in lista) {
      final fila = valores(p);
      hoja.appendRow([for (final c in claves) xls.TextCellValue(fila[c]!)]);
    }

    final bytes = libro.save();
    return Uint8List.fromList(bytes ?? []);
  }

  Future<Uint8List> generarPdfInventario(List<ProductoModel> lista, Map<String, String> mapaCategorias, {Set<String>? columnas}) =>
      enSegundoPlano(() => _generarPdfInventario(lista, mapaCategorias, columnas: columnas));

  Future<Uint8List> _generarPdfInventario(List<ProductoModel> lista, Map<String, String> mapaCategorias, {Set<String>? columnas}) async {
    final claves = _ordenColumnas.where((c) => columnas == null || columnas.contains(c)).toList();
    final valores = _valoresColumna(mapaCategorias);
    const anchoPorColumna = {
      'codigo': 1.2,
      'codigoBarras': 1.6,
      'nombre': 2.4,
      'descripcion': 2.4,
      'categoria': 1.6,
      'existencia': 1.1,
      'precioVenta': 1.3,
      'precioCompra': 1.3,
      'estado': 1.1,
    };
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        maxPages: 2000,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Inventario · CK', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F1B3D))),
            pw.SizedBox(height: 4),
            pw.Text('Total de productos: ${lista.length}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 14),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [for (final c in claves) _etiquetasColumna[c]!],
            data: lista.map((p) {
              final fila = valores(p);
              return [for (final c in claves) fila[c]!];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F1B3D)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EAF0)),
            border: null,
            columnWidths: {for (var i = 0; i < claves.length; i++) i: pw.FlexColumnWidth(anchoPorColumna[claves[i]]!)},
          ),
        ],
      ),
    );
    return doc.save();
  }

  List<LineaTicket> lineasTicket(
    List<ProductoModel> lista,
    Map<String, String> mapaCategorias,
    Set<String> campos,
    NegocioModel negocio,
  ) {
    return [
      if (negocio.nombre.isNotEmpty) LTexto(negocio.nombre.toUpperCase(), alineacion: AlineacionTicket.centro, negrita: true),
      const LTexto('Listado de Inventario', alineacion: AlineacionTicket.centro),
      const LSeparador(),
      for (final p in lista) ...[
        if (campos.contains('codigo')) LTexto('Codigo: ${p.codigo}'),
        LTexto(p.nombre, negrita: true),
        if (campos.contains('descripcion') && p.descripcion.isNotEmpty) LTexto(p.descripcion),
        if (campos.contains('categoria')) LTexto('Categoria: ${mapaCategorias[p.idCategoria] ?? '-'}'),
        if (campos.contains('existencia')) LTexto('Existencia: ${p.stock}'),
        if (campos.contains('precioVenta')) LPar('P. Venta', formatearMoneda(p.precioVenta)),
        if (campos.contains('precioCompra')) LPar('P. Compra', formatearMoneda(p.precioCompra)),
        const LSeparador(),
      ],
      const LEspacio(),
    ];
  }

  Future<Uint8List> generarPdfTicket(
    List<ProductoModel> lista,
    Map<String, String> mapaCategorias,
    Set<String> campos,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 8),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('AUTOPARTS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Listado de Inventario', style: const pw.TextStyle(fontSize: 9))),
              pw.SizedBox(height: 8),
              pw.Divider(),
              ...lista.map((p) {
                final lineas = <pw.Widget>[];
                if (campos.contains('codigo')) lineas.add(pw.Text('Código: ${p.codigo}', style: const pw.TextStyle(fontSize: 8)));
                lineas.add(pw.Text(p.nombre, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)));
                if (campos.contains('descripcion') && p.descripcion.isNotEmpty) {
                  lineas.add(pw.Text(p.descripcion, style: const pw.TextStyle(fontSize: 7.5)));
                }
                if (campos.contains('categoria')) {
                  lineas.add(pw.Text('Categoría: ${mapaCategorias[p.idCategoria] ?? '-'}', style: const pw.TextStyle(fontSize: 7.5)));
                }
                if (campos.contains('existencia')) {
                  lineas.add(pw.Text('Existencia: ${p.stock}', style: const pw.TextStyle(fontSize: 7.5)));
                }
                if (campos.contains('precioVenta')) {
                  lineas.add(pw.Text('P. Venta: ${formatearMoneda(p.precioVenta)}', style: const pw.TextStyle(fontSize: 7.5)));
                }
                if (campos.contains('precioCompra')) {
                  lineas.add(pw.Text('P. Compra: ${formatearMoneda(p.precioCompra)}', style: const pw.TextStyle(fontSize: 7.5)));
                }
                lineas.add(pw.SizedBox(height: 6));
                lineas.add(pw.Divider());
                return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: lineas);
              }),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  Future<Uint8List> generarPdfEtiquetasGrid(List<ProductoModel> productos) =>
      enSegundoPlano(() => _generarPdfEtiquetasGrid(productos));

  Future<Uint8List> _generarPdfEtiquetasGrid(List<ProductoModel> productos) async {
    const columnas = 1;
    const anchoEtiquetaMm = 50.8;
    const altoEtiquetaMm = 25.4;
    const margenMm = 3.0;
    final doc = pw.Document();

    final filas = <List<ProductoModel?>>[];
    for (var i = 0; i < productos.length; i += columnas) {
      filas.add(List.generate(columnas, (j) => i + j < productos.length ? productos[i + j] : null));
    }

    pw.Widget etiqueta(ProductoModel? p) {
      if (p == null) return pw.SizedBox(width: anchoEtiquetaMm * PdfPageFormat.mm, height: altoEtiquetaMm * PdfPageFormat.mm);
      final codigo = p.codigoBarras.isNotEmpty ? p.codigoBarras : p.codigo;
      return pw.Container(
        width: anchoEtiquetaMm * PdfPageFormat.mm,
        height: altoEtiquetaMm * PdfPageFormat.mm,
        padding: const pw.EdgeInsets.all(4),
        alignment: pw.Alignment.center,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(p.nombre, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center, maxLines: 1, overflow: pw.TextOverflow.clip),
            pw.SizedBox(height: 3),
            pw.BarcodeWidget(barcode: bc.Barcode.code128(), data: codigo, width: (anchoEtiquetaMm - 10) * PdfPageFormat.mm, height: 30),
            pw.SizedBox(height: 2),
            pw.Text(codigo, style: const pw.TextStyle(fontSize: 7)),
            pw.Text(formatearMoneda(p.precioVenta), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    final altoPaginaMm = margenMm * 2 + filas.length * altoEtiquetaMm;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, altoPaginaMm * PdfPageFormat.mm, marginAll: margenMm * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            children: filas
                .map((fila) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: fila.map(etiqueta).toList(),
                    ))
                .toList(),
          );
        },
      ),
    );
    return doc.save();
  }
}