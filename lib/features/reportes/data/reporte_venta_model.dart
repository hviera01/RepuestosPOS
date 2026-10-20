import '../../ventas/data/pago_detalle_model.dart';

class ReporteVentaModel {
  final String id;
  final DateTime? fechaRegistro;
  final String tipoDocumento;
  final String numeroDocumento;
  final double totalAPagar;
  final int cantidadProductos;
  final String metodoPago;
  final String usuarioRegistro;
  final String documentoCliente;
  final String nombreCliente;
  final String? idCliente;
  final double impuesto;
  final String condicion;
  final DateTime? fechaVencimiento;
  final String estado;
  final bool pendienteImpresion;
  final DateTime? creadoEn;
  final List<PagoDetalle> pagosMixtos;

  ReporteVentaModel({
    required this.id,
    required this.fechaRegistro,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.totalAPagar,
    required this.cantidadProductos,
    required this.metodoPago,
    required this.usuarioRegistro,
    required this.documentoCliente,
    required this.nombreCliente,
    this.idCliente,
    required this.impuesto,
    required this.condicion,
    required this.fechaVencimiento,
    required this.estado,
    this.pendienteImpresion = false,
    this.creadoEn,
    this.pagosMixtos = const [],
  });

  bool get esActiva => estado == 'Activa';
  bool get esCotizacion => tipoDocumento == 'Cotizacion';

  factory ReporteVentaModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha(String? iso) => iso == null ? null : DateTime.parse(iso);
    return ReporteVentaModel(
      id: id,
      fechaRegistro: fecha(data['fecha_registro'] as String?),
      tipoDocumento: data['tipo_documento'] ?? 'Factura',
      numeroDocumento: data['numero_documento'] ?? '',
      totalAPagar: (data['total_a_pagar'] ?? 0).toDouble(),
      cantidadProductos: (data['cantidad_productos'] ?? 0).toInt(),
      metodoPago: data['metodo_pago'] ?? '',
      usuarioRegistro: data['usuario_registro'] ?? '',
      documentoCliente: data['documento_cliente'] ?? '',
      nombreCliente: data['nombre_cliente'] ?? '',
      idCliente: data['id_cliente'] as String?,
      impuesto: (data['impuesto'] ?? 0).toDouble(),
      condicion: data['condicion'] ?? '',
      fechaVencimiento: fecha(data['fecha_vencimiento'] as String?),
      estado: data['estado'] ?? 'Activa',
      pendienteImpresion: data['pendiente_impresion'] ?? false,
      pagosMixtos: PagoDetalle.listaFromMaps(
        data['pagos_mixtos'] as List<dynamic>?,
      ),
    );
  }

  String get textoBusqueda =>
      '$numeroDocumento $nombreCliente $documentoCliente $metodoPago $tipoDocumento $condicion $usuarioRegistro';
}
