import 'package:shared_preferences/shared_preferences.dart';

class ImpresoraLocal {
  static SharedPreferences? _prefs;
  static final Map<String, Object> _memoria = {};

  static Future<void> iniciar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  static String _texto(String clave) {
    final p = _prefs;
    if (p != null) return p.getString('imp_$clave') ?? '';
    return (_memoria[clave] as String?) ?? '';
  }

  static void _guardarTexto(String clave, String valor) {
    _memoria[clave] = valor;
    _prefs?.setString('imp_$clave', valor);
  }

  static String get termicaUrl => _texto('termica_url');
  static String get termicaNombre => _texto('termica_nombre');
  static String get etiquetasUrl => _texto('etiquetas_url');
  static String get etiquetasNombre => _texto('etiquetas_nombre');
  static String get redIp => _texto('red_ip');
  static int get redPuerto => int.tryParse(_texto('red_puerto')) ?? 9100;
  static String get bluetoothId => _texto('bluetooth_id');
  static String get bluetoothNombre => _texto('bluetooth_nombre');
  static bool get usarDriverWindows => _texto('driver') == '1';

  static void termica(String url, String nombre) {
    _guardarTexto('termica_url', url);
    _guardarTexto('termica_nombre', nombre);
  }

  static void etiquetas(String url, String nombre) {
    _guardarTexto('etiquetas_url', url);
    _guardarTexto('etiquetas_nombre', nombre);
  }

  static void red(String ip, int puerto) {
    _guardarTexto('red_ip', ip);
    _guardarTexto('red_puerto', '$puerto');
  }

  static void bluetooth(String id, String nombre) {
    _guardarTexto('bluetooth_id', id);
    _guardarTexto('bluetooth_nombre', nombre);
  }

  static void driverWindows(bool valor) => _guardarTexto('driver', valor ? '1' : '0');
}
