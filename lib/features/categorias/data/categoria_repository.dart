import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import 'categoria_model.dart';

class CategoriaRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static final TablaSincronizada<CategoriaModel> _tabla = TablaSincronizada<CategoriaModel>(
    tabla: 'categorias',
    desdeFila: (f) => CategoriaModel.fromMap(f['id'] as String, f),
    orden: (a, b) => a.descripcion.compareTo(b.descripcion),
  );

  Stream<List<CategoriaModel>> obtenerCategorias() => _tabla.observar();

  Future<void> crear(String descripcion, bool estado, {bool controlaStock = true}) {
    return conRedExito('Categoría creada correctamente', () async {
      final existe = await _db.from('categorias').select('id').eq('descripcion', descripcion).limit(1);
      if (existe.isNotEmpty) {
        throw Exception('Ya existe una categoría con esa descripción');
      }
      final fila = await _db.from('categorias').insert({
        'descripcion': descripcion,
        'estado': estado,
        'controla_stock': controlaStock,
      }).select().single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> actualizar(String id, String descripcion, bool estado, {bool controlaStock = true}) {
    return conRedExito('Categoría actualizada correctamente', () async {
      final existe = await _db.from('categorias').select('id').eq('descripcion', descripcion).limit(2);
      final duplicado = existe.any((d) => d['id'] != id);
      if (duplicado) {
        throw Exception('Ya existe una categoría con esa descripción');
      }
      final fila = await _db.from('categorias').update({
        'descripcion': descripcion,
        'estado': estado,
        'controla_stock': controlaStock,
      }).eq('id', id).select().single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> eliminar(String id) {
    return conRedExito('Categoría eliminada correctamente', () async {
      final productos = await _db.from('productos').select('id').eq('id_categoria', id).limit(1);
      if (productos.isNotEmpty) {
        throw Exception('La categoría se encuentra relacionada a un producto');
      }
      await _db.from('categorias').delete().eq('id', id);
      _tabla.quitarLocal(id);
    });
  }
}
