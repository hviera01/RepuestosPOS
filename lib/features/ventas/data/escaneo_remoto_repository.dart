import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';

class EscaneoRemotoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static const _caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generarCodigo() {
    final azar = Random.secure();
    return List.generate(
      6,
      (_) => _caracteres[azar.nextInt(_caracteres.length)],
    ).join();
  }

  Future<void> crearSesion(String codigo) {
    return conRed(() => _db.from('escaneos_remotos').insert({'codigo': codigo}));
  }

  Future<bool> existeSesion(String codigo) {
    return conRed(() async {
      final filas = await _db.from('escaneos_remotos').select('codigo').eq('codigo', codigo).limit(1);
      return filas.isNotEmpty;
    });
  }

  Stream<bool> existeSesionEnVivo(String codigo) {
    return conRedStream(
      () => _db.from('escaneos_remotos').stream(primaryKey: ['codigo']).eq('codigo', codigo),
    ).map((filas) => filas.isNotEmpty);
  }

  Future<void> marcarConectado(String codigo) {
    return conRed(() => _db.from('escaneos_remotos').update({'conectado': true}).eq('codigo', codigo));
  }

  Stream<bool> escucharConectado(String codigo) {
    return conRedStream(
      () => _db.from('escaneos_remotos').stream(primaryKey: ['codigo']).eq('codigo', codigo),
    ).map((filas) => filas.isNotEmpty && (filas.first['conectado'] as bool? ?? false));
  }

  Future<void> enviarCodigo(String codigoSesion, String codigoEscaneado) {
    return conRed(
      () => _db.from('escaneo_remoto_eventos').insert({'codigo': codigoSesion, 'valor': codigoEscaneado}),
    );
  }

  Stream<List<Map<String, dynamic>>> escucharEventos(String codigoSesion) {
    return conRedStream(
      () => _db.from('escaneo_remoto_eventos').stream(primaryKey: ['id']).eq('codigo', codigoSesion).order('fecha'),
    );
  }

  Stream<String> escucharCodigosNuevos(String codigoSesion) {
    final vistos = <String>{};
    return escucharEventos(codigoSesion).expand(
      (filas) => [
        for (final fila in filas)
          if (vistos.add(fila['id'] as String)) fila['valor'] as String,
      ],
    );
  }

  Future<void> eliminarSesion(String codigo) {
    return conRed(() => _db.from('escaneos_remotos').delete().eq('codigo', codigo));
  }
}
