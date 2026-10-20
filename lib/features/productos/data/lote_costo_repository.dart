import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import 'lote_costo_model.dart';

class LoteCostoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  Stream<List<LoteCostoModel>> obtenerLotes(String idProducto) {
    return conRedStream(() => _db
        .from('producto_lotes_costo')
        .stream(primaryKey: ['id'])
        .eq('id_producto', idProducto)
        .order('fecha')
        .map((filas) {
      final lotes = filas.map((d) => LoteCostoModel.fromMap(d['id'] as String, d)).toList();
      lotes.sort(_compararLotesPorPrioridad);
      return lotes;
    }));
  }

  Future<void> reordenarLotes(String idProducto, List<String> idsEnOrdenDeseado) {
    return conRed(() => _db.rpc('reordenar_lotes', params: {
          'p_id_producto': idProducto,
          'p_ids_orden': idsEnOrdenDeseado,
        }));
  }
}

LoteCostoModel? loteActivo(List<LoteCostoModel> lotes) {
  final ordenados = [...lotes]..sort(_compararLotesPorPrioridad);
  for (final lote in ordenados) {
    if (lote.cantidadRestante > 0) return lote;
  }
  return null;
}

int _compararLotesPorPrioridad(LoteCostoModel a, LoteCostoModel b) {
  if (a.prioridad != null && b.prioridad != null) return a.prioridad!.compareTo(b.prioridad!);
  if (a.prioridad != null) return -1;
  if (b.prioridad != null) return 1;
  return a.fecha.compareTo(b.fecha);
}
