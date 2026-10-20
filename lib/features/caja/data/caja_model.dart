double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();

class CajaModel {
  final String id;
  final bool abierta;
  final String usuario;
  final String usuarioCierre;
  final DateTime abiertaEn;
  final DateTime? cerradaEn;
  final double montoApertura;
  final double? montoCierre;
  final double efectivoEsperado;
  final double diferencia;
  final String notas;
  final String notasCierre;
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
    required this.cerradaEn,
    required this.montoApertura,
    required this.montoCierre,
    required this.efectivoEsperado,
    required this.diferencia,
    required this.notas,
    required this.notasCierre,
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
      cerradaEn: m['cerradaEn'] == null ? null : DateTime.parse(m['cerradaEn'] as String),
      montoApertura: _num(m['montoApertura']),
      montoCierre: m['montoCierre'] == null ? null : _num(m['montoCierre']),
      efectivoEsperado: _num(m['efectivoEsperado']),
      diferencia: _num(m['diferencia']),
      notas: m['notas'] ?? '',
      notasCierre: m['notasCierre'] ?? '',
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

  double get entradasEfectivo => ventasEfectivo + abonosEfectivo;
  double get salidasEfectivo => gastos + pagosProveedores + comprasEfectivo;
}
