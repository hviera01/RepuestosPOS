import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../version_app.dart';
import 'firma_actualizacion.dart';

class ActualizacionDisponible {
  final int version;
  final String urlDescarga;
  final String notas;

  ActualizacionDisponible({required this.version, required this.urlDescarga, required this.notas});
}

class ActualizacionService {
  static const _repo = 'hviera01/RepuestosPOS';

  static bool get aplica => !kIsWeb && (Platform.isWindows || Platform.isAndroid);

  static String get _extensionEsperada => Platform.isAndroid ? '.apk' : '.exe';

  static String get urlDescargaDirectaUltima {
    final nombre = Platform.isAndroid ? 'RepuestosPOS.apk' : 'RepuestosPOS.exe';
    return 'https://github.com/$_repo/releases/latest/download/$nombre';
  }

  static Future<void> abrirDescargaDirecta() async {
    final url = urlDescargaDirectaUltima;
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], mode: ProcessStartMode.detached);
      return;
    }
    if (Platform.isAndroid) {
      await SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
    }
  }

  static Future<int?> obtenerUltimaVersionPublicada() async {
    try {
      final respuesta = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (respuesta.statusCode != 200) return null;
      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final tag = (datos['tag_name'] as String? ?? '').replaceFirst('v', '');
      return int.tryParse(tag);
    } catch (_) {
      return null;
    }
  }

  static Future<ActualizacionDisponible?> buscarActualizacion() async {
    if (!aplica) return null;
    try {
      return await _buscarViaApi();
    } catch (errorApi) {
      try {
        return await _buscarViaRedireccion();
      } catch (errorRedireccion) {
        throw Exception('api.github.com: $errorApi · github.com: $errorRedireccion');
      }
    }
  }

  static Future<ActualizacionDisponible?> _buscarViaApi() async {
    final respuesta = await http
        .get(
          Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 12));
    if (respuesta.statusCode != 200) {
      throw Exception('GitHub respondió con error ${respuesta.statusCode} al buscar la última versión');
    }
    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final tag = (datos['tag_name'] as String? ?? '').replaceFirst('v', '');
    final version = int.tryParse(tag);
    if (version == null || version <= versionApp) return null;
    final assets = (datos['assets'] as List? ?? []).cast<Map<String, dynamic>>();
    Map<String, dynamic>? asset;
    for (final a in assets) {
      if ((a['name'] as String? ?? '').toLowerCase().endsWith(_extensionEsperada)) {
        asset = a;
        break;
      }
    }
    final url = asset?['browser_download_url'] as String?;
    if (url == null) return null;
    return ActualizacionDisponible(
      version: version,
      urlDescarga: url,
      notas: (datos['body'] as String? ?? '').trim(),
    );
  }

  static Future<ActualizacionDisponible?> _buscarViaRedireccion() async {
    final cliente = http.Client();
    try {
      final pedido = http.Request('GET', Uri.parse('https://github.com/$_repo/releases/latest'))..followRedirects = false;
      final respuesta = await cliente.send(pedido).timeout(const Duration(seconds: 12));
      final ubicacion = respuesta.headers['location'];
      if (ubicacion == null) {
        throw Exception('github.com no devolvió una redirección (HTTP ${respuesta.statusCode})');
      }
      final match = RegExp(r'/releases/tag/v(\d+)$').firstMatch(ubicacion);
      final version = match != null ? int.tryParse(match.group(1)!) : null;
      if (version == null) throw Exception('No se pudo leer la versión desde: $ubicacion');
      if (version <= versionApp) return null;

      final nombreAsset = Platform.isAndroid ? 'RepuestosPOS$version.apk' : 'RepuestosPOS$version.exe';
      final urlDescarga = 'https://github.com/$_repo/releases/download/v$version/$nombreAsset';
      final chequeoAsset = await cliente.head(Uri.parse(urlDescarga)).timeout(const Duration(seconds: 12));
      if (chequeoAsset.statusCode != 200 && chequeoAsset.statusCode != 302) {
        throw Exception('El asset esperado ($nombreAsset) no existe en la release v$version');
      }
      return ActualizacionDisponible(version: version, urlDescarga: urlDescarga, notas: '');
    } finally {
      cliente.close();
    }
  }

  static Future<void> descargarEInstalar(
    ActualizacionDisponible actualizacion,
    void Function(double progreso) onProgreso,
  ) async {
    final carpetaTemp = await getTemporaryDirectory();
    final nombreArchivo = Platform.isAndroid ? 'RepuestosPOSActualizacion_v${actualizacion.version}.apk' : 'RepuestosPOSActualizacion_v${actualizacion.version}.exe';
    final archivoDestino = File('${carpetaTemp.path}${Platform.pathSeparator}$nombreArchivo');

    final cliente = http.Client();
    try {
      final peticion = await cliente.send(http.Request('GET', Uri.parse(actualizacion.urlDescarga)));
      final total = peticion.contentLength ?? 0;
      var recibido = 0;
      final sink = archivoDestino.openWrite();
      await for (final trozo in peticion.stream) {
        sink.add(trozo);
        recibido += trozo.length;
        if (total > 0) onProgreso(recibido / total);
      }
      await sink.close();
    } finally {
      cliente.close();
    }

    try {
      await FirmaActualizacion.verificar(archivoDestino, '${actualizacion.urlDescarga}.firma');
    } catch (e) {
      if (archivoDestino.existsSync()) archivoDestino.deleteSync();
      rethrow;
    }

    if (Platform.isAndroid) {
      await OpenFile.open(archivoDestino.path);
      return;
    }

    await Process.start(
      archivoDestino.path,
      ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }
}
