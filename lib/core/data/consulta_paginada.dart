import 'dart:async';
import 'package:postgrest/postgrest.dart';

typedef ConstructorConsulta = PostgrestTransformBuilder<PostgrestList> Function();

Future<List<Map<String, dynamic>>> traerTodo(
  ConstructorConsulta construir, {
  int tamanoPagina = 1000,
  int paralelo = 4,
  Duration tiempoLimite = const Duration(seconds: 40),
}) async {
  final resultado = <Map<String, dynamic>>[];
  var desde = 0;
  var terminado = false;
  while (!terminado) {
    final lote = <Future<List<Map<String, dynamic>>>>[];
    for (var i = 0; i < paralelo; i++) {
      final a = desde + i * tamanoPagina;
      lote.add(
        construir()
            .range(a, a + tamanoPagina - 1)
            .timeout(tiempoLimite)
            .then((filas) => List<Map<String, dynamic>>.from(filas)),
      );
    }
    final paginas = await Future.wait(lote);
    for (final pagina in paginas) {
      resultado.addAll(pagina);
      if (pagina.length < tamanoPagina) {
        terminado = true;
        break;
      }
    }
    desde += paralelo * tamanoPagina;
  }
  return resultado;
}

typedef ConstructorConsultaLote = PostgrestTransformBuilder<PostgrestList> Function(List<String> lote);

Future<List<Map<String, dynamic>>> traerPorLotes(
  List<String> ids,
  ConstructorConsultaLote construir, {
  int tamanoLote = 120,
}) async {
  if (ids.isEmpty) return const [];
  final lotes = <List<String>>[];
  for (var i = 0; i < ids.length; i += tamanoLote) {
    lotes.add(ids.sublist(i, i + tamanoLote > ids.length ? ids.length : i + tamanoLote));
  }
  final salida = <Map<String, dynamic>>[];
  for (var i = 0; i < lotes.length; i += 4) {
    final grupo = lotes.skip(i).take(4);
    final respuestas = await Future.wait(grupo.map((lote) => traerTodo(() => construir(lote))));
    for (final r in respuestas) {
      salida.addAll(r);
    }
  }
  return salida;
}
