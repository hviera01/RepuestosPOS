double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();

class CajaConfig {
  final bool soloDesdeApertura;
  final bool ventasEfectivo;
  final bool abonosEfectivo;
  final bool gastos;
  final bool pagosProveedores;
  final bool comprasEfectivo;

  const CajaConfig({
    this.soloDesdeApertura = false,
    this.ventasEfectivo = true,
    this.abonosEfectivo = true,
    this.gastos = true,
    this.pagosProveedores = true,
    this.comprasEfectivo = true,
  });

  factory CajaConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const CajaConfig();
    return CajaConfig(
      soloDesdeApertura: m['soloDesdeApertura'] ?? false,
      ventasEfectivo: m['ventasEfectivo'] ?? true,
      abonosEfectivo: m['abonosEfectivo'] ?? true,
      gastos: m['gastos'] ?? true,
      pagosProveedores: m['pagosProveedores'] ?? true,
      comprasEfectivo: m['comprasEfectivo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'soloDesdeApertura': soloDesdeApertura,
        'ventasEfectivo': ventasEfectivo,
        'abonosEfectivo': abonosEfectivo,
        'gastos': gastos,
        'pagosProveedores': pagosProveedores,
        'comprasEfectivo': comprasEfectivo,
      };

  CajaConfig copyWith({
    bool? soloDesdeApertura,
    bool? ventasEfectivo,
    bool? abonosEfectivo,
    bool? gastos,
    bool? pagosProveedores,
    bool? comprasEfectivo,
  }) {
    return CajaConfig(
      soloDesdeApertura: soloDesdeApertura ?? this.soloDesdeApertura,
      ventasEfectivo: ventasEfectivo ?? this.ventasEfectivo,
      abonosEfectivo: abonosEfectivo ?? this.abonosEfectivo,
      gastos: gastos ?? this.gastos,
      pagosProveedores: pagosProveedores ?? this.pagosProveedores,
      comprasEfectivo: comprasEfectivo ?? this.comprasEfectivo,
    );
  }
}

class CajaModel {
  final String id;
  final bool abierta;
  final String usuario;
  final String usuarioCierre;
  final DateTime abiertaEn;
  final DateTime? hastaEn;
  final DateTime aperturaReal;
  final DateTime? cerradaEn;
  final double montoApertura;
  final double? montoCierre;
  final double efectivoEsperado;
  final double diferencia;
  final String notas;
  final String notasCierre;
  final CajaConfig config;
  final double ventasEfectivo;
  final double ventasTarjeta;
  final double ventasTransferencia;
  final double ventasCheque;
  final double ventasCredito;
  final double totalVentas;
  final int cantidadVentas;
  final double abonosEfectivo;
  final double abonosOtros;
  final double gastos;
  final double pagosProveedores;
  final double comprasEfectivo;

  const CajaModel({
    required this.id,
    required this.abierta,
    required this.usuario,
    required this.usuarioCierre,
    required this.abiertaEn,
    required this.hastaEn,
    required this.aperturaReal,
    required this.cerradaEn,
    required this.montoApertura,
    required this.montoCierre,
    required this.efectivoEsperado,
    required this.diferencia,
    required this.notas,
    required this.notasCierre,
    required this.config,
    required this.ventasEfectivo,
    required this.ventasTarjeta,
    required this.ventasTransferencia,
    required this.ventasCheque,
    required this.ventasCredito,
    required this.totalVentas,
    required this.cantidadVentas,
    required this.abonosEfectivo,
    required this.abonosOtros,
    required this.gastos,
    required this.pagosProveedores,
    required this.comprasEfectivo,
  });

  factory CajaModel.fromMap(Map<String, dynamic> m) {
    return CajaModel(
      id: m['id'] as String,
      abierta: m['estado'] == 'abierta',
      usuario: m['usuario'] ?? '',
      usuarioCierre: m['usuarioCierre'] ?? '',
      abiertaEn: DateTime.parse(m['abiertaEn'] as String),
      hastaEn: m['hastaEn'] == null ? null : DateTime.parse(m['hastaEn'] as String),
      aperturaReal: DateTime.parse((m['aperturaReal'] ?? m['abiertaEn']) as String),
      cerradaEn: m['cerradaEn'] == null ? null : DateTime.parse(m['cerradaEn'] as String),
      montoApertura: _num(m['montoApertura']),
      montoCierre: m['montoCierre'] == null ? null : _num(m['montoCierre']),
      efectivoEsperado: _num(m['efectivoEsperado']),
      diferencia: _num(m['diferencia']),
      notas: m['notas'] ?? '',
      notasCierre: m['notasCierre'] ?? '',
      config: CajaConfig.fromMap(m['config'] == null ? null : Map<String, dynamic>.from(m['config'] as Map)),
      ventasEfectivo: _num(m['ventasEfectivo']),
      ventasTarjeta: _num(m['ventasTarjeta']),
      ventasTransferencia: _num(m['ventasTransferencia']),
      ventasCheque: _num(m['ventasCheque']),
      ventasCredito: _num(m['ventasCredito']),
      totalVentas: _num(m['totalVentas']),
      cantidadVentas: (m['cantidadVentas'] ?? 0) as int,
      abonosEfectivo: _num(m['abonosEfectivo']),
      abonosOtros: _num(m['abonosOtros']),
      gastos: _num(m['gastos']),
      pagosProveedores: _num(m['pagosProveedores']),
      comprasEfectivo: _num(m['comprasEfectivo']),
    );
  }

  DateTime get desdeEfectivo => config.soloDesdeApertura && aperturaReal.isAfter(abiertaEn) ? aperturaReal : abiertaEn;
}
