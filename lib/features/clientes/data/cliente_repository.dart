import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import 'cliente_model.dart';
import '../../../core/utils/texto_utils.dart';

class ClienteRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static final TablaSincronizada<ClienteModel> _tabla = TablaSincronizada<ClienteModel>(
    tabla: 'clientes',
    desdeFila: (f) => ClienteModel.fromMap(f['id'] as String, f),
    orden: (a, b) => a.nombreCompleto.compareTo(b.nombreCompleto),
  );

  Stream<List<ClienteModel>> obtenerClientes() => _tabla.observar();

  Exception _traducirDuplicado(PostgrestException e) {
    if (e.code == '23505') return Exception('Ya existe un cliente con ese DNI');
    return Exception(e.message);
  }

  Future<ClienteModel?> obtenerPorId(String id) {
    return conRed(() async {
      final filas = await _db.from('clientes').select().eq('id', id).limit(1);
      if (filas.isEmpty) return null;
      return ClienteModel.fromMap(filas.first['id'] as String, filas.first);
    });
  }

  // Devuelve el ClienteModel recién creado (con su id real ya asignado) -lo
  // necesita, por ejemplo, "Crear cliente nuevo" desde BuscarClienteDialog
  // (ver item 5 del pedido del dueño): tiene que poder vincular ese cliente
  // a la venta en curso apenas se guarda, con el mismo Navigator.pop(context,
  // cliente) que usa elegir uno ya existente.
  Future<ClienteModel> crear({
    required String dni,
    required String nombreCompleto,
    required String direccion,
    required String telefono,
    required bool estado,
  }) {
    return conRed(() async {
      if (dni.isNotEmpty && _tabla.actual.any((c) => c.dni == dni)) {
        throw Exception('Ya existe un cliente con ese DNI');
      }
      // 'nombre_normalizado' (mayúsculas/tildes/espacios colapsados) para que
      // VentaRepository pueda encontrar un cliente por nombre sin exigir
      // igualdad exacta de string.
      final Map<String, dynamic> fila;
      try {
        fila = await _db.from('clientes').insert({
          'dni': dni,
          'nombre_completo': nombreCompleto,
          'nombre_normalizado': normalizarNombreCliente(nombreCompleto),
          'direccion': direccion,
          'telefono': telefono,
          'estado': estado,
        }).select().single();
      } on PostgrestException catch (e) {
        throw _traducirDuplicado(e);
      }
      _tabla.aplicarLocal(fila);
      return ClienteModel.fromMap(fila['id'] as String, fila);
    });
  }

  Future<void> actualizar({
    required String id,
    required String dni,
    required String nombreCompleto,
    required String direccion,
    required String telefono,
    required bool estado,
  }) {
    return conRed(() async {
      if (dni.isNotEmpty && _tabla.actual.any((c) => c.id != id && c.dni == dni)) {
        throw Exception('Ya existe un cliente con ese DNI');
      }
      // A propósito NO se toca fecha_ultima_compra acá (ver comentario en
      // ClienteModel.toMap): ese campo lo escribe otro flujo (registrar venta).
      try {
        final fila = await _db.from('clientes').update({
          'dni': dni,
          'nombre_completo': nombreCompleto,
          'nombre_normalizado': normalizarNombreCliente(nombreCompleto),
          'direccion': direccion,
          'telefono': telefono,
          'estado': estado,
        }).eq('id', id).select().single();
        _tabla.aplicarLocal(fila);
      } on PostgrestException catch (e) {
        throw _traducirDuplicado(e);
      }
    });
  }

  Future<void> eliminar(String id) {
    return conRed(() async {
      await _db.from('clientes').delete().eq('id', id);
      _tabla.quitarLocal(id);
    });
  }
}
