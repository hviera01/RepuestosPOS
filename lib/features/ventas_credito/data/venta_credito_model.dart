class FacturaOrigenModel {
  final String id;
  final String numeroDocumento;
  final double saldoPendiente;

  FacturaOrigenModel({required this.id, required this.numeroDocumento, required this.saldoPendiente});

  factory FacturaOrigenModel.fromMap(Map<String, dynamic> data) {
    return FacturaOrigenModel(
      id: data['id'] ?? '',
      numeroDocumento: data['numeroDocumento'] ?? '',
      saldoPendiente: (data['saldoPendiente'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'numeroDocumento': numeroDocumento, 'saldoPendiente': saldoPendiente};
}

class VentaCreditoModel {
  final String id;
  final String documentoCliente;
  final String nombreCliente;
  final String? idCliente;
  final String numeroDocumento;
  final double montoTotal;
  final double saldoPendiente;
  final DateTime? fechaRegistro;
  final DateTime? fechaVencimiento;
  final bool fusionada;

  final String telefono;



  final bool sinVentaOrigen;

  final List<FacturaOrigenModel> facturasOrigen;

  VentaCreditoModel({
    required this.id,
    required this.documentoCliente,
    required this.nombreCliente,
    this.idCliente,
    required this.numeroDocumento,
    required this.montoTotal,
    required this.saldoPendiente,
    required this.fechaRegistro,
    required this.fechaVencimiento,
    this.fusionada = false,
    this.sinVentaOrigen = false,
    this.facturasOrigen = const [],
    this.telefono = '',
  });

  bool get liquidada => saldoPendiente <= 0;

  bool get vencida => !liquidada && fechaVencimiento != null && DateTime.now().isAfter(fechaVencimiento!);

  bool get esFusion => facturasOrigen.isNotEmpty;

  factory VentaCreditoModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha(String? iso) => iso == null ? null : DateTime.parse(iso);
    return VentaCreditoModel(
      id: id,
      documentoCliente: data['documento_cliente'] ?? '',
      nombreCliente: data['nombre_cliente'] ?? '',
      idCliente: data['id_cliente'] as String?,
      numeroDocumento: data['numero_documento'] ?? '',
      montoTotal: (data['monto_total'] ?? 0).toDouble(),
      saldoPendiente: (data['saldo_pendiente'] ?? 0).toDouble(),
      fechaRegistro: fecha(data['fecha_registro'] as String?),
      fechaVencimiento: fecha(data['fecha_vencimiento'] as String?),
      fusionada: data['fusionada'] ?? false,
      sinVentaOrigen: data['sin_venta_origen'] ?? false,
      facturasOrigen: ((data['facturas_origen'] as List<dynamic>?) ?? [])
          .map((f) => FacturaOrigenModel.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList(),
      telefono: data['telefono'] ?? '',
    );
  }

  String get textoBusqueda => '$numeroDocumento $nombreCliente $documentoCliente';
}
