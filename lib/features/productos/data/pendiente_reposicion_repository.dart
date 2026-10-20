import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import 'pendiente_reposicion_model.dart';

class PendienteReposicionRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  Stream<List<PendienteReposicionModel>> obtenerPendientes() {
    return conRedStream(() => _db
        .from('pendientes_reposicion')
        .stream(primaryKey: ['id'])
        .eq('estado', 'Pendiente')
        .order('fecha_registro')
        .map((filas) => filas.map((d) => PendienteReposicionModel.fromMap(d['id'] as String, d)).toList()));
  }

  Future<void> cancelar(String id) {
    return conRed(() => _db.from('pendientes_reposicion').update({
          'estado': 'Cancelado',
          'fecha_completado': DateTime.now().toIso8601String(),
        }).eq('id', id));
  }
}
