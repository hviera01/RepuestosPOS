import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'almacen_local.dart';
import 'base_repository.dart';

class ResultadoOperacion {
  final dynamic datos;
  final bool encolada;
  const ResultadoOperacion(this.datos, {this.encolada = false});
}

class OperacionPendiente {
  final String opId;
  final String funcion;
  final Map<String, dynamic> args;
  final String descripcion;
  final DateTime creada;
  final String? error;

  const OperacionPendiente({
    required this.opId,
    required this.funcion,
    required this.args,
    required this.descripcion,
    required this.creada,
    this.error,
  });

  Map<String, dynamic> toMap() => {
        'opId': opId,
        'funcion': funcion,
        'args': args,
        'descripcion': descripcion,
        'creada': creada.toIso8601String(),
        if (error != null) 'error': error,
      };

  factory OperacionPendiente.fromMap(Map<String, dynamic> m) => OperacionPendiente(
        opId: m['opId'] as String,
        funcion: m['funcion'] as String,
        args: Map<String, dynamic>.from(m['args'] as Map),
        descripcion: (m['descripcion'] ?? '') as String,
        creada: DateTime.parse(m['creada'] as String),
        error: m['error'] as String?,
      );
}

class OperacionesService {
  OperacionesService._();
  static final OperacionesService instancia = OperacionesService._();

  static const _uuid = Uuid();
  static const _esperas = [Duration(milliseconds: 400), Duration(milliseconds: 1500), Duration(seconds: 4)];

  final ValueNotifier<int> pendientes = ValueNotifier(0);
  final ValueNotifier<int> fallidas = ValueNotifier(0);
  Box<String>? _cola;
  Box<String>? _rechazadas;
  Timer? _reloj;
  bool _procesando = false;

  Future<void> iniciar() async {
    _cola = await AlmacenLocal.abrir('cola_operaciones');
    _rechazadas = await AlmacenLocal.abrir('cola_rechazadas');
    pendientes.value = _cola?.length ?? 0;
    fallidas.value = _rechazadas?.length ?? 0;
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 20), (_) => procesarCola());
    unawaited(procesarCola());
  }

  Future<dynamic> rpc(String funcion, Map<String, dynamic> args) async => (await ejecutar(funcion, args)).datos;

  Future<ResultadoOperacion> ejecutar(
    String funcion,
    Map<String, dynamic> args, {
    bool encolable = false,
    String descripcion = '',
  }) async {
    final opId = _uuid.v4();
    Object? ultimoError;
    for (var intento = 0; intento <= _esperas.length; intento++) {
      try {
        final datos = await _llamar(opId, funcion, args);
        return ResultadoOperacion(datos);
      } catch (e) {
        if (!esErrorDeRed(e)) {
          if (e is PostgrestException) throw Exception(e.message);
          rethrow;
        }
        ultimoError = e;
        if (intento < _esperas.length) await Future.delayed(_esperas[intento]);
      }
    }
    if (encolable && _cola != null) {
      await _guardarEnCola(OperacionPendiente(
        opId: opId,
        funcion: funcion,
        args: args,
        descripcion: descripcion,
        creada: DateTime.now(),
      ));
      return const ResultadoOperacion(null, encolada: true);
    }
    throw traducirError(ultimoError ?? const SinConexionException());
  }

  Future<dynamic> _llamar(String opId, String funcion, Map<String, dynamic> args) {
    return Supabase.instance.client
        .rpc('ejecutar_idempotente', params: {'p_op_id': opId, 'p_funcion': funcion, 'p_args': args})
        .timeout(const Duration(seconds: 25));
  }

  Future<void> _guardarEnCola(OperacionPendiente op) async {
    await _cola?.put(op.opId, jsonEncode(op.toMap()));
    pendientes.value = _cola?.length ?? 0;
  }

  List<OperacionPendiente> listarRechazadas() {
    final caja = _rechazadas;
    if (caja == null) return const [];
    return caja.values.map((t) => OperacionPendiente.fromMap(jsonDecode(t) as Map<String, dynamic>)).toList();
  }

  Future<void> descartarRechazada(String opId) async {
    await _rechazadas?.delete(opId);
    fallidas.value = _rechazadas?.length ?? 0;
  }

  Future<void> reintentarRechazada(String opId) async {
    final texto = _rechazadas?.get(opId);
    if (texto == null) return;
    final op = OperacionPendiente.fromMap(jsonDecode(texto) as Map<String, dynamic>);
    await _rechazadas?.delete(opId);
    fallidas.value = _rechazadas?.length ?? 0;
    await _guardarEnCola(OperacionPendiente(
      opId: op.opId,
      funcion: op.funcion,
      args: op.args,
      descripcion: op.descripcion,
      creada: op.creada,
    ));
    unawaited(procesarCola());
  }

  Future<void> procesarCola() async {
    final cola = _cola;
    if (cola == null || _procesando || cola.isEmpty) return;
    _procesando = true;
    try {
      final operaciones = cola.values
          .map((t) => OperacionPendiente.fromMap(jsonDecode(t) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.creada.compareTo(b.creada));
      for (final op in operaciones) {
        try {
          await _llamar(op.opId, op.funcion, op.args);
          await cola.delete(op.opId);
        } catch (e) {
          if (esErrorDeRed(e)) break;
          await cola.delete(op.opId);
          final rechazada = OperacionPendiente(
            opId: op.opId,
            funcion: op.funcion,
            args: op.args,
            descripcion: op.descripcion,
            creada: op.creada,
            error: e.toString(),
          );
          await _rechazadas?.put(op.opId, jsonEncode(rechazada.toMap()));
        }
        pendientes.value = cola.length;
        fallidas.value = _rechazadas?.length ?? 0;
      }
    } finally {
      _procesando = false;
      pendientes.value = cola.length;
    }
  }
}
