import '../theme/marca.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/impresion_remota_service.dart';
import '../services/impresora_usb_windows_service.dart';
import '../utils/impresion_calentamiento.dart';

class PdfPreviewDialog extends StatefulWidget {
  final String titulo;
  final Future<Uint8List> Function() generarPdf;
  final Future<Uint8List> Function(PdfPageFormat formato)? generarPdfConFormato;
  final String nombreArchivo;
  final Printer? impresora;
  final Future<List<int>> Function()? generarTicketEscPos;
  final String? nombreImpresoraWindows;
  final Widget Function()? vistaPreviaTicket;
  final Future<void> Function()? alFallarImprimir;

  const PdfPreviewDialog({
    super.key,
    required this.titulo,
    required this.generarPdf,
    this.generarPdfConFormato,
    required this.nombreArchivo,
    this.impresora,
    this.generarTicketEscPos,
    this.nombreImpresoraWindows,
    this.vistaPreviaTicket,
    this.alFallarImprimir,
  });

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  bool _imprimiendo = false;

  bool get _usaEscPosEnWindows =>
      !kIsWeb &&
      Platform.isWindows &&
      widget.generarTicketEscPos != null &&
      (widget.nombreImpresoraWindows?.isNotEmpty ?? false);

  bool get _mostrarVistaPreviaTicket =>
      widget.vistaPreviaTicket != null &&
      (_usaEscPosEnWindows || widget.impresora == null);

  Future<void> _imprimirDirecto() async {
    final impresora = widget.impresora;
    if (impresora == null) return;
    setState(() => _imprimiendo = true);
    try {
      if (_usaEscPosEnWindows) {
        final bytes = await widget.generarTicketEscPos!();
        final ok = ImpresoraUsbWindowsService().imprimir(
          nombreImpresora: widget.nombreImpresoraWindows!,
          bytes: bytes,
        );
        if (!ok) throw Exception('No se pudo escribir en la impresora');
        return;
      }
      if (!await calentarImpresionWindows(nombreImpresora: impresora.name)) {
        throw Exception('La impresora no respondió a tiempo');
      }
      final generarConFormato = widget.generarPdfConFormato;
      await Printing.directPrintPdf(
        printer: impresora,
        onLayout: generarConFormato != null
            ? (format) => generarConFormato(format)
            : (format) => widget.generarPdf(),
      );
    } catch (e) {
      final alFallar = widget.alFallarImprimir;
      if (alFallar != null) {
        await alFallar();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo imprimir en la impresora configurada'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  Future<void> _enviarALaPrincipal() async {
    final servicio = ImpresionRemotaService();
    setState(() => _imprimiendo = true);
    String mensaje;
    try {
      if (!await servicio.hayPcPrincipal()) {
        mensaje = 'La caja principal no está conectada: abrí el sistema en esa PC e intentá de nuevo';
      } else {
        await servicio.enviar(await widget.generarTicketEscPos!(), widget.titulo);
        mensaje = 'Se envió la orden de impresión a la caja principal';
      }
    } catch (_) {
      mensaje = 'No se pudo enviar la orden a la caja principal';
    }
    if (!mounted) return;
    setState(() => _imprimiendo = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<Uint8List>? _pdfCache;

  Future<Uint8List> _obtenerPdf() => _pdfCache ??= widget.generarPdf();

  Future<Uint8List> _construirPdf(PdfPageFormat formato) => _obtenerPdf();

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    final anchoDialog = tamano.width < 760 ? tamano.width - 24 : 640.0;
    final altoDialog = tamano.height < 700 ? tamano.height - 60 : 720.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        width: anchoDialog,
        height: kIsWeb ? null : altoDialog,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: kIsWeb ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (widget.impresora != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _imprimiendo ? null : _imprimirDirecto,
                  icon: _imprimiendo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_outlined, size: 18),
                  label: Text(
                    _imprimiendo
                        ? 'Imprimiendo...'
                        : 'Imprimir en ${widget.impresora!.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Marca.primario,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (_mostrarVistaPreviaTicket) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await widget.generarPdf();
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: widget.nombreArchivo,
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(
                    'Compartir PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFB6BCC7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (kIsWeb) _accionesWeb() else _vistaPreviaNativa(),
          ],
        ),
      ),
    );
  }

  Widget _vistaPreviaNativa() {
    final vistaTicket = widget.vistaPreviaTicket;
    if (_mostrarVistaPreviaTicket && vistaTicket != null) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: vistaTicket()),
          ),
        ),
      );
    }
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PdfPreview(
          build: _construirPdf,
          pdfFileName: widget.nombreArchivo,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: widget.generarTicketEscPos == null,
          allowSharing: true,
          useActions: true,
        ),
      ),
    );
  }

  Widget _accionesWeb() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.picture_as_pdf_outlined,
          size: 44,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 10),
        Text(
          'El documento está listo',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        if (widget.generarTicketEscPos != null) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _imprimiendo ? null : _enviarALaPrincipal,
              icon: _imprimiendo
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print, size: 18),
              label: Text(
                'Imprimir en la caja principal',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Marca.primario,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final bytes = await widget.generarPdf();
              await Printing.sharePdf(
                bytes: bytes,
                filename: widget.nombreArchivo,
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(
              'Descargar PDF',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Printing.layoutPdf(
              onLayout: (format) => widget.generarPdf(),
              name: widget.nombreArchivo,
            ),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: Text(
              'Ver / imprimir',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFFB6BCC7)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
