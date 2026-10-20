import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/services/impresora_red_service.dart';
import '../../../core/services/impresora_usb_windows_service.dart';
import '../../../core/widgets/pdf_preview_dialog.dart';
import '../presentation/widgets/ticket_escpos_preview.dart';
import '../../negocio/data/negocio_model.dart';
import 'presencia_impresion_repository.dart';
import 'venta_export_service.dart';
import 'venta_model.dart';
import 'venta_repository.dart';
import 'venta_ticket_escpos_service.dart';
import '../../../core/utils/impresion_calentamiento.dart';

class ImpresionPendienteService {
  final _servicioExport = VentaExportService();
  final _servicioTicketEscPos = VentaTicketEscPosService();
  final _servicioImpresoraRed = ImpresoraRedService();
  final _presencia = PresenciaImpresionRepository();

  Future<void> imprimir({
    required BuildContext context,
    required VentaModel venta,
    required NegocioModel negocio,
    required VentaRepository ventaRepo,
    required void Function(String mensaje) mostrarMensaje,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      await _imprimirEscPosRed(venta, negocio, ventaRepo, mostrarMensaje);
      return;
    }

    if (negocio.modoImpresion != ModoImpresion.directo) {
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
          titulo: 'Vista previa · ${venta.numeroDocumento}',
          nombreArchivo: 'venta_${venta.numeroDocumento}.pdf',
          generarPdf: () => _servicioExport.generarPdfFactura(venta, negocio),
          generarPdfConFormato: (formato) => _servicioExport.generarPdfFactura(
            venta,
            negocio,
            formatoImpresora: formato,
          ),
          impresora: impresora,
          generarTicketEscPos: () =>
              _servicioTicketEscPos.generarTicket(venta, negocio),
          nombreImpresoraWindows: negocio.impresoraUsbUsarDriverWindows
              ? null
              : negocio.impresoraTermicaNombre,
          vistaPreviaTicket: () => TicketEscPosPreview(
            venta: venta,
            negocio: negocio,
            esCopia: false,
          ),
        ),
      );
      await ventaRepo.marcarPendienteImpresion(venta.id, false);
      return;
    }

    final esMovil =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (kIsWeb && esMovil) {
      await _pedirImpresionEnVivoOMensaje(
        venta,
        ventaRepo,
        mostrarMensaje,
        mensajeSinPc:
            'No se puede imprimir directo desde el navegador del celular',
      );
      return;
    }

    if (kIsWeb) {
      try {
        await Printing.layoutPdf(
          onLayout: (formato) =>
              _servicioExport.generarPdfFactura(venta, negocio),
          name: 'venta_${venta.numeroDocumento}.pdf',
        );
        await ventaRepo.marcarPendienteImpresion(venta.id, false);
      } catch (_) {
        mostrarMensaje('No se pudo imprimir');
      }
      return;
    }

    if (Platform.isIOS) {
      await _imprimirEscPosRed(venta, negocio, ventaRepo, mostrarMensaje);
      return;
    }

    if (negocio.impresoraTermicaUrl.isEmpty) {
      mostrarMensaje('No hay impresora configurada');
      return;
    }
    if (!kIsWeb && Platform.isWindows && !negocio.impresoraUsbUsarDriverWindows) {
      try {
        final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio);
        final ok = ImpresoraUsbWindowsService().imprimir(
          nombreImpresora: negocio.impresoraTermicaNombre,
          bytes: bytes,
        );
        if (ok) {
          await ventaRepo.marcarPendienteImpresion(venta.id, false);
        } else {
          mostrarMensaje('No se pudo imprimir en la impresora configurada');
        }
      } catch (_) {
        mostrarMensaje('No se pudo imprimir en la impresora configurada');
      }
      return;
    }
    try {
      if (!await calentarImpresionWindows(nombreImpresora: negocio.impresoraTermicaNombre)) {
        mostrarMensaje('No se pudo confirmar la impresora, quedó pendiente de impresión');
        return;
      }
      final impresora = Printer(
        url: negocio.impresoraTermicaUrl,
        name: negocio.impresoraTermicaNombre,
      );
      await Printing.directPrintPdf(
        printer: impresora,
        onLayout: (formato) => _servicioExport.generarPdfFactura(
          venta,
          negocio,
          formatoImpresora: formato,
        ),
      );
      await ventaRepo.marcarPendienteImpresion(venta.id, false);
    } catch (_) {
      mostrarMensaje('No se pudo imprimir en la impresora configurada');
    }
  }

  Future<void> _imprimirEscPosRed(
    VentaModel venta,
    NegocioModel negocio,
    VentaRepository ventaRepo,
    void Function(String) mostrarMensaje,
  ) async {
    if (negocio.impresoraRedIp.isNotEmpty) {
      final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio);
      final ok = await _servicioImpresoraRed.imprimir(
        ip: negocio.impresoraRedIp,
        puerto: negocio.impresoraRedPuerto,
        bytes: bytes,
      );
      if (ok) {
        await ventaRepo.marcarPendienteImpresion(venta.id, false);
        return;
      }
    }
    await _pedirImpresionEnVivoOMensaje(venta, ventaRepo, mostrarMensaje);
  }

  Future<void> _pedirImpresionEnVivoOMensaje(
    VentaModel venta,
    VentaRepository ventaRepo,
    void Function(String) mostrarMensaje, {
    String mensajeSinPc = 'No se pudo imprimir',
  }) async {
    final pcConectada = await _presencia.estaConectada();
    if (pcConectada) {
      await ventaRepo.marcarSolicitudImpresionEnVivo(venta.id, true);
      mostrarMensaje('Se envió la orden de impresión a la caja principal');
    } else {
      mostrarMensaje(mensajeSinPc);
    }
  }
}
