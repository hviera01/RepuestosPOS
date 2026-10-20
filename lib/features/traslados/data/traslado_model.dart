import 'item_traslado_model.dart';

class TrasladoModel {
  final String id;
  final String numero;
  final String idSucursalOrigen;
  final String nombreSucursalOrigen;
  final String idSucursalDestino;
  final String nombreSucursalDestino;
  final DateTime? fecha;
  final String estado;
  final String observaciones;
  final String usuarioCrea;
  final String usuarioRecibe;
  final DateTime? fechaRecepcion;
  final List<ItemTrasladoModel> detalle;
  final double totalItemsGuardado;
  final bool solicitudImpresionEnVivo;
  final bool? solicitudImpresionEsCopia;

  TrasladoModel({
    required this.id,
    required this.numero,
    required this.idSucursalOrigen,
    required this.nombreSucursalOrigen,
    required this.idSucursalDestino,
    required this.nombreSucursalDestino,
    this.fecha,
    this.estado = 'Pendiente',
    this.observaciones = '',
    required this.usuarioCrea,
    this.usuarioRecibe = '',
    this.fechaRecepcion,
    this.detalle = const [],
    this.totalItemsGuardado = 0,
    this.solicitudImpresionEnVivo = false,
    this.solicitudImpresionEsCopia,
  });

  double get totalItems => detalle.isEmpty ? totalItemsGuardado : detalle.fold<double>(0, (s, i) => s + i.cantidad);

  factory TrasladoModel.fromMap(Map<String, dynamic> data, [List<ItemTrasladoModel> detalle = const []]) {
    DateTime? fecha(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();
    return TrasladoModel(
      id: data['id'] as String,
      numero: (data['numero'] ?? '') as String,
      idSucursalOrigen: (data['id_sucursal_origen'] ?? '') as String,
      nombreSucursalOrigen: (data['nombre_sucursal_origen'] ?? '') as String,
      idSucursalDestino: (data['id_sucursal_destino'] ?? '') as String,
      nombreSucursalDestino: (data['nombre_sucursal_destino'] ?? '') as String,
      fecha: fecha(data['fecha']),
      estado: (data['estado'] ?? 'Pendiente') as String,
      observaciones: (data['observaciones'] ?? '') as String,
      usuarioCrea: (data['usuario_crea'] ?? '') as String,
      usuarioRecibe: (data['usuario_recibe'] ?? '') as String,
      fechaRecepcion: fecha(data['fecha_recepcion']),
      detalle: detalle,
      totalItemsGuardado: ((data['total_items'] ?? 0) as num).toDouble(),
      solicitudImpresionEnVivo: (data['solicitud_impresion_en_vivo'] ?? false) as bool,
      solicitudImpresionEsCopia: data['solicitud_impresion_es_copia'] as bool?,
    );
  }
}
