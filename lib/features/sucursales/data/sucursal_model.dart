class SucursalModel {
  final String id;
  final String nombre;
  final String direccion;
  final bool estado;

  SucursalModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.estado,
  });

  factory SucursalModel.fromMap(Map<String, dynamic> data) {
    return SucursalModel(
      id: data['id'] as String,
      nombre: (data['nombre'] ?? '') as String,
      direccion: (data['direccion'] ?? '') as String,
      estado: (data['estado'] ?? true) as bool,
    );
  }

  String get textoBusqueda => '$nombre $direccion';
}
