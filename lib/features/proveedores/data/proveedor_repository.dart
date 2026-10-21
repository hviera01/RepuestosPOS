import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import 'proveedor_model.dart';

class ProveedorRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static final TablaSincronizada<ProveedorModel> _tabla = TablaSincronizada<ProveedorModel>(
    tabla: 'proveedores',
    desdeFila: (f) => ProveedorModel.fromMap(f['id'] as String, f),
    orden: (a, b) => a.razonSocial.compareTo(b.razonSocial),
  );

  Stream<List<ProveedorModel>> obtenerProveedores() => _tabla.observar();

  Future<void> crear({
    required String rtn,
    required String razonSocial,
    required String correo,
    required String telefono,
    required bool estado,
  }) {
    return conRedExito('Proveedor creado correctamente', () async {
      if (rtn.isNotEmpty && _tabla.actual.any((p) => p.rtn == rtn)) {
        throw Exception('Ya existe un proveedor con ese RTN');
      }
      final fila = await _db.from('proveedores').insert({
        'rtn': rtn,
        'razon_social': razonSocial,
        'correo': correo,
        'telefono': telefono,
        'estado': estado,
      }).select().single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> actualizar({
    required String id,
    required String rtn,
    required String razonSocial,
    required String correo,
    required String telefono,
    required bool estado,
  }) {
    return conRedExito('Proveedor actualizado correctamente', () async {
      if (rtn.isNotEmpty && _tabla.actual.any((p) => p.id != id && p.rtn == rtn)) {
        throw Exception('Ya existe un proveedor con ese RTN');
      }
      final fila = await _db.from('proveedores').update({
        'rtn': rtn,
        'razon_social': razonSocial,
        'correo': correo,
        'telefono': telefono,
        'estado': estado,
      }).eq('id', id).select().single();
      _tabla.aplicarLocal(fila);
    });
  }

  Future<void> eliminar(String id) {
    return conRedExito('Proveedor eliminado correctamente', () async {
      await _db.from('proveedores').delete().eq('id', id);
      _tabla.quitarLocal(id);
    });
  }
}
