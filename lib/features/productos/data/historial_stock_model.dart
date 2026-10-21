class HistorialStockModel {
  final String id;
  final double stockAnterior;
  final double stockNuevo;
  final DateTime? fecha;
  final String usuario;
  final String motivo;

  HistorialStockModel({
    required this.id,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.fecha,
    required this.usuario,
    required this.motivo,
  });

  factory HistorialStockModel.fromMap(String id, Map<String, dynamic> data) {
    return HistorialStockModel(
      id: id,
      stockAnterior: (data['stock_anterior'] ?? 0).toDouble(),
      stockNuevo: (data['stock_nuevo'] ?? 0).toDouble(),
      fecha: data['fecha'] == null ? null : DateTime.parse(data['fecha'] as String),
      usuario: data['usuario'] ?? '',
      motivo: data['motivo'] ?? '',
    );
  }

  double get delta => stockNuevo - stockAnterior;

  TipoMovimientoStock get tipo {
    if (motivo.startsWith('Anulación de venta')) return TipoMovimientoStock.anulacionVenta;
    if (motivo.startsWith('Venta ')) return TipoMovimientoStock.venta;
    if (motivo.startsWith('Anulación de compra')) return TipoMovimientoStock.anulacionCompra;
    if (motivo.startsWith('Compra ')) return TipoMovimientoStock.compra;
    if (motivo.startsWith('Anulación de traslado')) return TipoMovimientoStock.anulacionTraslado;
    if (motivo.startsWith('Traslado ')) return TipoMovimientoStock.traslado;
    return delta >= 0 ? TipoMovimientoStock.ajusteEntrada : TipoMovimientoStock.ajusteSalida;
  }
}

enum TipoMovimientoStock { venta, anulacionVenta, compra, anulacionCompra, traslado, anulacionTraslado, ajusteEntrada, ajusteSalida }

const etiquetasTipoMovimientoStock = {
  TipoMovimientoStock.venta: 'Venta',
  TipoMovimientoStock.anulacionVenta: 'Anulación de venta',
  TipoMovimientoStock.compra: 'Compra',
  TipoMovimientoStock.anulacionCompra: 'Anulación de compra',
  TipoMovimientoStock.traslado: 'Traslado',
  TipoMovimientoStock.anulacionTraslado: 'Anulación de traslado',
  TipoMovimientoStock.ajusteEntrada: 'Ajuste manual (entrada)',
  TipoMovimientoStock.ajusteSalida: 'Ajuste manual (salida)',
};