import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'almacen_local.dart';

typedef DesdeFila<T> = T Function(Map<String, dynamic> fila);

class TablaSincronizada<T> {
  final String tabla;
  final DesdeFila<T> desdeFila;
  final String columnas;
  final Duration intervaloRespaldo;
  final int Function(T a, T b)? orden;

  TablaSincronizada({
    required this.tabla,
    required this.desdeFila,
    this.columnas = '*',
    this.intervaloRespaldo = const Duration(seconds: 90),
    this.orden,
  });

  static const _tamanoPagina = 1000;

  final _db = Supabase.instance.client;
  final Map<String, Map<String, dynamic>> _filas = {};
  final Map<String, T> _modelos = {};
  final _controlador = StreamController<List<T>>.broadcast();
  Box<String>? _caja;
  Box<String>? _meta;
  RealtimeChannel? _canal;
  Timer? _temporizador;
  Timer? _antirrebote;
  Future<void>? _inicio;
  Future<void>? _sincronizando;
  bool _pendienteOtraVuelta = false;
  bool _cargadoLocal = false;
  bool _sincronizadoAlgunaVez = false;
  String _cursor = '';
  String _cursorEliminados = '';
  List<T>? _ultimaLista;
  Object? ultimoError;

  bool get sincronizadoAlgunaVez => _sincronizadoAlgunaVez;
  List<T> get actual => _ultimaLista ?? const [];

  Stream<List<T>> observar() {
    late StreamController<List<T>> salida;
    StreamSubscription<List<T>>? sub;
    salida = StreamController<List<T>>(
      onListen: () {
        unawaited(_asegurarInicio());
        final previa = _ultimaLista;
        if (previa != null) salida.add(previa);
        sub = _controlador.stream.listen(salida.add, onError: salida.addError);
      },
      onCancel: () => sub?.cancel(),
    );
    return salida.stream;
  }

  Future<void> _asegurarInicio() => _inicio ??= _iniciar();

  Future<void> _iniciar() async {
    _caja = await AlmacenLocal.abrir('t_$tabla');
    _meta = await AlmacenLocal.abrir('meta_sync');
    _cursor = _meta?.get('cursor_$tabla') ?? '';
    _cursorEliminados = _meta?.get('cursor_elim_$tabla') ?? '';
    final caja = _caja;
    if (caja != null && caja.isNotEmpty) {
      final textos = caja.values.toList();
      final decodificadas = textos.length > 1500
          ? await compute(_decodificarLote, textos)
          : _decodificarLote(textos);
      for (final f in decodificadas) {
        _poner(f);
      }
    }
    _cargadoLocal = true;
    _emitir();
    unawaited(sincronizar());
    _suscribirRealtime();
    _temporizador = Timer.periodic(intervaloRespaldo, (_) => sincronizar());
  }

  static List<Map<String, dynamic>> _decodificarLote(List<String> textos) {
    final salida = <Map<String, dynamic>>[];
    for (final t in textos) {
      try {
        salida.add(Map<String, dynamic>.from(jsonDecode(t) as Map));
      } catch (_) {}
    }
    return salida;
  }

  void _suscribirRealtime() {
    try {
      _canal = _db
          .channel('sync_$tabla')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tabla,
            callback: (_) => _programar(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'eliminados',
            callback: (_) => _programar(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('TablaSincronizada($tabla): realtime no disponible: $e');
    }
  }

  void _programar() {
    _antirrebote?.cancel();
    _antirrebote = Timer(const Duration(milliseconds: 250), () => sincronizar());
  }

  Future<void> sincronizar() {
    if (_sincronizando != null) {
      _pendienteOtraVuelta = true;
      return _sincronizando!;
    }
    final trabajo = _sincronizarInterno().whenComplete(() {
      _sincronizando = null;
      if (_pendienteOtraVuelta) {
        _pendienteOtraVuelta = false;
        unawaited(sincronizar());
      }
    });
    _sincronizando = trabajo;
    return trabajo;
  }

  Future<void> _sincronizarInterno() async {
    await _asegurarInicio();
    try {
      var offset = 0;
      var mayor = _cursor;
      while (true) {
        var consulta = _db.from(tabla).select(columnas);
        if (_cursor.isNotEmpty) consulta = consulta.gte('updated_at', _cursor);
        final pagina = await consulta
            .order('updated_at', ascending: true)
            .order('id', ascending: true)
            .range(offset, offset + _tamanoPagina - 1)
            .timeout(const Duration(seconds: 25));
        if (pagina.isEmpty) break;
        for (final f in pagina) {
          final fila = Map<String, dynamic>.from(f);
          _poner(fila);
          final u = fila['updated_at'] as String?;
          if (u != null && u.compareTo(mayor) > 0) mayor = u;
        }
        await _guardarFilas(pagina);
        if (_cursor.isEmpty || pagina.length == _tamanoPagina) _emitir();
        if (pagina.length < _tamanoPagina) break;
        offset += _tamanoPagina;
      }
      if (mayor != _cursor) {
        _cursor = mayor;
        await _meta?.put('cursor_$tabla', mayor);
      }
      await _sincronizarEliminados();
      _sincronizadoAlgunaVez = true;
      ultimoError = null;
      _emitir();
    } catch (e) {
      ultimoError = e;
      debugPrint('TablaSincronizada($tabla): $e');
      if (!_sincronizadoAlgunaVez && _cargadoLocal) _emitir();
    }
  }

  Future<void> _sincronizarEliminados() async {
    var consulta = _db.from('eliminados').select('id_fila, eliminado_en').eq('tabla', tabla);
    if (_cursorEliminados.isNotEmpty) consulta = consulta.gt('eliminado_en', _cursorEliminados);
    final filas = await consulta.order('eliminado_en', ascending: true).limit(5000).timeout(const Duration(seconds: 25));
    if (filas.isEmpty) return;
    var mayor = _cursorEliminados;
    final ids = <String>[];
    for (final f in filas) {
      final id = f['id_fila'] as String;
      _quitar(id);
      ids.add(id);
      final e = f['eliminado_en'] as String;
      if (e.compareTo(mayor) > 0) mayor = e;
    }
    await _caja?.deleteAll(ids);
    _cursorEliminados = mayor;
    await _meta?.put('cursor_elim_$tabla', mayor);
  }

  Future<void> _guardarFilas(List<Map<String, dynamic>> filas) async {
    final caja = _caja;
    if (caja == null) return;
    try {
      await caja.putAll({for (final f in filas) f['id'] as String: jsonEncode(f)});
    } catch (e) {
      debugPrint('TablaSincronizada($tabla): no se pudo guardar en disco: $e');
    }
  }

  void aplicarLocal(Map<String, dynamic> fila) {
    final id = fila['id'] as String;
    final previa = _filas[id] ?? const <String, dynamic>{};
    final unida = {...previa, ...fila};
    _poner(unida);
    unawaited(_guardarFilas([unida]));
    _emitir();
  }

  void quitarLocal(String id) {
    _quitar(id);
    final caja = _caja;
    if (caja != null) unawaited(caja.delete(id));
    _emitir();
  }

  Map<String, dynamic>? filaLocal(String id) => _filas[id];

  void _poner(Map<String, dynamic> fila) {
    final id = fila['id'] as String;
    _filas[id] = fila;
    try {
      _modelos[id] = desdeFila(fila);
    } catch (e) {
      debugPrint('TablaSincronizada($tabla): fila invalida $id: $e');
      _modelos.remove(id);
    }
  }

  void _quitar(String id) {
    _filas.remove(id);
    _modelos.remove(id);
  }

  void _emitir() {
    final lista = _modelos.values.toList();
    if (orden != null) lista.sort(orden);
    _ultimaLista = lista;
    if (!_controlador.isClosed) _controlador.add(lista);
  }

  Future<void> reiniciar() async {
    _cursor = '';
    _cursorEliminados = '';
    _filas.clear();
    _modelos.clear();
    await _caja?.clear();
    await _meta?.delete('cursor_$tabla');
    await _meta?.delete('cursor_elim_$tabla');
    _emitir();
    await sincronizar();
  }

  Future<void> cerrar() async {
    _temporizador?.cancel();
    _antirrebote?.cancel();
    final canal = _canal;
    if (canal != null) await _db.removeChannel(canal);
  }
}
