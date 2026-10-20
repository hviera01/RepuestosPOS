import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/consulta_paginada.dart';
import 'reporte_venta_model.dart';
import 'reporte_compra_model.dart';

class ResumenInicioVentas {
  final double totalDia;
  final int cantidadDia;
  final double totalMes;
  final double totalSemana;
  final int cantidadSemana;
  final List<({DateTime dia, double total})> serie;

  const ResumenInicioVentas({
    required this.totalDia,
    required this.cantidadDia,
    required this.totalMes,
    required this.totalSemana,
    required this.cantidadSemana,
    required this.serie,
  });

  factory ResumenInicioVentas.fromMap(Map<String, dynamic> m) {
    return ResumenInicioVentas(
      totalDia: (m['totalDia'] as num).toDouble(),
      cantidadDia: (m['cantidadDia'] as num).toInt(),
      totalMes: (m['totalMes'] as num).toDouble(),
      totalSemana: (m['totalSemana'] as num).toDouble(),
      cantidadSemana: (m['cantidadSemana'] as num).toInt(),
      serie: [
        for (final p in (m['serie'] as List<dynamic>))
          (
            dia: DateTime.parse((p as Map)['dia'] as String),
            total: ((p)['total'] as num).toDouble(),
          ),
      ],
    );
  }
}

class ReporteRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static const _columnasVenta =
      'id, fecha_registro, tipo_documento, numero_documento, total_a_pagar, cantidad_productos, metodo_pago, usuario_registro, documento_cliente, nombre_cliente, id_cliente, impuesto, condicion, fecha_vencimiento, estado, pendiente_impresion, pagos_mixtos';

  static const _columnasCompra =
      'id, tipo_documento, numero_documento, no_factura, total_a_pagar, subtotal, fecha_registro, cantidad_productos, usuario_registro, documento_proveedor, id_proveedor, razon_social, condicion, metodo_pago, fecha_vencimiento, impuesto, descuento_total_monto, ajuste_manual, estado';

  Future<List<ReporteVentaModel>> obtenerReporteVentas(
    DateTime inicio,
    DateTime finInclusive,
  ) {
    return conRed(() async {
      final filas = await traerTodo(
        () => _db
            .from('ventas')
            .select(_columnasVenta)
            .gte('fecha_registro', inicio.toIso8601String())
            .lte('fecha_registro', finInclusive.toIso8601String())
            .order('fecha_registro', ascending: false)
            .order('id'),
      );
      return filas.map((d) => ReporteVentaModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Future<ResumenInicioVentas> obtenerResumenInicio() {
    return conRed(() async {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final resultado = await _db
          .rpc('resumen_ventas_inicio', params: {'p_hoy': hoy.toIso8601String()})
          .timeout(const Duration(seconds: 20));
      return ResumenInicioVentas.fromMap(Map<String, dynamic>.from(resultado as Map));
    });
  }

  Stream<ResumenInicioVentas> observarResumenInicio() {
    late StreamController<ResumenInicioVentas> controlador;
    StreamSubscription<void>? suscripcion;
    Timer? antirrebote;
    Timer? respaldo;

    Future<void> cargar() async {
      try {
        final r = await obtenerResumenInicio();
        if (!controlador.isClosed) controlador.add(r);
      } catch (e) {
        if (!controlador.isClosed) controlador.addError(e);
      }
    }

    controlador = StreamController<ResumenInicioVentas>(
      onListen: () {
        unawaited(cargar());
        suscripcion = observarCambiosEnTabla('ventas').listen((_) {
          antirrebote?.cancel();
          antirrebote = Timer(const Duration(milliseconds: 600), cargar);
        }, onError: (_) {});
        respaldo = Timer.periodic(const Duration(minutes: 3), (_) => cargar());
      },
      onCancel: () {
        antirrebote?.cancel();
        respaldo?.cancel();
        return suscripcion?.cancel();
      },
    );
    return controlador.stream;
  }

  /// Emite un evento (sin contenido útil, solo "avisa") cada vez que cambia
  /// algo en [tabla] vía Supabase Realtime. No trae ni mapea filas -a
  /// diferencia de [observarReporteVentas]-, solo sirve para que una
  /// pantalla de Reporte ya abierta se re-dispare sola (misma consulta,
  /// mismo rango de fecha ya elegido, sin resetear ningún filtro) cuando el
  /// dueño registra/anula algo en otra pestaña mientras el reporte sigue
  /// abierto en esta -pedido explícito: "entro a ver el reporte y la venta
  /// que acabo de hacer no aparece hasta que lo busco de nuevo a mano"-.
  ///
  /// Escucha directo los eventos de Postgres Changes (INSERT/UPDATE/DELETE)
  /// -a propósito, NO usa `.from(tabla).stream()`-: ese `.stream()` mantiene
  /// una copia completa de la tabla y la re-emite entera no solo cuando algo
  /// cambia sino también cada vez que el canal de Realtime se reconecta (un
  /// blip de red, la pestaña quedó en segundo plano, etc. -algo que puede
  /// pasar sin que el dueño toque nada-), y esa re-emisión de reconexión
  /// llega al código de arriba indistinguible de un cambio real, disparando
  /// una recarga espontánea del reporte. Con Postgres Changes puro, una
  /// reconexión no emite nada por sí sola -solo un INSERT/UPDATE/DELETE de
  /// verdad dispara [callback]-, así que ya no hace falta descartar "el
  /// primer evento" a mano en la pantalla.
  Stream<void> observarCambiosEnTabla(String tabla) {
    return conRedStream(() => _streamCambiosPostgres(tabla));
  }

  Stream<void> _streamCambiosPostgres(String tabla) {
    RealtimeChannel? canal;
    late final StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () {
        canal = _db.channel('reporte_cambios_$tabla')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tabla,
            callback: (payload) {
              if (!controller.isClosed) controller.add(null);
            },
          )
          ..subscribe((status, [error]) {
            if (controller.isClosed) return;
            if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              controller.addError(
                error ?? Exception('No se pudo suscribir a cambios de $tabla'),
              );
            }
          });
      },
      onCancel: () => canal?.unsubscribe(),
    );
    return controller.stream;
  }

  Future<List<ReporteCompraModel>> obtenerReporteCompras(
    DateTime inicio,
    DateTime finInclusive, {
    String? idProveedor,
  }) {
    return conRed(() async {
      final filas = await traerTodo(() {
        var consulta = _db
            .from('compras')
            .select(_columnasCompra)
            .gte('fecha_registro', inicio.toIso8601String())
            .lte('fecha_registro', finInclusive.toIso8601String());
        return consulta.order('fecha_registro', ascending: false).order('id');
      });
      var lista = filas.map((d) => ReporteCompraModel.fromMap(d['id'] as String, d)).toList();
      if (idProveedor != null && idProveedor.isNotEmpty) {
        lista = lista.where((c) => c.idProveedor == idProveedor).toList();
      }
      return lista;
    });
  }
}
