import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/utils/device_id.dart';
import 'dispositivo_model.dart';

class DispositivoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  Future<void> reportar({required int versionApp, required String usuario}) async {
    try {
      final id = await obtenerIdDispositivo();
      await _db.from('dispositivos').upsert({
        'id': id,
        'plataforma': obtenerPlataforma(),
        'version_app': versionApp,
        'usuario': usuario,
        'ultima_conexion': DateTime.now().toIso8601String(),
      });
    } catch (_) {
    }
  }

  Stream<List<DispositivoModel>> obtenerDispositivos() {
    return conRedStream(() => _db
        .from('dispositivos')
        .stream(primaryKey: ['id'])
        .order('ultima_conexion', ascending: false)
        .map((filas) => filas.map((d) => DispositivoModel.fromMap(d['id'] as String, d)).toList()));
  }
}
