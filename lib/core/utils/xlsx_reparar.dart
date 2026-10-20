import 'dart:convert';
import 'package:archive/archive.dart';

List<int> repararRutasXlsx(List<int> bytes) {
  try {
    final archivoOriginal = ZipDecoder().decodeBytes(bytes);
    var huboCambios = false;
    final archivoNuevo = Archive();
    for (final f in archivoOriginal.files) {
      if (f.name.endsWith('.rels')) {
        final contenido = utf8.decode(f.content as List<int>);
        final corregido = contenido.replaceAll('Target="/xl/', 'Target="');
        if (corregido != contenido) {
          huboCambios = true;
          final data = utf8.encode(corregido);
          archivoNuevo.addFile(ArchiveFile(f.name, data.length, data));
          continue;
        }
      }
      archivoNuevo.addFile(ArchiveFile(f.name, f.size, f.content));
    }
    if (!huboCambios) return bytes;
    return ZipEncoder().encode(archivoNuevo) ?? bytes;
  } catch (_) {
    return bytes;
  }
}
