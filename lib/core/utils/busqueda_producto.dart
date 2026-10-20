import '../../features/productos/data/producto_model.dart';
import 'texto_utils.dart';

String _soloAlfanumerico(String texto) => texto.replaceAll(RegExp(r'[^a-z0-9]'), '');

final Expando<String> _cacheTexto = Expando<String>('busquedaNorm');
final Expando<String> _cacheCodigo = Expando<String>('codigoCompacto');
final Expando<String> _cacheNombre = Expando<String>('nombreNorm');

String textoNormalizadoDe(ProductoModel p) => _cacheTexto[p] ??= normalizarTexto(p.textoBusqueda);

String codigoCompactoDe(ProductoModel p) =>
    _cacheCodigo[p] ??= _soloAlfanumerico(normalizarTexto('${p.codigo} ${p.codigoBarras}'));

String nombreNormalizadoDe(ProductoModel p) => _cacheNombre[p] ??= normalizarTexto(p.nombre);

List<String> tokensDeConsulta(String consulta) =>
    normalizarTexto(consulta).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

bool coincideProductoEstricto(ProductoModel p, String consulta) {
  final tokens = tokensDeConsulta(consulta);
  if (tokens.isEmpty) return true;
  final texto = textoNormalizadoDe(p);
  final codigoCompacto = codigoCompactoDe(p);
  return tokens.every((t) {
    if (texto.contains(t)) return true;
    final compacto = _soloAlfanumerico(t);
    return compacto.length >= 4 && codigoCompacto.contains(compacto);
  });
}

int _prioridadCodigo(ProductoModel p, String consultaCompacta) {
  if (consultaCompacta.isEmpty) return 2;
  final cod = _soloAlfanumerico(normalizarTexto(p.codigo));
  final barras = _soloAlfanumerico(normalizarTexto(p.codigoBarras));
  if (cod == consultaCompacta || barras == consultaCompacta) return 0;
  if (cod.startsWith(consultaCompacta) || barras.startsWith(consultaCompacta)) return 1;
  return 2;
}

List<ProductoModel> ordenarPorCodigoPrimero(List<ProductoModel> lista, String consulta) {
  final compacta = _soloAlfanumerico(normalizarTexto(consulta));
  if (compacta.length < 3) return lista;
  final prioridades = {for (final p in lista) p.id: _prioridadCodigo(p, compacta)};
  if (prioridades.values.every((v) => v == 2)) return lista;
  final indice = {for (var i = 0; i < lista.length; i++) lista[i].id: i};
  final copia = [...lista];
  copia.sort((a, b) {
    final c = prioridades[a.id]!.compareTo(prioridades[b.id]!);
    return c != 0 ? c : indice[a.id]!.compareTo(indice[b.id]!);
  });
  return copia;
}

class FiltroVehiculo {
  final String texto;
  final int? anio;
  const FiltroVehiculo({this.texto = '', this.anio});

  bool get activo => texto.trim().isNotEmpty || anio != null;
}

int? parsearAnio(String entrada) {
  final limpio = entrada.trim();
  if (!RegExp(r'^\d{2}$|^\d{4}$').hasMatch(limpio)) return null;
  final n = int.parse(limpio);
  if (limpio.length == 4) return n >= 1950 && n <= 2035 ? n : null;
  return n <= 35 ? 2000 + n : 1900 + n;
}

int? _anioDeToken(String t) {
  final n = int.tryParse(t);
  if (n == null) return null;
  if (t.length == 4) return n >= 1950 && n <= 2035 ? n : null;
  if (n <= 35) return 2000 + n;
  if (n >= 50) return 1900 + n;
  return null;
}

final _regexRango = RegExp(r'(?<![\w#/.(\-])(\d{2}|\d{4})\s*-\s*(\d{2}|\d{4}|UP|\+)?(?![\w/.])', caseSensitive: false);
final _regexSuelto = RegExp(r'(?<![\w#/.(\-])(\d{2}|\d{4})(?![\w/.\-)])');

class _RangoAnios {
  final int desde;
  final int hasta;
  const _RangoAnios(this.desde, this.hasta);
}

final Map<String, List<_RangoAnios>> _cacheRangos = {};

List<_RangoAnios> _rangosDeNombre(String nombre) {
  return _cacheRangos.putIfAbsent(nombre, () {
    final rangos = <_RangoAnios>[];
    var resto = nombre.toUpperCase();
    for (final m in _regexRango.allMatches(resto)) {
      final desde = _anioDeToken(m.group(1)!);
      if (desde == null) continue;
      final finTxt = m.group(2);
      final hasta = (finTxt == null || finTxt == 'UP' || finTxt == '+') ? 2035 : _anioDeToken(finTxt);
      if (hasta == null || hasta < desde) continue;
      rangos.add(_RangoAnios(desde, hasta));
    }
    resto = resto.replaceAll(_regexRango, ' ');
    for (final m in _regexSuelto.allMatches(resto)) {
      final a = _anioDeToken(m.group(1)!);
      if (a != null) rangos.add(_RangoAnios(a, a));
    }
    return rangos;
  });
}

enum CoincidenciaVehiculo { no, confirmada, sinDatoDeAnio }

CoincidenciaVehiculo coincideVehiculo(ProductoModel p, FiltroVehiculo filtro) {
  if (!filtro.activo) return CoincidenciaVehiculo.confirmada;
  final tokens = tokensDeConsulta(filtro.texto);
  final anio = filtro.anio;

  if (p.compatibilidad.isNotEmpty) {
    for (final c in p.compatibilidad) {
      final texto = normalizarTexto('${c.marca} ${c.modelo}');
      if (!tokens.every(texto.contains)) continue;
      if (anio == null || c.cubreAnio(anio)) return CoincidenciaVehiculo.confirmada;
    }
    final algunoSinAnio = p.compatibilidad.any((c) {
      final texto = normalizarTexto('${c.marca} ${c.modelo}');
      return tokens.every(texto.contains) && c.anioDesde == null && c.anioHasta == null;
    });
    return algunoSinAnio ? CoincidenciaVehiculo.sinDatoDeAnio : CoincidenciaVehiculo.no;
  }

  final nombre = nombreNormalizadoDe(p);
  for (final t in tokens) {
    if (!nombre.contains(t)) return CoincidenciaVehiculo.no;
  }
  if (anio == null) return CoincidenciaVehiculo.confirmada;
  final rangos = _rangosDeNombre(p.nombre);
  if (rangos.isEmpty) return CoincidenciaVehiculo.sinDatoDeAnio;
  return rangos.any((r) => anio >= r.desde && anio <= r.hasta) ? CoincidenciaVehiculo.confirmada : CoincidenciaVehiculo.no;
}

List<ProductoModel> filtrarPorVehiculo(List<ProductoModel> lista, FiltroVehiculo filtro) {
  if (!filtro.activo) return lista;
  final confirmados = <ProductoModel>[];
  final sinAnio = <ProductoModel>[];
  for (final p in lista) {
    switch (coincideVehiculo(p, filtro)) {
      case CoincidenciaVehiculo.confirmada:
        confirmados.add(p);
      case CoincidenciaVehiculo.sinDatoDeAnio:
        sinAnio.add(p);
      case CoincidenciaVehiculo.no:
        break;
    }
  }
  return [...confirmados, ...sinAnio];
}
