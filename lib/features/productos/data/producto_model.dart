import 'compatibilidad_model.dart';

class ComponenteProductoModel {
  final String idProducto;
  final double cantidad;

  ComponenteProductoModel({required this.idProducto, required this.cantidad});

  Map<String, dynamic> toMap() => {'idProducto': idProducto, 'cantidad': cantidad};

  factory ComponenteProductoModel.fromMap(Map<String, dynamic> data) {
    return ComponenteProductoModel(
      idProducto: data['idProducto'] ?? '',
      cantidad: (data['cantidad'] ?? 0).toDouble(),
    );
  }
}

class ProductoModel {
  final String id;
  final String codigo;
  final String codigoBarras;
  final String nombre;
  final String descripcion;
  final String idCategoria;
  final double stock;
  final double precioCompra;
  final double precioVenta;
  final double precioVenta2;
  final double precioVenta3;
  final bool estado;
  final String imagenUrl;
  final bool esCombo;
  final List<ComponenteProductoModel> componentes;
  final String nombreBase;
  final bool nombreAutomatico;
  final List<CompatibilidadModel> compatibilidad;

  ProductoModel({
    required this.id,
    required this.codigo,
    required this.codigoBarras,
    required this.nombre,
    required this.descripcion,
    required this.idCategoria,
    required this.stock,
    required this.precioCompra,
    required this.precioVenta,
    required this.precioVenta2,
    required this.precioVenta3,
    required this.estado,
    this.imagenUrl = '',
    this.esCombo = false,
    this.componentes = const [],
    this.nombreBase = '',
    this.nombreAutomatico = false,
    this.compatibilidad = const [],
  });

  factory ProductoModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductoModel(
      id: id,
      codigo: data['codigo'] ?? '',
      codigoBarras: data['codigo_barras'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      idCategoria: data['id_categoria'] ?? '',
      stock: (data['stock'] ?? 0).toDouble(),
      precioCompra: (data['precio_compra'] ?? 0).toDouble(),
      precioVenta: (data['precio_venta'] ?? 0).toDouble(),
      precioVenta2: (data['precio_venta2'] ?? 0).toDouble(),
      precioVenta3: (data['precio_venta3'] ?? 0).toDouble(),
      estado: data['estado'] ?? true,
      imagenUrl: data['imagen_url'] ?? '',
      esCombo: data['es_combo'] ?? false,
      componentes: (data['componentes'] as List<dynamic>? ?? [])
          .map((c) => ComponenteProductoModel.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      nombreBase: data['nombre_base'] ?? '',
      nombreAutomatico: data['nombre_automatico'] ?? false,
      compatibilidad: (data['compatibilidad'] as List<dynamic>? ?? [])
          .map((c) => CompatibilidadModel.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }

  String get textoBusqueda => '$codigo $codigoBarras $nombre $descripcion $textoVehiculos';

  String get textoVehiculos => compatibilidad.map((c) => c.textoCompleto).join(' ');

  double stockDisponibleCombo(Map<String, ProductoModel> mapaProductos) {
    if (componentes.isEmpty) return 0;
    double? minimo;
    for (final c in componentes) {
      if (c.cantidad <= 0) continue;
      final stockComponente = mapaProductos[c.idProducto]?.stock ?? 0;
      final disponible = (stockComponente / c.cantidad).floorToDouble();
      if (minimo == null || disponible < minimo) minimo = disponible;
    }
    return minimo ?? 0;
  }
}