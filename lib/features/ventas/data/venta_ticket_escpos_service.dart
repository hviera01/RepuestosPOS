import 'dart:ui' as ui;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'venta_model.dart';
import 'numero_a_letras.dart';
import 'tipos_documento.dart';
import '../../../core/utils/formato_moneda.dart';
import '../../../core/utils/logo_escpos.dart';
import '../../../core/utils/texto_utils.dart';
import '../../negocio/data/negocio_model.dart';

class _SeccionGuiaGrande {
  _SeccionGuiaGrande(this.etiqueta, this.valor, {required this.fontEtiqueta, required this.fontValor, required this.maxAnchoValor});

  final String etiqueta;
  final String valor;
  final double fontEtiqueta;
  final double fontValor;
  final double maxAnchoValor;

  late TextPainter _painterEtiqueta;
  late TextPainter _painterValor;
  double ancho = 0;

  void medir() {
    _painterEtiqueta = TextPainter(
      text: TextSpan(text: etiqueta, style: TextStyle(color: const Color(0xFF000000), fontSize: fontEtiqueta, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    _painterValor = TextPainter(
      text: TextSpan(text: valor, style: TextStyle(color: const Color(0xFF000000), fontSize: fontValor, fontWeight: FontWeight.bold)),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxAnchoValor);
    ancho = [_painterEtiqueta.width, _painterValor.width].reduce((a, b) => a > b ? a : b);
  }

  void pintar(Canvas canvas, double x, double altoLienzo) {
    const espacioEtiquetaValor = 14.0;
    final altoBloque = _painterEtiqueta.height + espacioEtiquetaValor + _painterValor.height;
    final yInicial = ((altoLienzo - altoBloque) / 2).clamp(0.0, altoLienzo);
    _painterEtiqueta.paint(canvas, Offset(x, yInicial));
    _painterValor.paint(canvas, Offset(x, yInicial + _painterEtiqueta.height + espacioEtiquetaValor));
  }
}

class VentaTicketEscPosService {
  Future<List<int>> generarTicket(VentaModel venta, NegocioModel negocio, {bool? forzarCopia}) async {
    final perfil = await CapabilityProfile.load();
    final paperSize = _paperSizePara(negocio);
    final generador = Generator(paperSize, perfil);
    final logo = decodificarLogoEscPos(negocio.logoBnBase64, maxDimension: paperSize == PaperSize.mm58 ? 280 : 420);
    final anchoDescripcion = _anchoDescripcionPara(paperSize);
    final anchoTexto = _anchoTextoPara(paperSize);

    List<int> bytes = [];
    bytes += generador.reset();
    bytes += _construirTicket(generador, venta, negocio, logo, esCopia: forzarCopia ?? false, anchoDescripcion: anchoDescripcion, anchoTexto: anchoTexto);
    if (forzarCopia == null && negocio.facturaImprimirCopia) {
      bytes += _construirTicket(generador, venta, negocio, logo, esCopia: true, anchoDescripcion: anchoDescripcion, anchoTexto: anchoTexto);
    }
    return bytes;
  }

  PaperSize _paperSizePara(NegocioModel negocio) => negocio.anchoTicketMm == 58 ? PaperSize.mm58 : PaperSize.mm80;

  Future<List<int>> generarGuiaEnvio(VentaModel venta, NegocioModel negocio, {bool grande = false}) async {
    final perfil = await CapabilityProfile.load();
    final generador = Generator(PaperSize.mm80, perfil);

    List<int> bytes = [];
    bytes += generador.reset();

    if (grande) {
      final imagen = await _renderizarGuiaRotada(venta, negocio);
      bytes += generador.image(imagen);
      bytes += generador.emptyLines(2);
      bytes += generador.cut();
      return bytes;
    }

    final formatoFecha = DateFormat('dd/MM/yyyy hh:mm a');
    if (negocio.nombre.isNotEmpty) {
      bytes += _texto(generador, negocio.nombre.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true));
    }
    bytes += _texto(generador, 'GUIA DE ENVIO', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generador.hr();
    bytes += generador.emptyLines(1);

    bytes += _texto(generador, 'PARA:', styles: const PosStyles(bold: true));
    for (final linea in _envolverDescripcion(venta.envioNombre, _anchoDoble)) {
      bytes += _texto(generador, linea, styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    }
    bytes += generador.emptyLines(1);

    if (venta.envioDireccion.isNotEmpty) {
      bytes += _texto(generador, 'DIRECCION:', styles: const PosStyles(bold: true));
      for (final linea in _envolverDescripcion(venta.envioDireccion, _anchoCompleto)) {
        bytes += _texto(generador, linea, styles: const PosStyles(bold: true, height: PosTextSize.size2));
      }
      bytes += generador.emptyLines(1);
    }

    if (venta.envioTelefono.isNotEmpty) {
      bytes += _texto(generador, 'TELEFONO:', styles: const PosStyles(bold: true));
      bytes += _texto(generador, venta.envioTelefono, styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generador.emptyLines(1);
    }

    bytes += generador.hr();
    bytes += _texto(generador, '${tiposDocumento[venta.tipoDocumento] ?? venta.tipoDocumento} ${negocio.rangoPrefijo}${venta.numeroDocumento}');
    bytes += _texto(generador, 'Fecha: ${venta.fechaRegistro != null ? formatoFecha.format(venta.fechaRegistro!) : '-'}');
    if (venta.nombreCliente.isNotEmpty && venta.nombreCliente != venta.envioNombre) {
      bytes += _texto(generador, 'Comprador: ${venta.nombreCliente}');
    }
    bytes += generador.emptyLines(2);
    bytes += generador.cut();

    return bytes;
  }

  static const _altoLienzoGuiaGrande = 576;
  static const _margenGuiaGrande = 24.0;
  static const _separacionSeccionGuiaGrande = 48.0;

  Future<img.Image> _renderizarGuiaRotada(VentaModel venta, NegocioModel negocio) async {
    final secciones = <_SeccionGuiaGrande>[
      _SeccionGuiaGrande('PARA', venta.envioNombre, fontEtiqueta: 26, fontValor: 65, maxAnchoValor: 550),
      if (venta.envioDireccion.isNotEmpty) _SeccionGuiaGrande('DIRECCION', venta.envioDireccion, fontEtiqueta: 26, fontValor: 50, maxAnchoValor: 550),
      if (venta.envioTelefono.isNotEmpty) _SeccionGuiaGrande('TELEFONO', venta.envioTelefono, fontEtiqueta: 26, fontValor: 65, maxAnchoValor: 400),
      _SeccionGuiaGrande(
        negocio.nombre.isEmpty ? '' : negocio.nombre.toUpperCase(),
        '${tiposDocumento[venta.tipoDocumento] ?? venta.tipoDocumento} ${negocio.rangoPrefijo}${venta.numeroDocumento}',
        fontEtiqueta: 22,
        fontValor: 28,
        maxAnchoValor: 500,
      ),
    ];

    for (final s in secciones) {
      s.medir();
    }
    final anchoTotal = secciones.fold<double>(_margenGuiaGrande, (s, seccion) => s + seccion.ancho + _separacionSeccionGuiaGrande);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, anchoTotal, _altoLienzoGuiaGrande.toDouble()));
    canvas.drawRect(Rect.fromLTWH(0, 0, anchoTotal, _altoLienzoGuiaGrande.toDouble()), Paint()..color = const Color(0xFFFFFFFF));

    var x = _margenGuiaGrande;
    for (final seccion in secciones) {
      seccion.pintar(canvas, x, _altoLienzoGuiaGrande.toDouble());
      x += seccion.ancho + _separacionSeccionGuiaGrande;
    }

    final picture = recorder.endRecording();
    final imagenUi = await picture.toImage(anchoTotal.ceil(), _altoLienzoGuiaGrande);
    final bytesRgba = await imagenUi.toByteData(format: ui.ImageByteFormat.rawRgba);
    final lienzo = img.Image.fromBytes(
      width: imagenUi.width,
      height: imagenUi.height,
      bytes: bytesRgba!.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return img.copyRotate(lienzo, angle: 90).convert(numChannels: 3);
  }

  List<int> _texto(Generator g, String texto, {PosStyles styles = const PosStyles(), int? maxAncho}) {
    final limpio = quitarTildes(texto);
    if (maxAncho == null) return g.text(limpio, styles: styles);
    List<int> bytes = [];
    for (final linea in _envolverDescripcion(limpio, maxAncho)) {
      bytes += g.text(linea, styles: styles);
    }
    return bytes;
  }

  PosColumn _columna(String texto, {required int width, PosStyles styles = const PosStyles()}) {
    return PosColumn(text: quitarTildes(texto), width: width, styles: styles);
  }

  int _anchoDescripcionPara(PaperSize paperSize) => paperSize == PaperSize.mm58 ? 20 : 31;

  int _anchoTextoPara(PaperSize paperSize) => paperSize == PaperSize.mm58 ? 32 : 48;

  static const _anchoCompleto = 48;
  static const _anchoDoble = 24;

  List<String> _envolverDescripcion(String texto, int maxAncho) {
    final palabras = texto.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return [''];

    final lineas = <String>[];
    var actual = '';

    void cerrarLinea() {
      if (actual.isNotEmpty) {
        lineas.add(actual);
        actual = '';
      }
    }

    for (var palabra in palabras) {
      if (actual.isEmpty && palabra.length <= maxAncho) {
        actual = palabra;
        continue;
      }
      if (palabra.length <= maxAncho) {
        if (actual.length + 1 + palabra.length <= maxAncho) {
          actual = '$actual $palabra';
        } else {
          cerrarLinea();
          actual = palabra;
        }
        continue;
      }

      cerrarLinea();
      var restante = palabra;
      while (restante.length > maxAncho) {
        var corte = maxAncho - 1;
        if (restante.length - corte < 2) corte -= (2 - (restante.length - corte));
        corte = corte.clamp(2, maxAncho - 1);
        lineas.add('${restante.substring(0, corte)}-');
        restante = restante.substring(corte);
      }
      actual = restante;
    }
    cerrarLinea();
    return lineas;
  }

  List<int> _construirTicket(Generator generador, VentaModel venta, NegocioModel negocio, img.Image? logo, {required bool esCopia, required int anchoDescripcion, required int anchoTexto}) {
    final formatoFecha = DateFormat('dd/MM/yyyy hh:mm a');
    final formatoDia = DateFormat('dd/MM/yyyy');

    final esFacturable = venta.tipoDocumento == 'Factura' || venta.tipoDocumento == 'Boleta';
    final mostrarConIsv = esFacturable && negocio.facturaPreciosConIsv;
    double precioMostrado(dynamic item) => mostrarConIsv ? redondearMoneda((item.precioVenta as double) * 1.15) : item.precioVenta as double;
    double importeMostrado(dynamic item) {
      if (!mostrarConIsv) return item.subtotal as double;
      final precio = precioMostrado(item);
      return redondearMoneda(precio * (item.cantidad as double) * (1 - (item.descuentoPorcentaje as double) / 100));
    }
    final descuentosYRebajas = venta.descuentosYRebajas;

    List<int> bytes = [];

    if (logo != null) bytes += generador.image(logo);
    if (negocio.nombre.isNotEmpty) {
      bytes += _encabezadoNombreNegocio(generador, negocio.nombre, anchoTexto);
    }
    if (negocio.eslogan.isNotEmpty) bytes += _texto(generador, negocio.eslogan, styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    if (negocio.direccion.isNotEmpty) bytes += _texto(generador, 'Direccion: ${negocio.direccion}', styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    if (negocio.rtn.isNotEmpty) bytes += _texto(generador, 'RTN: ${negocio.rtn}', styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    if (negocio.telefono.isNotEmpty) bytes += _texto(generador, 'Tel: ${negocio.telefono}', styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    if (negocio.correo.isNotEmpty) bytes += _texto(generador, 'Email: ${negocio.correo}', styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    if (negocio.cai.isNotEmpty) bytes += _texto(generador, 'CAI: ${negocio.cai}', styles: const PosStyles(align: PosAlign.center), maxAncho: anchoTexto);
    bytes += generador.emptyLines(1);
    bytes += generador.hr();

    bytes += _texto(generador, '${(tiposDocumento[venta.tipoDocumento] ?? venta.tipoDocumento).toUpperCase()} ${negocio.rangoPrefijo}${venta.numeroDocumento}', styles: const PosStyles(bold: true), maxAncho: anchoTexto);
    bytes += _texto(generador, 'Fecha: ${venta.fechaRegistro != null ? formatoFecha.format(venta.fechaRegistro!) : '-'}', maxAncho: anchoTexto);
    bytes += _texto(generador, 'Atendido por: ${venta.usuarioRegistro}', maxAncho: anchoTexto);
    bytes += _texto(generador, 'Condicion: ${venta.condicion}', maxAncho: anchoTexto);
    if (venta.condicion == 'Credito' && venta.fechaVencimiento != null) {
      bytes += _texto(generador, 'Fecha de vencimiento: ${formatoDia.format(venta.fechaVencimiento!)}', maxAncho: anchoTexto);
    }
    bytes += generador.hr();

    bytes += _texto(generador, 'Cliente: ${venta.nombreCliente.isEmpty ? 'CONSUMIDOR FINAL' : venta.nombreCliente}', maxAncho: anchoTexto);
    bytes += _texto(generador, 'ID/RTN Cliente: ${venta.documentoCliente.isEmpty ? 'N/A' : venta.documentoCliente}', maxAncho: anchoTexto);
    if (venta.oc.isNotEmpty) bytes += _texto(generador, 'No. O/C exenta: ${venta.oc}', maxAncho: anchoTexto);
    if (venta.regExonerado.isNotEmpty) bytes += _texto(generador, 'No. Reg de exonerado: ${venta.regExonerado}', maxAncho: anchoTexto);
    if (venta.regSag.isNotEmpty) bytes += _texto(generador, 'No. De reg de la SAG: ${venta.regSag}', maxAncho: anchoTexto);
    if (venta.observaciones.isNotEmpty) {
      bytes += generador.hr();
      bytes += _texto(generador, 'Observaciones: ${venta.observaciones}', maxAncho: anchoTexto);
    }
    bytes += generador.hr();

    bytes += generador.row([
      _columna('CANT DESCRIPCION', width: 8, styles: const PosStyles(bold: true)),
      _columna('IMPORTE', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generador.hr();

    for (final item in venta.detalle) {
      for (final linea in _envolverDescripcion(item.nombreProducto, anchoDescripcion)) {
        bytes += generador.row([
          _columna(linea, width: 8),
          _columna('', width: 4),
        ]);
      }
      bytes += generador.row([
        _columna('${_formatoCantidad(item.cantidad)} x ${formatearMoneda(precioMostrado(item))}${item.descuentoPorcentaje > 0 ? ' (-${_formatoCantidad(item.descuentoPorcentaje)}%)' : ''}', width: 8),
        _columna(formatearMoneda(importeMostrado(item)), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generador.emptyLines(1);
    }
    bytes += generador.hr();

    bytes += _filaTotal(generador, 'SUBTOTAL:', venta.subtotal);
    if (venta.descuentoGlobal > 0) bytes += _texto(generador, 'Descuento global: ${_formatoCantidad(venta.descuentoGlobal)}%');
    if (descuentosYRebajas > 0) bytes += _filaTotal(generador, 'Descuentos y rebajas:', descuentosYRebajas);
    if (esFacturable) {
      bytes += _filaTotal(generador, 'Gravado 15%:', venta.subtotal);
      bytes += _filaTotal(generador, 'Gravado 18%:', 0);
      bytes += _filaTotal(generador, 'ISV 15%:', venta.impuesto);
    }
    bytes += _filaTotal(generador, 'TOTAL A PAGAR:', venta.totalAPagar, negrita: true);
    bytes += generador.emptyLines(1);
    bytes += generador.hr();

    bytes += _texto(generador, 'Son: ${convertirNumeroALetras(venta.totalAPagar)}', maxAncho: anchoTexto);
    if (venta.condicion != 'Credito') {
      if (venta.metodoPago == 'Efectivo') {
        bytes += _texto(generador, 'Efectivo: ${formatearMoneda(venta.montoPago)}', maxAncho: anchoTexto);
        bytes += _texto(generador, 'Cambio: ${formatearMoneda(venta.montoCambio)}', maxAncho: anchoTexto);
      } else if (venta.metodoPago == 'Tarjeta') {
        bytes += _texto(generador, 'Pago con tarjeta: ${formatearMoneda(venta.totalAPagar)}', maxAncho: anchoTexto);
      } else if (venta.metodoPago == 'Transferencia') {
        bytes += _texto(generador, 'Transferencia');
      } else if (venta.metodoPago == 'Cheque') {
        bytes += _texto(generador, 'Pago con cheque: ${formatearMoneda(venta.totalAPagar)}', maxAncho: anchoTexto);
      } else if (venta.metodoPago == 'Mixto') {
        for (final pago in venta.pagosMixtos) {
          bytes += _texto(generador, '${pago.metodoPago}: ${formatearMoneda(pago.monto)}', maxAncho: anchoTexto);
        }
      }
    }
    bytes += generador.hr();

    if (negocio.rangoPrefijo.isNotEmpty || negocio.rangoDesde.isNotEmpty) {
      bytes += _texto(generador, 'Rango Aut.: ${negocio.rangoPrefijo}${negocio.rangoDesde} al ${negocio.rangoPrefijo}${negocio.rangoHasta}', maxAncho: anchoTexto);
    }
    if (negocio.fechaLimiteEmision != null) {
      bytes += _texto(generador, 'Fecha Limite: ${formatoDia.format(negocio.fechaLimiteEmision!)}', maxAncho: anchoTexto);
    }
    bytes += generador.emptyLines(1);
    bytes += _texto(generador, 'GRACIAS POR SU COMPRA!', styles: const PosStyles(align: PosAlign.center, bold: true), maxAncho: anchoTexto);
    bytes += generador.emptyLines(1);
    bytes += _texto(generador, esCopia ? 'COPIA' : 'ORIGINAL', styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generador.cut();

    return bytes;
  }

  List<int> _encabezadoNombreNegocio(Generator g, String nombre, int anchoTexto) {
    final nombreMayus = nombre.toUpperCase().trim();
    const styles = PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2);
    final espacio = nombreMayus.indexOf(' ');
    if (espacio == -1) {
      return _texto(g, nombreMayus, styles: styles, maxAncho: anchoTexto ~/ 2);
    }
    List<int> bytes = [];
    bytes += _texto(g, nombreMayus.substring(0, espacio), styles: styles, maxAncho: anchoTexto ~/ 2);
    bytes += _texto(g, nombreMayus.substring(espacio + 1).trim(), styles: styles, maxAncho: anchoTexto ~/ 2);
    return bytes;
  }

  List<int> _filaTotal(Generator generador, String etiqueta, double valor, {bool negrita = false}) {
    return generador.row([
      _columna(etiqueta, width: 8, styles: PosStyles(bold: negrita)),
      _columna(formatearMoneda(valor), width: 4, styles: PosStyles(align: PosAlign.right, bold: negrita)),
    ]);
  }

  String _formatoCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) return cantidad.toInt().toString();
    return cantidad.toStringAsFixed(2);
  }
}
