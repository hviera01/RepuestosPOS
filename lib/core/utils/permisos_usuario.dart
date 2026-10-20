import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/roles.dart';
import '../../features/auth/providers/auth_provider.dart';

bool puedeRealizarAccion(WidgetRef ref, String accionKey) {
  final usuario = ref.read(authProvider).usuario;
  if (usuario == null) return false;
  if (usuario.rol == Roles.administrador) return true;
  if (usuario.rol == Roles.encargado) return usuario.accionesPermitidas[accionKey] == true;
  if (usuario.rol == Roles.empleado && usuario.accionesPermitidas.isNotEmpty) {
    return usuario.accionesPermitidas[accionKey] == true;
  }
  return true;
}
