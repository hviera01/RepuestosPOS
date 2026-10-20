class ComponenteComboSnapshot {
  final String idProducto;
  final String idCategoria;
  final String nombreProducto;
  final double cantidad;
  final double precioCompraUsado;

  ComponenteComboSnapshot({
    required this.idProducto,
    required this.idCategoria,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioCompraUsado,
  });

  Map<String, dynamic> toMap() => {
    'idProducto': idProducto,
    'idCategoria': idCategoria,
    'nombreProducto': nombreProducto,
    'cantidad': cantidad,
    'precioCompraUsado': precioCompraUsado,
  };

  factory ComponenteComboSnapshot.fromMap(Map<String, dynamic> data) {
    return ComponenteComboSnapshot(
      idProducto: data['idProducto'] ?? '',
      idCategoria: data['idCategoria'] ?? '',
      nombreProducto: data['nombreProducto'] ?? '',
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      precioCompraUsado: (data['precioCompraUsado'] ?? 0).toDouble(),
    );
  }
}

class ItemVentaModel {
  final String idProducto;
  final String idCategoria;
  final String nombreProducto;
  final double precioVenta;
  final double cantidad;
  final double subtotal;
  final double precioCompraUsado;
  final double descuentoPorcentaje;
  final List<ComponenteComboSnapshot> componentes;
  final bool pendienteCompra;

  ItemVentaModel({
    required this.idProducto,
    required this.idCategoria,
    required this.nombreProducto,
    required this.precioVenta,
    required this.cantidad,
    required this.subtotal,
    required this.precioCompraUsado,
    this.descuentoPorcentaje = 0,
    this.componentes = const [],
    this.pendienteCompra = false,
  });

  bool get esCombo => componentes.isNotEmpty;

  factory ItemVentaModel.fromMap(Map<String, dynamic> data) {
    return ItemVentaModel(
      idProducto: data['idProducto'] ?? '',
      idCategoria: data['idCategoria'] ?? '',
      nombreProducto: data['nombreProducto'] ?? '',
      precioVenta: (data['precioVenta'] ?? 0).toDouble(),
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      precioCompraUsado: (data['precioCompraUsado'] ?? 0).toDouble(),
      descuentoPorcentaje: (data['descuentoPorcentaje'] ?? 0).toDouble(),
      componentes: (data['componentes'] as List<dynamic>? ?? [])
          .map((c) => ComponenteComboSnapshot.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      pendienteCompra: data['pendienteCompra'] ?? false,
    );
  }

  factory ItemVentaModel.fromRow(Map<String, dynamic> data) {
    return ItemVentaModel(
      idProducto: data['id_producto'] ?? '',
      idCategoria: data['id_categoria'] ?? '',
      nombreProducto: data['nombre_producto'] ?? '',
      precioVenta: (data['precio_venta'] ?? 0).toDouble(),
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      precioCompraUsado: (data['precio_compra_usado'] ?? 0).toDouble(),
      descuentoPorcentaje: (data['descuento_porcentaje'] ?? 0).toDouble(),
      componentes: (data['componentes'] as List<dynamic>? ?? [])
          .map((c) => ComponenteComboSnapshot.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      pendienteCompra: data['pendiente_compra'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idProducto': idProducto,
      'idCategoria': idCategoria,
      'nombreProducto': nombreProducto,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'precioCompraUsado': precioCompraUsado,
      'descuentoPorcentaje': descuentoPorcentaje,
      'componentes': componentes.map((c) => c.toMap()).toList(),
      'pendienteCompra': pendienteCompra,
    };
  }

  ItemVentaModel copyWith({
    String? nombreProducto,
    double? precioVenta,
    double? cantidad,
    double? subtotal,
    double? descuentoPorcentaje,
    double? precioCompraUsado,
    List<ComponenteComboSnapshot>? componentes,
    bool? pendienteCompra,
  }) {
    return ItemVentaModel(
      idProducto: idProducto,
      idCategoria: idCategoria,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      precioVenta: precioVenta ?? this.precioVenta,
      cantidad: cantidad ?? this.cantidad,
      subtotal: subtotal ?? this.subtotal,
      precioCompraUsado: precioCompraUsado ?? this.precioCompraUsado,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      componentes: componentes ?? this.componentes,
      pendienteCompra: pendienteCompra ?? this.pendienteCompra,
    );
  }
}
