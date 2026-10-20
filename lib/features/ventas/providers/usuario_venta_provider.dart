import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/usuario_model.dart';

class UsuarioVentaOverrideNotifier extends Notifier<UsuarioModel?> {
  @override
  UsuarioModel? build() => null;

  void cambiar(UsuarioModel usuario) => state = usuario;

  void quitar() => state = null;
}

final usuarioVentaOverrideProvider = NotifierProvider<UsuarioVentaOverrideNotifier, UsuarioModel?>(UsuarioVentaOverrideNotifier.new);
