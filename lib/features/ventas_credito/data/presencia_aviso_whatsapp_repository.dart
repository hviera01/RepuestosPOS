import 'package:supabase_flutter/supabase_flutter.dart';

class PresenciaAvisoWhatsappRepository {
  static const umbralConectada = Duration(minutes: 4);
  static const _id = 'aviso_whatsapp_escuchador';

  final _db = Supabase.instance.client;

  Future<bool> estaConectado() async {
    try {
      final filas = await _db
          .from('presencia')
          .select('ultimo_latido')
          .eq('id', _id)
          .limit(1);
      if (filas.isEmpty) return false;
      final texto = filas.first['ultimo_latido'] as String?;
      if (texto == null) return false;
      return DateTime.now().difference(DateTime.parse(texto)) < umbralConectada;
    } catch (_) {
      return false;
    }
  }
}
