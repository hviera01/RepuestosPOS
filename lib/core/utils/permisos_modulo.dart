import '../constants/roles.dart';
import '../data/modulos_menu.dart';
import '../../features/auth/data/usuario_model.dart';

bool puedeVerSubModulo(UsuarioModel? usuario, SubModulo s) {
  final rol = usuario?.rol ?? Roles.empleado;
  if (rol == Roles.administrador) return true;
  if (rol == Roles.encargado) {
    return usuario?.pantallasPermitidas[s.moduleKey] == true;
  }
  if (rol == Roles.empleado) {
    final tieneConfiguracion = usuario?.pantallasPermitidas.isNotEmpty == true;
    if (tieneConfiguracion) {
      return usuario?.pantallasPermitidas[s.moduleKey] == true;
    }
    return pantallasPermitidasEmpleadoPorDefecto.contains(s.moduleKey);
  }
  return !s.soloAdmin;
}
