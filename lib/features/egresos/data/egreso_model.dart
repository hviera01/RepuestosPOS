class EgresoModel {
  final String id;
  final DateTime fecha;
  final double monto;
  final String descripcion;
  final String usuario;
  final String metodoPago;
  final String categoria;
  final bool esPagado;
  final DateTime? fechaPago;
  final DateTime? fechaRegistro;
  final String beneficiario;
  final String comprobante;

  EgresoModel({
    this.id = '',
    required this.fecha,
    required this.monto,
    required this.descripcion,
    required this.usuario,
    required this.metodoPago,
    required this.categoria,
    required this.esPagado,
    this.fechaPago,
    this.fechaRegistro,
    this.beneficiario = '',
    this.comprobante = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'descripcion': descripcion,
      'usuario': usuario,
      'metodo_pago': metodoPago,
      'categoria': categoria,
      'es_pagado': esPagado,
      'fecha_pago': fechaPago?.toIso8601String(),
      'beneficiario': beneficiario,
      'comprobante': comprobante,
    };
  }

  factory EgresoModel.fromMap(String id, Map<String, dynamic> data) {
    return EgresoModel(
      id: id,
      fecha: data['fecha'] == null ? DateTime.now() : DateTime.parse(data['fecha'] as String),
      monto: (data['monto'] ?? 0).toDouble(),
      descripcion: data['descripcion'] ?? '',
      usuario: data['usuario'] ?? '',
      metodoPago: data['metodo_pago'] ?? 'Efectivo',
      categoria: data['categoria'] ?? 'Otros gastos',
      esPagado: data['es_pagado'] ?? true,
      fechaPago: data['fecha_pago'] == null ? null : DateTime.parse(data['fecha_pago'] as String),
      fechaRegistro: data['fecha_registro'] == null ? null : DateTime.parse(data['fecha_registro'] as String),
      beneficiario: data['beneficiario'] ?? '',
      comprobante: data['comprobante'] ?? '',
    );
  }

  String get textoBusqueda => '$descripcion $usuario $metodoPago $categoria $beneficiario $comprobante';
}

class MovimientoFinanciero {
  final DateTime fecha;
  final String tipoMovimiento;
  final String descripcion;
  final double ingreso;
  final double egreso;
  final String metodoPago;
  final String categoria;
  final bool esPagado;
  final DateTime? fechaPago;
  final String usuario;
  final String idEgreso;
  final String beneficiario;
  final String comprobante;

  MovimientoFinanciero({
    required this.fecha,
    required this.tipoMovimiento,
    required this.descripcion,
    this.ingreso = 0,
    this.egreso = 0,
    this.metodoPago = '',
    this.categoria = '',
    this.esPagado = true,
    this.fechaPago,
    this.usuario = '',
    this.idEgreso = '',
    this.beneficiario = '',
    this.comprobante = '',
  });

  bool get esEgresoManual => tipoMovimiento == 'Egreso Manual';
}
