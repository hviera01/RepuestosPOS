import 'package:supabase_flutter/supabase_flutter.dart';

class PresenciaImpresionRepository {
  static const umbralConectada = Duration(seconds: 40);
  static const _id = 'pc_principal';

  final _db = Supabase.instance.client;

  Future<void> enviarLatido() async {
    try {
      await _db.from('presencia').upsert({'id': _id, 'ultimo_latido': DateTime.now().toUtc().toIso8601String()});
    } catch (_) {
    }
  }

  static bool latidoReciente(DateTime latido, DateTime ahora) {
    final comoInstante = ahora.difference(latido).abs();
    if (comoInstante < umbralConectada) return true;
    final utc = latido.toUtc();
    final comoHoraLocal = DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second, utc.millisecond);
    return ahora.difference(comoHoraLocal).abs() < umbralConectada;
  }

  Future<bool> estaConectada() async {
    try {
      final filas = await _db.from('presencia').select('ultimo_latido').eq('id', _id).limit(1);
      if (filas.isEmpty) return false;
      final texto = filas.first['ultimo_latido'] as String?;
      if (texto == null) return false;
      return latidoReciente(DateTime.parse(texto), DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
