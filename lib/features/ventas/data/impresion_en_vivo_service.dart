import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import '../../negocio/data/negocio_model.dart';
import '../../../core/services/impresora_usb_windows_service.dart';
import '../../../core/services/impresora_red_service.dart';
import 'venta_export_service.dart';
import 'venta_model.dart';
import 'venta_ticket_escpos_service.dart';
import '../../../core/utils/impresion_calentamiento.dart';

class ImpresionEnVivoService {
  final _servicioExport = VentaExportService();
  final _servicioTicketEscPos = VentaTicketEscPosService();
  final _servicioImpresoraRed = ImpresoraRedService();

  Future<bool> imprimirSilencioso(VentaModel venta, NegocioModel negocio, {bool? forzarCopia}) async {
    if (negocio.impresoraTermicaUrl.isEmpty) return false;
    if (!kIsWeb && Platform.isWindows && !negocio.impresoraUsbUsarDriverWindows) {
      try {
        final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio, forzarCopia: forzarCopia);
        return ImpresoraUsbWindowsService().imprimir(nombreImpresora: negocio.impresoraTermicaNombre, bytes: bytes);
      } catch (_) {
        return false;
      }
    }
    try {
      if (!await calentarImpresionWindows(nombreImpresora: negocio.impresoraTermicaNombre)) {
        return false;
      }
      final impresora = Printer(url: negocio.impresoraTermicaUrl, name: negocio.impresoraTermicaNombre);
      await Printing.directPrintPdf(
        printer: impresora,
        onLayout: (formato) => _servicioExport.generarPdfFactura(venta, negocio, forzarCopia: forzarCopia, formatoImpresora: formato),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> imprimirGuiaSilencioso(VentaModel venta, NegocioModel negocio, {bool grande = false}) async {
    try {
      final bytes = await _servicioTicketEscPos.generarGuiaEnvio(venta, negocio, grande: grande);
      if (!kIsWeb && Platform.isWindows) {
        if (negocio.impresoraTermicaNombre.isEmpty) return false;
        if (negocio.impresoraUsbUsarDriverWindows) return false;
        return ImpresoraUsbWindowsService().imprimir(nombreImpresora: negocio.impresoraTermicaNombre, bytes: bytes);
      }
      if (negocio.impresoraRedIp.isEmpty) return false;
      return await _servicioImpresoraRed.imprimir(ip: negocio.impresoraRedIp, puerto: negocio.impresoraRedPuerto, bytes: bytes);
    } catch (_) {
      return false;
    }
  }
}
