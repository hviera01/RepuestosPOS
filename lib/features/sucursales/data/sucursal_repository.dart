import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import 'sucursal_model.dart';

class SucursalRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static final TablaSincronizada<SucursalModel> _tabla = TablaSincronizada<SucursalModel>(
    tabla: 'sucursales',
    desdeFila: SucursalModel.fromMap,
    orden: (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
  );

  Stream<List<SucursalModel>> obtenerSucursales() => _tabla.observar();

  Future<List<SucursalModel>> obtenerActivas() async {
    final lista = _tabla.actual;
    if (lista.isNotEmpty) return lista.where((s) => s.estado).toList();
    await _tabla.sincronizar();
    return _tabla.actual.where((s) => s.estado).toList();
  }

  Future<void> crear({required String nombre, required String direccion, required bool estado}) {
    if (nombre.trim().isEmpty) throw Exception('El nombre es obligatorio');
    return conRed(() async {
      final fila = await _db
          .from('sucursales')
          .insert({'nombre': nombre.trim(), 'direccion': direccion.trim(), 'estado': estado})
          .select()
          .single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> actualizar({required String id, required String nombre, required String direccion, required bool estado}) {
    if (nombre.trim().isEmpty) throw Exception('El nombre es obligatorio');
    return conRed(() async {
      final fila = await _db
          .from('sucursales')
          .update({'nombre': nombre.trim(), 'direccion': direccion.trim(), 'estado': estado})
          .eq('id', id)
          .select()
          .single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> eliminar(String id) {
    return conRed(() async {
      await _db.from('sucursales').delete().eq('id', id);
      _tabla.quitarLocal(id);
    });
  }
}
