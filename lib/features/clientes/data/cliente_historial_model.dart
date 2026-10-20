import '../../ventas_credito/data/venta_credito_model.dart';

class VentaResumenCliente {
  final String id;
  final String numeroDocumento;
  final DateTime? fecha;
  final double monto;
  final String metodoPago;
  final String condicion;
  final bool emparejadaPorNombre;

  VentaResumenCliente({
    required this.id,
    required this.numeroDocumento,
    required this.fecha,
    required this.monto,
    required this.metodoPago,
    required this.condicion,
    required this.emparejadaPorNombre,
  });
}

class ProductoTopCliente {
  final String nombreProducto;
  final double cantidad;

  ProductoTopCliente({required this.nombreProducto, required this.cantidad});
}

class ClienteHistorialData {
  final List<VentaCreditoModel> creditos;
  final int? abonosATiempo;
  final int? abonosAtrasados;

  final double totalComprado;
  final int cantidadCompras;
  final double ticketPromedio;
  final DateTime? primeraCompra;
  final DateTime? ultimaCompra;
  final List<VentaResumenCliente> ventasRecientes;
  final String? metodoPagoPreferido;

  final List<ProductoTopCliente> productosTop;


  final bool hayVentasEmparejadasPorNombre;

  ClienteHistorialData({
    required this.creditos,
    required this.abonosATiempo,
    required this.abonosAtrasados,
    required this.totalComprado,
    required this.cantidadCompras,
    required this.ticketPromedio,
    required this.primeraCompra,
    required this.ultimaCompra,
    required this.ventasRecientes,
    required this.metodoPagoPreferido,
    required this.productosTop,
    required this.hayVentasEmparejadasPorNombre,
  });

  bool get hayCreditoVencido => creditos.any((c) => c.vencida);

  double get saldoVencidoTotal => creditos.where((c) => c.vencida).fold<double>(0, (s, c) => s + c.saldoPendiente);

  double get saldoPendienteTotal => creditos.where((c) => !c.liquidada).fold<double>(0, (s, c) => s + c.saldoPendiente);
}
