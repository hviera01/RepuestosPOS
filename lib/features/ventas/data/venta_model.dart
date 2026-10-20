import 'item_venta_model.dart';
import 'pago_detalle_model.dart';
import '../../../core/utils/formato_moneda.dart';

class VentaModel {
  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String documentoCliente;
  final String nombreCliente;
  final String? idCliente;
  final String metodoPago;
  final double montoPago;
  final double montoCambio;
  final double subtotal;
  final double impuesto;
  final double totalAPagar;
  final String condicion;
  final DateTime? fechaVencimiento;
  final DateTime? fechaRegistro;
  final String estado;
  final String usuarioRegistro;
  final double cantidadProductos;
  final String oc;
  final String regExonerado;
  final String regSag;
  final double descuentoGlobal;
  final String observaciones;
  final List<ItemVentaModel> detalle;
  final List<PagoDetalle> pagosMixtos;
  final String usuarioAnulacion;
  final String motivoAnulacion;
  final DateTime? fechaAnulacion;
  final bool pendienteImpresion;
  final bool solicitudImpresionEnVivo;
  final bool? solicitudImpresionEsCopia;
  final bool esEnvio;
  final String envioNombre;
  final String envioDireccion;
  final String envioTelefono;
  final bool solicitudImpresionGuiaEnvio;
  final bool solicitudImpresionGuiaGrande;

  bool get estaAnulada => estado == 'Anulada';

  double get descuentosYRebajas {
    final listaSinDescuento = detalle.fold<double>(
      0,
      (s, item) => s + redondearMoneda(item.precioVenta * item.cantidad),
    );
    return redondearMoneda(listaSinDescuento - subtotal);
  }

  VentaModel copyWith({
    List<ItemVentaModel>? detalle,
    bool? esEnvio,
    String? envioNombre,
    String? envioDireccion,
    String? envioTelefono,
    bool? solicitudImpresionGuiaEnvio,
    bool? solicitudImpresionGuiaGrande,
  }) {
    return VentaModel(
      id: id,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
      documentoCliente: documentoCliente,
      nombreCliente: nombreCliente,
      idCliente: idCliente,
      metodoPago: metodoPago,
      montoPago: montoPago,
      montoCambio: montoCambio,
      subtotal: subtotal,
      impuesto: impuesto,
      totalAPagar: totalAPagar,
      condicion: condicion,
      fechaVencimiento: fechaVencimiento,
      fechaRegistro: fechaRegistro,
      estado: estado,
      usuarioRegistro: usuarioRegistro,
      cantidadProductos: cantidadProductos,
      oc: oc,
      regExonerado: regExonerado,
      regSag: regSag,
      descuentoGlobal: descuentoGlobal,
      observaciones: observaciones,
      detalle: detalle ?? this.detalle,
      pagosMixtos: pagosMixtos,
      usuarioAnulacion: usuarioAnulacion,
      motivoAnulacion: motivoAnulacion,
      fechaAnulacion: fechaAnulacion,
      pendienteImpresion: pendienteImpresion,
      solicitudImpresionEnVivo: solicitudImpresionEnVivo,
      solicitudImpresionEsCopia: solicitudImpresionEsCopia,
      esEnvio: esEnvio ?? this.esEnvio,
      envioNombre: envioNombre ?? this.envioNombre,
      envioDireccion: envioDireccion ?? this.envioDireccion,
      envioTelefono: envioTelefono ?? this.envioTelefono,
      solicitudImpresionGuiaEnvio: solicitudImpresionGuiaEnvio ?? this.solicitudImpresionGuiaEnvio,
      solicitudImpresionGuiaGrande: solicitudImpresionGuiaGrande ?? this.solicitudImpresionGuiaGrande,
    );
  }

  VentaModel({
    required this.id,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.documentoCliente,
    required this.nombreCliente,
    this.idCliente,
    required this.metodoPago,
    required this.montoPago,
    required this.montoCambio,
    required this.subtotal,
    required this.impuesto,
    required this.totalAPagar,
    required this.condicion,
    required this.fechaVencimiento,
    required this.fechaRegistro,
    required this.estado,
    required this.usuarioRegistro,
    required this.cantidadProductos,
    required this.oc,
    required this.regExonerado,
    required this.regSag,
    this.descuentoGlobal = 0,
    this.observaciones = '',
    required this.detalle,
    this.pagosMixtos = const [],
    this.usuarioAnulacion = '',
    this.motivoAnulacion = '',
    this.fechaAnulacion,
    this.pendienteImpresion = false,
    this.solicitudImpresionEnVivo = false,
    this.solicitudImpresionEsCopia,
    this.esEnvio = false,
    this.envioNombre = '',
    this.envioDireccion = '',
    this.envioTelefono = '',
    this.solicitudImpresionGuiaEnvio = false,
    this.solicitudImpresionGuiaGrande = false,
  });

  factory VentaModel.fromMap(String id, Map<String, dynamic> data, List<ItemVentaModel> detalle) {
    DateTime? fecha(String? iso) => iso == null ? null : DateTime.parse(iso);
    return VentaModel(
      id: id,
      tipoDocumento: data['tipo_documento'] ?? '',
      numeroDocumento: data['numero_documento'] ?? '',
      documentoCliente: data['documento_cliente'] ?? '',
      nombreCliente: data['nombre_cliente'] ?? '',
      idCliente: data['id_cliente'] as String?,
      metodoPago: data['metodo_pago'] ?? '',
      montoPago: (data['monto_pago'] ?? 0).toDouble(),
      montoCambio: (data['monto_cambio'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      impuesto: (data['impuesto'] ?? 0).toDouble(),
      totalAPagar: (data['total_a_pagar'] ?? 0).toDouble(),
      condicion: data['condicion'] ?? '',
      fechaVencimiento: fecha(data['fecha_vencimiento'] as String?),
      fechaRegistro: fecha(data['fecha_registro'] as String?),
      estado: data['estado'] ?? 'Activa',
      usuarioRegistro: data['usuario_registro'] ?? '',
      cantidadProductos: (data['cantidad_productos'] ?? 0).toDouble(),
      oc: data['oc'] ?? '',
      regExonerado: data['reg_exonerado'] ?? '',
      regSag: data['reg_sag'] ?? '',
      descuentoGlobal: (data['descuento_global'] ?? 0).toDouble(),
      observaciones: data['observaciones'] ?? '',
      detalle: detalle,
      pagosMixtos: PagoDetalle.listaFromMaps(data['pagos_mixtos'] as List<dynamic>?),
      usuarioAnulacion: data['usuario_anulacion'] ?? '',
      motivoAnulacion: data['motivo_anulacion'] ?? '',
      fechaAnulacion: fecha(data['fecha_anulacion'] as String?),
      pendienteImpresion: data['pendiente_impresion'] ?? false,
      solicitudImpresionEnVivo: data['solicitud_impresion_en_vivo'] ?? false,
      solicitudImpresionEsCopia: data['solicitud_impresion_es_copia'] as bool?,
      esEnvio: data['es_envio'] ?? false,
      envioNombre: data['envio_nombre'] ?? '',
      envioDireccion: data['envio_direccion'] ?? '',
      envioTelefono: data['envio_telefono'] ?? '',
      solicitudImpresionGuiaEnvio: data['solicitud_impresion_guia_envio'] ?? false,
      solicitudImpresionGuiaGrande: data['solicitud_impresion_guia_grande'] ?? false,
    );
  }
}
