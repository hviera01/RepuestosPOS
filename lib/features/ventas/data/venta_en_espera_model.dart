import 'item_venta_model.dart';
import '../../../core/utils/formato_moneda.dart';

class OrigenVentaEnEspera {
  static const manual = 'manual';
  static const automatico = 'automatico';
}

class VentaEnEsperaModel {
  final String id;
  final DateTime? fecha;
  final String tipoDocumento;
  final String condicion;
  final String metodoPago;
  final String documentoCliente;
  final String nombreCliente;
  final String? idCliente;
  final DateTime? fechaVencimiento;
  final String oc;
  final String regExonerado;
  final String regSag;
  final String observaciones;
  final double descuentoGlobal;
  final List<ItemVentaModel> items;
  final String origen;
  final bool stockReservado;
  final Map<String, double> cantidadesReservadas;

  VentaEnEsperaModel({
    required this.id,
    required this.fecha,
    required this.tipoDocumento,
    required this.condicion,
    required this.metodoPago,
    required this.documentoCliente,
    required this.nombreCliente,
    this.idCliente,
    required this.fechaVencimiento,
    required this.oc,
    required this.regExonerado,
    required this.regSag,
    this.observaciones = '',
    this.descuentoGlobal = 0,
    required this.items,
    this.origen = OrigenVentaEnEspera.automatico,
    this.stockReservado = false,
    this.cantidadesReservadas = const {},
  });

  double get total => items.fold<double>(0, (s, i) => s + i.subtotal);

  double get totalFinal {
    final aplicaIsv = tipoDocumento == 'Factura' || tipoDocumento == 'Boleta';
    var totalFinal = 0.0;
    for (final i in items) {
      final precioFinal = aplicaIsv ? redondearMoneda(i.precioVenta * 1.15) : i.precioVenta;
      totalFinal += redondearMoneda(precioFinal * i.cantidad * (1 - i.descuentoPorcentaje / 100));
    }
    totalFinal *= (1 - descuentoGlobal / 100);
    final base = totalFinal.floorToDouble();
    final resto = totalFinal - base;
    return resto >= 0.90 ? base + 1 : base;
  }

  factory VentaEnEsperaModel.fromMap(String id, Map<String, dynamic> data) {
    final itemsRaw = (data['items'] as List<dynamic>? ?? []);
    return VentaEnEsperaModel(
      id: id,
      fecha: data['fecha'] == null ? null : DateTime.parse(data['fecha'] as String),
      tipoDocumento: data['tipo_documento'] ?? 'Factura',
      condicion: data['condicion'] ?? 'Contado',
      metodoPago: data['metodo_pago'] ?? 'Efectivo',
      documentoCliente: data['documento_cliente'] ?? '',
      nombreCliente: data['nombre_cliente'] ?? '',
      idCliente: data['id_cliente'] as String?,
      fechaVencimiento: data['fecha_vencimiento'] == null ? null : DateTime.parse(data['fecha_vencimiento'] as String),
      oc: data['oc'] ?? '',
      regExonerado: data['reg_exonerado'] ?? '',
      regSag: data['reg_sag'] ?? '',
      observaciones: data['observaciones'] ?? '',
      descuentoGlobal: (data['descuento_global'] ?? 0).toDouble(),
      items: itemsRaw.map((e) => ItemVentaModel.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      origen: data['origen'] ?? OrigenVentaEnEspera.automatico,
      stockReservado: data['stock_reservado'] ?? false,
      cantidadesReservadas: (data['cantidades_reservadas'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoDocumento': tipoDocumento,
      'condicion': condicion,
      'metodoPago': metodoPago,
      'documentoCliente': documentoCliente,
      'nombreCliente': nombreCliente,
      'idCliente': idCliente,
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'oc': oc,
      'regExonerado': regExonerado,
      'regSag': regSag,
      'observaciones': observaciones,
      'descuentoGlobal': descuentoGlobal,
      'items': items.map((i) => i.toMap()).toList(),
      'origen': origen,
      'stockReservado': stockReservado,
      'cantidadesReservadas': cantidadesReservadas,
    };
  }

  Map<String, dynamic> toRow() {
    return {
      'fecha': DateTime.now().toIso8601String(),
      'tipo_documento': tipoDocumento,
      'condicion': condicion,
      'metodo_pago': metodoPago,
      'documento_cliente': documentoCliente,
      'nombre_cliente': nombreCliente,
      'id_cliente': idCliente,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'oc': oc,
      'reg_exonerado': regExonerado,
      'reg_sag': regSag,
      'observaciones': observaciones,
      'descuento_global': descuentoGlobal,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
