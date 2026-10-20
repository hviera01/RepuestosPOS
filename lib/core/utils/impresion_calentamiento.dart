import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';

Future<bool> calentarImpresionWindows({String? nombreImpresora}) async {
  if (kIsWeb || !Platform.isWindows) return true;
  try {
    final impresoras = await Printing.listPrinters().timeout(const Duration(seconds: 3));
    if (nombreImpresora == null || nombreImpresora.isEmpty) return true;
    return impresoras.any((p) => p.name == nombreImpresora);
  } catch (_) {
    return false;
  }
}
