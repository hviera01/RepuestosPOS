import '../../features/productos/data/producto_model.dart';

String invertirCodigoBarras(String codigo) => codigo.trim().split('').reversed.join();

List<String> variantesCodigoBarras(String codigo) {
  final variantes = <String>[];
  if (codigo.length == 13 && codigo.startsWith('0')) {
    variantes.add(codigo.substring(1));
  } else if (codigo.length == 12) {
    variantes.add('0$codigo');
  }
  final invertido = invertirCodigoBarras(codigo);
  if (invertido != codigo) variantes.add(invertido);
  return variantes;
}

final _caracteresInvisibles = RegExp(r'[\u0000-\u001F\u007F-\u009F​-‏ - ⁠﻿]');
final _prefijoSimbologia = RegExp(r'^\][A-Za-z][0-9A-Za-z]');

String limpiarCodigoEscaneado(String crudo) {
  var t = crudo.replaceAll(_caracteresInvisibles, '').trim();
  t = t.replaceFirst(_prefijoSimbologia, '');
  if (t.length > 2 && t.startsWith('*') && t.endsWith('*')) t = t.substring(1, t.length - 1);
  if (t.length > 2 && ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'")))) {
    t = t.substring(1, t.length - 1);
  }
  return t.trim();
}

String _alfanumerico(String t) => t.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool _soloDigitos(String t) => t.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(t);

String _sinCeros(String t) {
  final r = t.replaceFirst(RegExp(r'^0+'), '');
  return r.isEmpty ? '0' : r;
}

int _digitoVerificador(String cuerpo) {
  var suma = 0;
  for (var i = 0; i < cuerpo.length; i++) {
    final d = int.parse(cuerpo[cuerpo.length - 1 - i]);
    suma += i % 2 == 0 ? d * 3 : d;
  }
  return (10 - suma % 10) % 10;
}

Set<String> _variantesNumericas(String digitos) {
  final v = <String>{};
  final n = digitos.length;
  if (n == 13 || n == 12 || n == 8 || n == 14) v.add(digitos.substring(0, n - 1));
  if (n == 12 || n == 11 || n == 7 || n == 13) v.add('$digitos${_digitoVerificador(digitos)}');
  if (n == 14) {
    final cuerpo = digitos.substring(1, 13);
    v.add(cuerpo);
    v.add('$cuerpo${_digitoVerificador(cuerpo)}');
  }
  return v;
}

class _ClavesCodigo {
  final Set<String> exactas;
  final Set<String> alfanumericas;
  final Set<String> numericas;
  const _ClavesCodigo(this.exactas, this.alfanumericas, this.numericas);
}

_ClavesCodigo _clavesDeTexto(Iterable<String> textos) {
  final exactas = <String>{};
  final alfa = <String>{};
  final num = <String>{};
  for (final crudo in textos) {
    final t = limpiarCodigoEscaneado(crudo);
    if (t.isEmpty) continue;
    exactas.add(t.toUpperCase());
    final a = _alfanumerico(t);
    if (a.isNotEmpty) {
      alfa.add(a);
      if (_soloDigitos(a)) num.add(_sinCeros(a));
    }
  }
  return _ClavesCodigo(exactas, alfa, num);
}

final Expando<_ClavesCodigo> _cacheClavesProducto = Expando<_ClavesCodigo>('clavesCodigo');

_ClavesCodigo _clavesDeProducto(ProductoModel p) {
  return _cacheClavesProducto[p] ??= _clavesDeTexto([p.codigo, p.codigoBarras]);
}

_ClavesCodigo _clavesDeEscaneo(String crudo) {
  final limpio = limpiarCodigoEscaneado(crudo);
  final base = _clavesDeTexto([limpio]);
  final extra = <String>{};
  final alfa = _alfanumerico(limpio);
  if (_soloDigitos(alfa)) {
    extra.addAll(_variantesNumericas(alfa));
    extra.addAll(_variantesNumericas(_sinCeros(alfa).padLeft(13, '0')));
  }
  final invertido = invertirCodigoBarras(alfa);
  if (invertido.isNotEmpty && invertido != alfa) {
    extra.add(invertido);
    if (_soloDigitos(invertido)) extra.addAll(_variantesNumericas(invertido));
  }
  final variantes = _clavesDeTexto(extra);
  return _ClavesCodigo(
    base.exactas,
    {...base.alfanumericas, ...variantes.alfanumericas},
    {...base.numericas, ...variantes.numericas},
  );
}

int _nivelCoincidencia(_ClavesCodigo producto, _ClavesCodigo escaneo, _ClavesCodigo basico) {
  if (producto.exactas.any(basico.exactas.contains)) return 0;
  if (producto.alfanumericas.any(basico.alfanumericas.contains)) return 1;
  if (producto.numericas.any(basico.numericas.contains)) return 2;
  if (producto.alfanumericas.any(escaneo.alfanumericas.contains) || producto.numericas.any(escaneo.numericas.contains)) return 3;
  return -1;
}

List<ProductoModel> buscarProductosPorCodigoEscaneado(List<ProductoModel> productos, String crudo, {bool soloActivos = true}) {
  final limpio = limpiarCodigoEscaneado(crudo);
  if (limpio.isEmpty) return const [];
  final escaneo = _clavesDeEscaneo(limpio);
  final basico = _clavesDeTexto([limpio]);
  var mejor = 99;
  final coincidencias = <ProductoModel>[];
  for (final p in productos) {
    if (soloActivos && !p.estado) continue;
    final nivel = _nivelCoincidencia(_clavesDeProducto(p), escaneo, basico);
    if (nivel < 0 || nivel > mejor) continue;
    if (nivel < mejor) {
      mejor = nivel;
      coincidencias.clear();
    }
    coincidencias.add(p);
  }
  return coincidencias;
}

bool pareceCodigoDeBarras(String texto) {
  final t = limpiarCodigoEscaneado(texto);
  if (t.length < 6 || t.contains(' ')) return false;
  if (!RegExp(r'^[0-9A-Za-z\-./*\]]+$').hasMatch(t)) return false;
  final digitos = RegExp(r'[0-9]').allMatches(t).length;
  if (digitos == t.length) return true;
  return t.length >= 8 && digitos / t.length >= 0.75;
}

String? _ultimoCrudo;
_ClavesCodigo? _ultimoEscaneo;
_ClavesCodigo? _ultimoBasico;

bool coincideCodigoProducto(ProductoModel p, String crudo) {
  if (_ultimoCrudo != crudo) {
    _ultimoCrudo = crudo;
    final limpio = limpiarCodigoEscaneado(crudo);
    _ultimoEscaneo = _clavesDeEscaneo(limpio);
    _ultimoBasico = _clavesDeTexto([limpio]);
  }
  if (limpiarCodigoEscaneado(crudo).isEmpty) return false;
  return _nivelCoincidencia(_clavesDeProducto(p), _ultimoEscaneo!, _ultimoBasico!) >= 0;
}
