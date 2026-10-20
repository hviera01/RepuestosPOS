import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import 'caja_model.dart';

class CajaRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  Future<CajaModel?> cajaAbiertaDe(String usuario) {
    return conRed(() async {
      final r = await _db.rpc('caja_abierta_de', params: {'p_usuario': usuario});
      if (r == null) return null;
      return CajaModel.fromMap(Map<String, dynamic>.from(r as Map));
    });
  }

  Future<DateTime?> ultimoCierreDe(String usuario) {
    return conRed(() async {
      final r = await _db.rpc('ultimo_cierre_de', params: {'p_usuario': usuario});
      return r == null ? null : DateTime.parse(r as String);
    });
  }

  Future<CajaModel> abrir({
    required String usuario,
    required double monto,
    required String notas,
    required DateTime abiertaEn,
  }) {
    return conRed(() async {
      final r = await _db.rpc('abrir_caja', params: {
        'p_usuario': usuario,
        'p_monto': monto,
        'p_notas': notas,
        'p_abierta_en': abiertaEn.toIso8601String(),
      });
      return CajaModel.fromMap(Map<String, dynamic>.from(r as Map));
    });
  }

  Future<CajaModel> cerrar({
    required String id,
    required double montoContado,
    required String notas,
    required String usuario,
  }) {
    return conRed(() async {
      final r = await _db.rpc('cerrar_caja', params: {
        'p_id': id,
        'p_monto_contado': montoContado,
        'p_notas': notas,
        'p_usuario_cierre': usuario,
        'p_cerrada_en': DateTime.now().toIso8601String(),
      });
      return CajaModel.fromMap(Map<String, dynamic>.from(r as Map));
    });
  }

  Future<CajaModel> reabrir(String id) {
    return conRed(() async {
      final r = await _db.rpc('reabrir_caja', params: {'p_id': id});
      return CajaModel.fromMap(Map<String, dynamic>.from(r as Map));
    });
  }

  Future<CajaModel> resumen(String id) {
    return conRed(() async {
      final r = await _db.rpc('resumen_caja', params: {'p_id': id});
      return CajaModel.fromMap(Map<String, dynamic>.from(r as Map));
    });
  }

  Future<List<CajaModel>> historial({
    required DateTime desde,
    required DateTime hasta,
    String? usuario,
  }) {
    return conRed(() async {
      final r = await _db.rpc('historial_cajas', params: {
        'p_desde': desde.toIso8601String(),
        'p_hasta': hasta.toIso8601String(),
        'p_usuario': usuario,
      });
      return (r as List).map((e) => CajaModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<double> efectivoEstimado() {
    return conRed(() async {
      final r = await _db.rpc('efectivo_estimado_cajas');
      return (r as num?)?.toDouble() ?? 0;
    });
  }
}
