import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/core/services/firma_actualizacion.dart';

void main() {
  test('firma real verifica y detecta manipulacion', () async {
    final llave = File(r'C:\Proyectos\repuestos_pos_secrets\firma_actualizaciones.key');
    if (!llave.existsSync()) {
      markTestSkipped('sin llave privada local');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('firma_test');
    final archivo = File('${dir.path}/instalador.exe')..writeAsBytesSync(List.generate(5000, (i) => i % 251));
    final r = await Process.run('dart', ['run', 'tool/firmar_release.dart', archivo.path], runInShell: true);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    final firma = File('${archivo.path}.firma').readAsStringSync();
    expect(await FirmaActualizacion.comprobar(archivo, firma), isTrue);
    archivo.writeAsBytesSync([...archivo.readAsBytesSync(), 1]);
    expect(await FirmaActualizacion.comprobar(archivo, firma), isFalse);
    dir.deleteSync(recursive: true);
  });
}
