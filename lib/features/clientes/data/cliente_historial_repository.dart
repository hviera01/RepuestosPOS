import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/consulta_paginada.dart';
import '../../../core/data/base_repository.dart';
import 'cliente_model.dart';
import 'cliente_historial_model.dart';
import '../../ventas/data/venta_model.dart';
import '../../ventas/data/item_venta_model.dart';
import '../../ventas_credito/data/venta_credito_model.dart';
import '../../ventas_credito/data/venta_credito_repository.dart';

const _maxVentasRecientes = 10;
const _maxProductosTop = 3;

class ClienteHistorialRepository with ConRedMixin {
  final _db = Supabase.instance.client;
  final _ventaCreditoRepository = VentaCreditoRepository();

  Future<ClienteHistorialData> obtener(ClienteModel cliente) {
    return conRed(() async {
      final nombre = cliente.nombreCompleto.trim();
      final dni = cliente.dni.trim();

      final ventasPorIdFuture = traerTodo(
        () => _db.from('ventas').select().eq('id_cliente', cliente.id).order('id'),
      );
      final ventasPorNombreFuture = nombre.isEmpty
          ? null
          : traerTodo(() => _db.from('ventas').select().eq('nombre_cliente', nombre).order('id'));
      final creditosPorIdFuture = traerTodo(
        () => _db.from('ventas_credito').select().eq('id_cliente', cliente.id).order('id'),
      );
      final creditosPorDniFuture = dni.isEmpty || dni == 'N/A'
          ? null
          : traerTodo(() => _db.from('ventas_credito').select().eq('documento_cliente', dni).order('id'));

      final ventasPorIdFilas = await ventasPorIdFuture;
      final ventasPorNombreFilas = ventasPorNombreFuture == null
          ? null
          : await ventasPorNombreFuture;
      final creditosPorIdFilas = await creditosPorIdFuture;
      final creditosPorDniFilas = creditosPorDniFuture == null
          ? null
          : await creditosPorDniFuture;

      final ventasMap = <String, VentaModel>{};
      final emparejadaSoloPorNombre = <String, bool>{};
      for (final fila in ventasPorIdFilas) {
        final id = fila['id'] as String;
        ventasMap[id] = VentaModel.fromMap(id, fila, const []);
        emparejadaSoloPorNombre[id] = false;
      }
      var hayEmparejadasPorNombre = false;
      if (ventasPorNombreFilas != null) {
        for (final fila in ventasPorNombreFilas) {
          final id = fila['id'] as String;
          if (ventasMap.containsKey(id)) continue;
          ventasMap[id] = VentaModel.fromMap(id, fila, const []);
          emparejadaSoloPorNombre[id] = true;
          hayEmparejadasPorNombre = true;
        }
      }

      final ventasValidas =
          ventasMap.values
              .where(
                (v) => v.estado == 'Activa' && v.tipoDocumento != 'Cotizacion',
              )
              .toList()
            ..sort(
              (a, b) => (b.fechaRegistro ?? DateTime(2000)).compareTo(
                a.fechaRegistro ?? DateTime(2000),
              ),
            );

      final creditosMap = <String, VentaCreditoModel>{};
      for (final fila in creditosPorIdFilas) {
        final id = fila['id'] as String;
        creditosMap[id] = VentaCreditoModel.fromMap(id, fila);
      }
      if (creditosPorDniFilas != null) {
        for (final fila in creditosPorDniFilas) {
          final id = fila['id'] as String;
          creditosMap.putIfAbsent(
            id,
            () => VentaCreditoModel.fromMap(id, fila),
          );
        }
      }
      final creditos = creditosMap.values.toList()
        ..sort(
          (a, b) => (b.fechaRegistro ?? DateTime(2000)).compareTo(
            a.fechaRegistro ?? DateTime(2000),
          ),
        );

      final totalComprado = ventasValidas.fold<double>(
        0,
        (s, v) => s + v.totalAPagar,
      );
      final cantidadCompras = ventasValidas.length;
      final ticketPromedio = cantidadCompras == 0
          ? 0.0
          : totalComprado / cantidadCompras;
      final fechas = ventasValidas
          .map((v) => v.fechaRegistro)
          .whereType<DateTime>()
          .toList();
      final primeraCompra = fechas.isEmpty
          ? null
          : fechas.reduce((a, b) => a.isBefore(b) ? a : b);
      final ultimaCompra = fechas.isEmpty
          ? null
          : fechas.reduce((a, b) => a.isAfter(b) ? a : b);

      final ventasRecientes = ventasValidas
          .take(_maxVentasRecientes)
          .map(
            (v) => VentaResumenCliente(
              id: v.id,
              numeroDocumento: v.numeroDocumento,
              fecha: v.fechaRegistro,
              monto: v.totalAPagar,
              metodoPago: v.metodoPago,
              condicion: v.condicion,
              emparejadaPorNombre: emparejadaSoloPorNombre[v.id] ?? false,
            ),
          )
          .toList();

      final conteoMetodoPago = <String, int>{};
      for (final v in ventasValidas) {
        final metodo = v.metodoPago.isEmpty ? 'N/A' : v.metodoPago;
        conteoMetodoPago[metodo] = (conteoMetodoPago[metodo] ?? 0) + 1;
      }
      String? metodoPagoPreferido;
      var maxConteoMetodo = 0;
      conteoMetodoPago.forEach((metodo, conteo) {
        if (conteo > maxConteoMetodo) {
          maxConteoMetodo = conteo;
          metodoPagoPreferido = metodo;
        }
      });

      final idsVenta = ventasMap.keys.toList();
      final detalleFilas = idsVenta.isEmpty
          ? const <Map<String, dynamic>>[]
          : await traerPorLotes(
              idsVenta,
              (lote) => _db.from('venta_items').select().inFilter('id_venta', lote).order('id'),
            );

      final lineas = detalleFilas.map((d) {
        final item = ItemVentaModel.fromRow(d);
        final idVenta = d['id_venta'] as String?;
        final fecha = idVenta != null
            ? ventasMap[idVenta]?.fechaRegistro
            : null;
        return (item: item, fecha: fecha, idVenta: idVenta);
      }).toList();

      final cantidadPorProducto = <String, double>{};
      for (final l in lineas) {
        if (l.item.nombreProducto.isEmpty) continue;
        cantidadPorProducto[l.item.nombreProducto] =
            (cantidadPorProducto[l.item.nombreProducto] ?? 0) + l.item.cantidad;
      }
      final productosTop =
          cantidadPorProducto.entries
              .map(
                (e) => ProductoTopCliente(
                  nombreProducto: e.key,
                  cantidad: e.value,
                ),
              )
              .toList()
            ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

      int? abonosATiempo;
      int? abonosAtrasados;
      if (creditos.isNotEmpty) {
        final abonosPorCredito = await Future.wait(
          creditos.map(
            (c) => _ventaCreditoRepository.obtenerAbonosUnaVez(c.id),
          ),
        );
        var aTiempo = 0;
        var atrasados = 0;
        for (var i = 0; i < creditos.length; i++) {
          final vencimiento = creditos[i].fechaVencimiento;
          if (vencimiento == null) continue;
          for (final abono in abonosPorCredito[i]) {
            if (abono.fecha == null) continue;
            if (abono.fecha!.isAfter(vencimiento)) {
              atrasados++;
            } else {
              aTiempo++;
            }
          }
        }
        if (aTiempo + atrasados > 0) {
          abonosATiempo = aTiempo;
          abonosAtrasados = atrasados;
        }
      }

      return ClienteHistorialData(
        creditos: creditos,
        abonosATiempo: abonosATiempo,
        abonosAtrasados: abonosAtrasados,
        totalComprado: totalComprado,
        cantidadCompras: cantidadCompras,
        ticketPromedio: ticketPromedio,
        primeraCompra: primeraCompra,
        ultimaCompra: ultimaCompra,
        ventasRecientes: ventasRecientes,
        metodoPagoPreferido: metodoPagoPreferido,
        productosTop: productosTop.take(_maxProductosTop).toList(),
        hayVentasEmparejadasPorNombre: hayEmparejadasPorNombre,
      );
    });
  }
}
