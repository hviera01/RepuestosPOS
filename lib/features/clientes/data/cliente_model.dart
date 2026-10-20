class ClienteModel {
  final String id;
  final String dni;
  final String nombreCompleto;
  final String direccion;
  final String telefono;
  final bool estado;
  final DateTime? fechaUltimaCompra;

  ClienteModel({
    required this.id,
    required this.dni,
    required this.nombreCompleto,
    required this.direccion,
    required this.telefono,
    required this.estado,
    this.fechaUltimaCompra,
  });

  factory ClienteModel.fromMap(String id, Map<String, dynamic> data) {
    return ClienteModel(
      id: id,
      dni: data['dni'] ?? '',
      nombreCompleto: data['nombre_completo'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      estado: data['estado'] ?? true,
      fechaUltimaCompra: data['fecha_ultima_compra'] == null ? null : DateTime.parse(data['fecha_ultima_compra'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dni': dni,
      'nombre_completo': nombreCompleto,
      'direccion': direccion,
      'telefono': telefono,
      'estado': estado,
      'fecha_ultima_compra': fechaUltimaCompra?.toIso8601String(),
    };
  }

  String get textoBusqueda => '$dni $nombreCompleto $direccion $telefono';
}
