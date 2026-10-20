import 'package:shared_preferences/shared_preferences.dart';

const prefsRegistrarVentaVista = 'registrarVentaVista';

const registrarVentaVistaClasica = 'clasica';
const registrarVentaVistaDividida = 'dividida';
const registrarVentaVistaDynamics = 'dynamics';

Future<String> obtenerVistaGuardada() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(prefsRegistrarVentaVista) ??
      registrarVentaVistaClasica;
}

Future<void> guardarVista(String valor) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(prefsRegistrarVentaVista, valor);
}
