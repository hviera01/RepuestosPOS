import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/utils/clave_hash.dart';
import '../../../core/utils/reintentos.dart';
import '../../../core/constants/roles.dart';
import 'usuario_model.dart';

class UsuarioRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  Stream<List<UsuarioModel>> obtenerUsuarios() {
    return conRedStream(() => _db
        .from('usuarios')
        .stream(primaryKey: ['id'])
        .order('nombre_completo')
        .map((filas) => filas.map((d) => UsuarioModel.fromMap(d['id'] as String, d)).toList()));
  }

  Future<List<UsuarioModel>> obtenerUsuariosParaSeguridad() async {
    return conReintentos(() async {
      final filas = await _db.from('usuarios').select().order('nombre_completo').timeout(const Duration(seconds: 8));
      return filas.map((d) => UsuarioModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Future<void> crear(
    String documento,
    String nombreCompleto,
    String correo,
    String clave,
    String rol,
    bool estado, [
    Map<String, bool> pantallasPermitidas = const {},
    Map<String, bool> accionesPermitidas = const {},
  ]) {
    return conRed(() async {
      final sal = ClaveHash.generarSal();
      final aplicaPermisos = rol == Roles.encargado || rol == Roles.empleado;
      try {
        await _db.rpc('crear_usuario_con_clave', params: {
          'p_datos': {
            'documento': documento,
            'nombre_completo': nombreCompleto,
            'correo': correo,
            'rol': rol,
            'estado': estado,
            'pantallas_permitidas': aplicaPermisos ? pantallasPermitidas : {},
            'acciones_permitidas': aplicaPermisos ? accionesPermitidas : {},
          },
          'p_clave': ClaveHash.hash(clave, sal),
          'p_sal': sal,
        });
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }
    });
  }

  Future<void> actualizar(
    String id,
    String documento,
    String nombreCompleto,
    String correo,
    String rol,
    bool estado, [
    String? clave,
    Map<String, bool> pantallasPermitidas = const {},
    Map<String, bool> accionesPermitidas = const {},
  ]) {
    return conRed(() async {
      final existe = await _db.from('usuarios').select('id').eq('documento', documento).limit(2);
      final duplicado = existe.any((d) => d['id'] != id);
      if (duplicado) {
        throw Exception('El número de documento ya existe');
      }
      final aplicaPermisos = rol == Roles.encargado || rol == Roles.empleado;
      final data = <String, dynamic>{
        'documento': documento,
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'rol': rol,
        'estado': estado,
        'pantallas_permitidas': aplicaPermisos ? pantallasPermitidas : {},
        'acciones_permitidas': aplicaPermisos ? accionesPermitidas : {},
      };
      await _db.from('usuarios').update(data).eq('id', id);
      if (clave != null && clave.trim().isNotEmpty) {
        final sal = ClaveHash.generarSal();
        try {
          await _db.rpc('guardar_credencial', params: {'p_id': id, 'p_clave': ClaveHash.hash(clave, sal), 'p_sal': sal});
        } on PostgrestException catch (e) {
          throw Exception(e.message);
        }
      }
    });
  }

  Future<void> eliminar(String id) {
    return conRed(() async {
      final compras = await _db.from('compras').select('id').eq('usuario_registro', id).limit(1);
      if (compras.isNotEmpty) {
        throw Exception('No se puede eliminar porque el usuario se encuentra relacionado a una compra');
      }
      final ventas = await _db.from('ventas').select('id').eq('usuario_registro', id).limit(1);
      if (ventas.isNotEmpty) {
        throw Exception('No se puede eliminar porque el usuario se encuentra relacionado a una venta');
      }
      await _db.from('usuarios').delete().eq('id', id);
    });
  }
}
