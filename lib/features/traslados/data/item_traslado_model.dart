class ItemTrasladoModel {
  final String idProducto;
  final String nombreProducto;
  final double cantidad;
  final String ubicacion;

  ItemTrasladoModel({
    required this.idProducto,
    required this.nombreProducto,
    required this.cantidad,
    this.ubicacion = '',
  });

  factory ItemTrasladoModel.fromMap(Map<String, dynamic> data) {
    return ItemTrasladoModel(
      idProducto: (data['id_producto'] ?? '') as String,
      nombreProducto: (data['nombre_producto'] ?? '') as String,
      cantidad: ((data['cantidad'] ?? 0) as num).toDouble(),
      ubicacion: (data['ubicacion'] ?? '') as String,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'idProducto': idProducto,
      'nombreProducto': nombreProducto,
      'cantidad': cantidad,
      'ubicacion': ubicacion,
    };
  }
}
