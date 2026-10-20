import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/operaciones_service.dart';
import 'item_traslado_model.dart';
import 'traslado_model.dart';

class TrasladoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static const _columnasLista =
      'id, numero, id_sucursal_origen, nombre_sucursal_origen, id_sucursal_destino, nombre_sucursal_destino, fecha, estado, observaciones, usuario_crea, usuario_recibe, fecha_recepcion, total_items, solicitud_impresion_en_vivo, solicitud_impresion_es_copia';

  Future<List<TrasladoModel>> obtenerRecientes({int limite = 200}) {
    return conRed(() async {
      final filas = await _db.from('traslados').select(_columnasLista).order('fecha', ascending: false).limit(limite);
      return filas.map((f) => TrasladoModel.fromMap(f)).toList();
    });
  }

  Stream<List<TrasladoModel>> obtenerTraslados() {
    final controlador = StreamController<List<TrasladoModel>>();
    RealtimeChannel? canal;
    Timer? antirrebote;

    Future<void> cargar() async {
      try {
        final lista = await obtenerRecientes();
        if (!controlador.isClosed) controlador.add(lista);
      } catch (e) {
        if (!controlador.isClosed) controlador.addError(e);
      }
    }

    controlador.onListen = () {
      unawaited(cargar());
      canal = _db
          .channel('traslados_lista')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'traslados',
            callback: (_) {
              antirrebote?.cancel();
              antirrebote = Timer(const Duration(milliseconds: 300), cargar);
            },
          )
          .subscribe();
    };
    controlador.onCancel = () async {
      antirrebote?.cancel();
      final c = canal;
      if (c != null) await _db.removeChannel(c);
    };
    return controlador.stream;
  }

  Future<List<TrasladoModel>> obtenerPorRango(DateTime inicio, DateTime finInclusive, {String? estado, String? idSucursal}) {
    return conRed(() async {
      var consulta = _db
          .from('traslados')
          .select('$_columnasLista, traslado_items(id_producto, nombre_producto, cantidad, ubicacion, orden)')
          .gte('fecha', inicio.toUtc().toIso8601String())
          .lte('fecha', finInclusive.toUtc().toIso8601String());
      if (estado != null && estado.isNotEmpty) consulta = consulta.eq('estado', estado);
      if (idSucursal != null && idSucursal.isNotEmpty) {
        consulta = consulta.or('id_sucursal_origen.eq.$idSucursal,id_sucursal_destino.eq.$idSucursal');
      }
      final filas = await consulta.order('fecha', ascending: false).limit(2000);
      return filas.map(_desdeFilaConDetalle).toList();
    });
  }

  TrasladoModel _desdeFilaConDetalle(Map<String, dynamic> fila) {
    final items = ((fila['traslado_items'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => ((a['orden'] ?? 0) as num).compareTo((b['orden'] ?? 0) as num));
    return TrasladoModel.fromMap(fila, items.map(ItemTrasladoModel.fromMap).toList());
  }

  Future<TrasladoModel?> obtenerPorId(String id) {
    return conRed(() async {
      final fila = await _db
          .from('traslados')
          .select('$_columnasLista, traslado_items(id_producto, nombre_producto, cantidad, ubicacion, orden)')
          .eq('id', id)
          .maybeSingle();
      return fila == null ? null : _desdeFilaConDetalle(fila);
    });
  }

  Future<void> marcarSolicitudImpresionEnVivo(String id, bool valor, {bool? esCopia}) async {
    try {
      await _db.rpc('marcar_solicitud_impresion_traslado', params: {'p_id': id, 'p_valor': valor, 'p_es_copia': esCopia});
    } on PostgrestException {
      return;
    }
  }

  Stream<List<TrasladoModel>> obtenerTrasladosConSolicitudImpresionEnVivo() {
    return conRedStream(() => _db
        .from('traslados')
        .stream(primaryKey: ['id'])
        .eq('solicitud_impresion_en_vivo', true)
        .map((filas) => filas.map((f) => TrasladoModel.fromMap(f)).toList()));
  }

  Set<String> _candidatosNumero(String texto) {
    final limpio = texto.trim();
    final candidatos = <String>{limpio};
    final sinPrefijo = limpio.replaceFirst(RegExp(r'^tras-?', caseSensitive: false), '');
    if (RegExp(r'^\d+$').hasMatch(sinPrefijo)) {
      candidatos.add('TRAS-${sinPrefijo.padLeft(6, '0')}');
    }
    return candidatos;
  }

  Future<TrasladoModel?> obtenerPorNumero(String numero) {
    return conRed(() async {
      final fila = await _db
          .from('traslados')
          .select('$_columnasLista, traslado_items(id_producto, nombre_producto, cantidad, ubicacion, orden)')
          .inFilter('numero', _candidatosNumero(numero).toList())
          .limit(1)
          .maybeSingle();
      return fila == null ? null : _desdeFilaConDetalle(fila);
    });
  }

  Future<TrasladoModel> registrar({
    required String idSucursalOrigen,
    required String nombreSucursalOrigen,
    required String idSucursalDestino,
    required String nombreSucursalDestino,
    required String observaciones,
    required String usuarioCrea,
    required List<ItemTrasladoModel> detalle,
    String estadoInicial = 'Pendiente',
    String usuarioRecibe = '',
  }) async {
    if (idSucursalOrigen == idSucursalDestino) {
      throw Exception('La sucursal origen y destino no pueden ser la misma');
    }
    if (detalle.isEmpty) {
      throw Exception('Agregá al menos un producto');
    }
    final resultado = await OperacionesService.instancia.rpc('registrar_traslado', {
      'payload': {
        'idSucursalOrigen': idSucursalOrigen,
        'nombreSucursalOrigen': nombreSucursalOrigen,
        'idSucursalDestino': idSucursalDestino,
        'nombreSucursalDestino': nombreSucursalDestino,
        'observaciones': observaciones,
        'usuarioCrea': usuarioCrea,
        'estadoInicial': estadoInicial,
        'usuarioRecibe': usuarioRecibe,
        'items': detalle.map((i) => i.toPayload()).toList(),
      },
    }) as Map<String, dynamic>;
    final ahora = DateTime.now();
    return TrasladoModel(
      id: resultado['id'] as String,
      numero: resultado['numero'] as String,
      idSucursalOrigen: idSucursalOrigen,
      nombreSucursalOrigen: nombreSucursalOrigen,
      idSucursalDestino: idSucursalDestino,
      nombreSucursalDestino: nombreSucursalDestino,
      fecha: ahora,
      estado: estadoInicial,
      observaciones: observaciones,
      usuarioCrea: usuarioCrea,
      usuarioRecibe: estadoInicial == 'Entregado' ? usuarioRecibe : '',
      fechaRecepcion: estadoInicial == 'Entregado' ? ahora : null,
      detalle: detalle,
    );
  }

  Future<void> enviar(String id) async {
    await OperacionesService.instancia.rpc('enviar_traslado', {'p_id': id});
  }

  Future<void> recepcionar(String id, {required String usuarioRecibe}) async {
    await OperacionesService.instancia.rpc('recepcionar_traslado', {'p_id': id, 'p_usuario': usuarioRecibe});
  }

  Future<void> anular(String id, {required String usuario}) async {
    await OperacionesService.instancia.rpc('anular_traslado', {'p_id': id, 'p_usuario': usuario});
  }
}
