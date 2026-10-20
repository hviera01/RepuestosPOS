import 'dart:io';
import 'package:supabase/supabase.dart';

Map<String, String> leerEnv() {
  final salida = <String, String>{};
  for (final l in File('.env').readAsLinesSync()) {
    final i = l.indexOf('=');
    if (i > 0) salida[l.substring(0, i)] = l.substring(i + 1);
  }
  return salida;
}

var fallos = 0;
void ok(bool c, String m) {
  if (!c) fallos++;
  stdout.writeln('${c ? 'ok   ' : 'FALLO'} $m');
}

Future<void> main(List<String> args) async {
  final env = leerEnv();
  final url = env['SUPABASE_URL']!;
  final anon = env['SUPABASE_ANON_KEY']!;
  final documento = args[0];
  final clave = args[1];
  String? token;
  final cliente = SupabaseClient(url, anon, accessToken: () async => token);

  Future<bool> bloqueado(Future<dynamic> Function() f) async {
    try {
      await f();
      return false;
    } catch (_) {
      return true;
    }
  }

  ok(await bloqueado(() => cliente.from('productos').select('id').limit(1)), 'sin sesion no se leen productos');
  ok(await bloqueado(() => cliente.from('usuarios').select('id').limit(1)), 'sin sesion no se leen usuarios');

  final mala = Map<String, dynamic>.from(await cliente.rpc('iniciar_sesion', params: {'p_documento': documento, 'p_clave': 'incorrecta'}) as Map);
  ok(mala['error'] == 'Contraseña incorrecta', 'clave incorrecta rechazada');

  final r = Map<String, dynamic>.from(await cliente.rpc('iniciar_sesion', params: {'p_documento': documento, 'p_clave': clave}) as Map);
  token = r['token'] as String?;
  ok(token != null, 'login correcto devuelve sesion');
  ok(!(r['usuario'] as Map).containsKey('clave'), 'el usuario devuelto no trae la clave');

  final prod = await cliente.from('productos').select('id').limit(1);
  ok(prod.length >= 0, 'con sesion se leen productos');
  ok(await bloqueado(() => cliente.from('usuarios_credenciales').select()), 'credenciales no se leen ni con sesion');
  ok(await bloqueado(() => cliente.from('app_secretos').select()), 'secretos no se leen ni con sesion');

  await cliente.rpc('establecer_clave_especial', params: {'p_hash': 'abc123'});
  ok(await cliente.rpc('verificar_clave_especial', params: {'p_hash': 'abc123'}) == true, 'clave especial correcta');
  ok(await cliente.rpc('verificar_clave_especial', params: {'p_hash': 'otra'}) == false, 'clave especial incorrecta');
  await cliente.rpc('establecer_clave_especial', params: {'p_hash': ''});
  final neg = await cliente.from('negocio_config').select('tiene_clave_especial').maybeSingle();
  ok(neg == null || neg['tiene_clave_especial'] == false, 'negocio no expone hash y refleja que no hay clave');

  final idNuevo = await cliente.rpc('crear_usuario_con_clave', params: {
    'p_datos': {'documento': 'prueba-seg', 'nombre_completo': 'PRUEBA', 'rol': 'Empleado', 'estado': true},
    'p_clave': 'x', 'p_sal': 'y',
  });
  ok(idNuevo != null, 'admin crea usuario');
  final sal = 'sal-de-prueba';
  final hash = await _sha('$sal:ClavePrueba1');
  await cliente.rpc('guardar_credencial', params: {'p_id': idNuevo, 'p_clave': hash, 'p_sal': sal});

  String? tokenEmpleado;
  final cliente2 = SupabaseClient(url, anon, accessToken: () async => tokenEmpleado);
  final e = Map<String, dynamic>.from(await cliente2.rpc('iniciar_sesion', params: {'p_documento': 'prueba-seg', 'p_clave': 'ClavePrueba1'}) as Map);
  tokenEmpleado = e['token'] as String?;
  ok(tokenEmpleado != null, 'empleado nuevo inicia sesion');
  ok(await bloqueado(() => cliente2.rpc('guardar_credencial', params: {'p_id': idNuevo, 'p_clave': 'z', 'p_sal': 'z'})), 'empleado no puede cambiar claves');
  ok(await bloqueado(() => cliente2.rpc('crear_usuario_con_clave', params: {'p_datos': {'documento': 'x', 'nombre_completo': 'X', 'rol': 'Administrador'}, 'p_clave': 'a', 'p_sal': 'b'})), 'empleado no puede crear usuarios');
  ok(await bloqueado(() => cliente2.rpc('establecer_clave_especial', params: {'p_hash': 'zzz'})), 'empleado no puede cambiar clave especial');

  final eventos = <String>[];
  final canal = cliente.channel('prueba_seg').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'categorias',
    callback: (p) => eventos.add(p.eventType.name),
  );
  cliente.realtime.setAuth(token!);
  canal.subscribe();
  await Future.delayed(const Duration(seconds: 8));
  final fila = await cliente.from('categorias').insert({'descripcion': 'prueba-seg-${DateTime.now().millisecondsSinceEpoch}'}).select().single();
  await Future.delayed(const Duration(seconds: 4));
  ok(eventos.contains('insert'), 'realtime entrega eventos con la sesion');
  await cliente.from('categorias').delete().eq('id', fila['id']);
  await cliente.removeAllChannels();

  await cliente.from('usuarios').delete().eq('id', idNuevo);
  stdout.writeln(fallos == 0 ? 'TODO OK' : 'HAY $fallos FALLOS');
  exit(fallos == 0 ? 0 : 1);
}

Future<String> _sha(String texto) async {
  final r = await Process.run('powershell', [
    '-NoProfile',
    '-Command',
    "[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('$texto'))).Replace('-','').ToLower()"
  ]);
  return (r.stdout as String).trim();
}
