import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class ImpresoraUsbWindowsService {
  bool imprimir({required String nombreImpresora, required List<int> bytes}) {
    if (nombreImpresora.trim().isEmpty || bytes.isEmpty) return false;

    final phPrinter = calloc<IntPtr>();
    final nombrePtr = nombreImpresora.toNativeUtf16();
    var hPrinter = 0;
    var docIniciado = false;
    var paginaIniciada = false;

    try {
      if (OpenPrinter(nombrePtr, phPrinter, nullptr) == 0) return false;
      hPrinter = phPrinter.value;

      final docInfo = calloc<DOC_INFO_1>();
      final docNamePtr = 'Ticket de venta'.toNativeUtf16();
      final dataTypePtr = 'RAW'.toNativeUtf16();
      try {
        docInfo.ref.pDocName = docNamePtr;
        docInfo.ref.pOutputFile = nullptr;
        docInfo.ref.pDatatype = dataTypePtr;
        if (StartDocPrinter(hPrinter, 1, docInfo) == 0) return false;
        docIniciado = true;
      } finally {
        calloc.free(docInfo);
        calloc.free(docNamePtr);
        calloc.free(dataTypePtr);
      }

      if (StartPagePrinter(hPrinter) == 0) return false;
      paginaIniciada = true;

      final buffer = calloc<Uint8>(bytes.length);
      final bytesEscritos = calloc<Uint32>();
      try {
        for (var i = 0; i < bytes.length; i++) {
          buffer[i] = bytes[i];
        }
        final ok = WritePrinter(hPrinter, buffer.cast(), bytes.length, bytesEscritos);
        return ok != 0 && bytesEscritos.value == bytes.length;
      } finally {
        calloc.free(buffer);
        calloc.free(bytesEscritos);
      }
    } catch (_) {
      return false;
    } finally {
      if (paginaIniciada) EndPagePrinter(hPrinter);
      if (docIniciado) EndDocPrinter(hPrinter);
      if (hPrinter != 0) ClosePrinter(hPrinter);
      calloc.free(phPrinter);
      calloc.free(nombrePtr);
    }
  }
}
