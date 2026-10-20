class RankingProducto {
  final String idProducto;
  final String nombreProducto;
  final double cantidad;
  final double monto;

  RankingProducto({required this.idProducto, required this.nombreProducto, required this.cantidad, required this.monto});
}

class ProductoSinVenta {
  final String idProducto;
  final String nombreProducto;
  final double stock;
  final double valorInventario;

  ProductoSinVenta({required this.idProducto, required this.nombreProducto, required this.stock, required this.valorInventario});
}

class VentasPorUsuario {
  final String usuario;
  final double totalVentas;
  final int cantidadTransacciones;

  VentasPorUsuario({required this.usuario, required this.totalVentas, required this.cantidadTransacciones});
}

class GananciaPorVenta {
  final String idVenta;
  final String numeroDocumento;
  final DateTime? fecha;
  final String cliente;
  final double ventas;
  final double costo;

  GananciaPorVenta({required this.idVenta, required this.numeroDocumento, required this.fecha, required this.cliente, required this.ventas, required this.costo});

  double get ganancia => ventas - costo;
  double get margenPorcentaje => ventas <= 0 ? 0 : (ganancia / ventas) * 100;
}

class AbonoPorProveedor {
  final String proveedor;
  final double total;

  AbonoPorProveedor({required this.proveedor, required this.total});
}

class PuntoMensual {
  final DateTime mes;
  final double totalVentas;
  final double totalCompras;

  PuntoMensual({required this.mes, required this.totalVentas, required this.totalCompras});
}

class FlujoEfectivo {
  final double ingresosEfectivo;
  final double ingresosTarjeta;
  final double ingresosTransferencia;
  final double egresosEfectivo;
  final double egresosTransferencia;

  FlujoEfectivo({
    required this.ingresosEfectivo,
    required this.ingresosTarjeta,
    required this.ingresosTransferencia,
    required this.egresosEfectivo,
    required this.egresosTransferencia,
  });

  double get totalIngresos => ingresosEfectivo + ingresosTarjeta + ingresosTransferencia;
  double get totalEgresos => egresosEfectivo + egresosTransferencia;
  double get neto => totalIngresos - totalEgresos;
}

class RecomendacionPago {
  final double efectivoEstimado;
  final double reservaGastosFijos;
  final double sugeridoPorCaja;
  final double ingresoEfectivoCobrado;
  final double sugeridoPorVentas;

  RecomendacionPago({
    required this.efectivoEstimado,
    required this.reservaGastosFijos,
    required this.sugeridoPorCaja,
    required this.ingresoEfectivoCobrado,
    required this.sugeridoPorVentas,
  });
}

class BalanceGeneral {
  final double inventarioACosto;
  final double cuentasPorCobrar;
  final double efectivoEstimado;
  final double cuentasPorPagar;

  BalanceGeneral({
    required this.inventarioACosto,
    required this.cuentasPorCobrar,
    required this.efectivoEstimado,
    required this.cuentasPorPagar,
  });

  double get totalActivos => inventarioACosto + cuentasPorCobrar + efectivoEstimado;
  double get totalPasivos => cuentasPorPagar;
  double get patrimonio => totalActivos - totalPasivos;
}

class PronosticoVentas {
  final double montoEstimado;
  final double promedioUltimosMeses;
  final double tendenciaMensual;
  final String metodo;

  PronosticoVentas({
    required this.montoEstimado,
    required this.promedioUltimosMeses,
    required this.tendenciaMensual,
    required this.metodo,
  });

  bool get tendenciaAlAlza => tendenciaMensual > 0;
}

class SugerenciaCompra {
  final String idProducto;
  final String nombreProducto;
  final double stockActual;
  final double ventaDiariaPromedio;
  final double diasParaAgotarse;
  final String? proveedor;
  final double deudaVencidaProveedor;
  final bool proveedorAlDia;

  SugerenciaCompra({
    required this.idProducto,
    required this.nombreProducto,
    required this.stockActual,
    required this.ventaDiariaPromedio,
    required this.diasParaAgotarse,
    required this.proveedor,
    required this.deudaVencidaProveedor,
    required this.proveedorAlDia,
  });
}

class ClienteTop {
  final String cliente;
  final double totalComprado;
  final int cantidadCompras;

  ClienteTop({required this.cliente, required this.totalComprado, required this.cantidadCompras});

  double get ticketPromedio => cantidadCompras <= 0 ? 0 : totalComprado / cantidadCompras;
}

class VentaSinCliente {
  final String nombre;
  final int cantidadVentas;
  final double totalComprado;

  VentaSinCliente({required this.nombre, required this.cantidadVentas, required this.totalComprado});
}

class ClienteInactivo {
  final String nombreCompleto;
  final DateTime? ultimaCompra;
  final int? diasSinComprar;

  ClienteInactivo({required this.nombreCompleto, required this.ultimaCompra, required this.diasSinComprar});
}

class InteligenciaNegocioData {
  final PronosticoVentas pronosticoVentas;
  final List<SugerenciaCompra> sugerenciasCompra;
  final double rotacionInventario;
  final List<ClienteTop> clientesTop;
  final double ticketPromedio;
  final double valorStockMuerto;
  final List<VentaSinCliente> ventasNoRegistradas;
  final List<ClienteInactivo> clientesInactivos;

  InteligenciaNegocioData({
    required this.pronosticoVentas,
    required this.sugerenciasCompra,
    required this.rotacionInventario,
    required this.clientesTop,
    required this.ticketPromedio,
    required this.valorStockMuerto,
    required this.ventasNoRegistradas,
    required this.clientesInactivos,
  });
}

class ReporteFinancieroData {
  final DateTime inicio;
  final DateTime fin;

  final double ventasPeriodo;
  final double comprasPeriodo;
  final double costoVentas;
  final double utilidadBruta;
  final double gastosPeriodo;
  final double utilidadNeta;

  final FlujoEfectivo flujoEfectivo;
  final List<PuntoMensual> serieMensual;

  final List<RankingProducto> topVendidosPorCantidad;
  final List<RankingProducto> topCompradosPorCantidad;
  final List<RankingProducto> topGananciaPorProducto;
  final List<ProductoSinVenta> productosSinVenta;

  final List<GananciaPorVenta> gananciaPorVenta;
  final List<VentasPorUsuario> ventasPorUsuario;

  final double totalAbonosComprasCredito;
  final List<AbonoPorProveedor> abonosPorProveedor;

  final RecomendacionPago recomendacionPago;
  final BalanceGeneral balanceGeneral;
  final InteligenciaNegocioData inteligenciaNegocio;

  ReporteFinancieroData({
    required this.inicio,
    required this.fin,
    required this.ventasPeriodo,
    required this.comprasPeriodo,
    required this.costoVentas,
    required this.utilidadBruta,
    required this.gastosPeriodo,
    required this.utilidadNeta,
    required this.flujoEfectivo,
    required this.serieMensual,
    required this.gananciaPorVenta,
    required this.topVendidosPorCantidad,
    required this.topCompradosPorCantidad,
    required this.topGananciaPorProducto,
    required this.productosSinVenta,
    required this.ventasPorUsuario,
    required this.totalAbonosComprasCredito,
    required this.abonosPorProveedor,
    required this.recomendacionPago,
    required this.balanceGeneral,
    required this.inteligenciaNegocio,
  });

  double get margenBrutoPorcentaje => ventasPeriodo <= 0 ? 0 : (utilidadBruta / ventasPeriodo) * 100;
}
