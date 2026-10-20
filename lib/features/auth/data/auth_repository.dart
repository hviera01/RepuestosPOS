import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/sesion_servidor.dart';
import '../../../core/utils/clave_hash.dart';
import 'usuario_model.dart';

class AuthRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  String hashClave(String clave) => ClaveHash.hashSinSal(clave);

  Future<UsuarioModel> login(String documento, String clave) {
    return conRed(() async {
      final r = await _db.rpc('iniciar_sesion', params: {'p_documento': documento, 'p_clave': clave});
      final datos = Map<String, dynamic>.from(r as Map);
      final error = datos['error'] as String?;
      if (error != null) throw Exception(error);
      final usuario = Map<String, dynamic>.from(datos['usuario'] as Map);
      SesionServidor.establecer(datos['token'] as String);
      return UsuarioModel.fromMap(usuario['id'] as String, usuario);
    });
  }
}
