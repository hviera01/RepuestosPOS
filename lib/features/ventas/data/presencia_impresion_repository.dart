import 'package:supabase_flutter/supabase_flutter.dart';

class PresenciaImpresionRepository {
  static const umbralConectada = Duration(seconds: 40);
  static const _id = 'pc_principal';

  final _db = Supabase.instance.client;

  Future<void> enviarLatido() async {
    try {
      await _db.from('presencia').upsert({'id': _id, 'ultimo_latido': DateTime.now().toIso8601String()});
    } catch (_) {
    }
  }

  Future<bool> estaConectada() async {
    try {
      final filas = await _db.from('presencia').select('ultimo_latido').eq('id', _id).limit(1);
      if (filas.isEmpty) return false;
      final texto = filas.first['ultimo_latido'] as String?;
      if (texto == null) return false;
      return DateTime.now().difference(DateTime.parse(texto)) < umbralConectada;
    } catch (_) {
      return false;
    }
  }
}
