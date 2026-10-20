const _sinCambio = Object();

class ItemCompraModel {
  final String idProducto;
  final String idCategoria;
  final String nombreProducto;
  final double precioCompra;
  final double cantidad;
  final double subtotal;
  final double descuentoPorcentaje;
  final double? precioVentaNuevo;
  final String? idPendienteReposicionVinculado;
  final String? numeroDocumentoVentaVinculada;
  final String? nombreProductoVentaVinculada;

  ItemCompraModel({
    required this.idProducto,
    required this.idCategoria,
    required this.nombreProducto,
    required this.precioCompra,
    required this.cantidad,
    required this.subtotal,
    this.descuentoPorcentaje = 0,
    this.precioVentaNuevo,
    this.idPendienteReposicionVinculado,
    this.numeroDocumentoVentaVinculada,
    this.nombreProductoVentaVinculada,
  });

  factory ItemCompraModel.fromMap(Map<String, dynamic> data) {
    return ItemCompraModel(
      idProducto: data['idProducto'] ?? '',
      idCategoria: data['idCategoria'] ?? '',
      nombreProducto: data['nombreProducto'] ?? '',
      precioCompra: (data['precioCompra'] ?? 0).toDouble(),
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      descuentoPorcentaje: (data['descuentoPorcentaje'] ?? 0).toDouble(),
      precioVentaNuevo: (data['precioVentaNuevo'] as num?)?.toDouble(),
      idPendienteReposicionVinculado: data['idPendienteReposicionVinculado'] as String?,
      numeroDocumentoVentaVinculada: data['numeroDocumentoVentaVinculada'] as String?,
      nombreProductoVentaVinculada: data['nombreProductoVentaVinculada'] as String?,
    );
  }

  factory ItemCompraModel.fromRow(Map<String, dynamic> data) {
    return ItemCompraModel(
      idProducto: data['id_producto'] ?? '',
      idCategoria: data['id_categoria'] ?? '',
      nombreProducto: data['nombre_producto'] ?? '',
      precioCompra: (data['precio_compra'] ?? 0).toDouble(),
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      descuentoPorcentaje: (data['descuento_porcentaje'] ?? 0).toDouble(),
      precioVentaNuevo: (data['precio_venta_nuevo'] as num?)?.toDouble(),
      idPendienteReposicionVinculado: data['id_pendiente_reposicion_vinculado'] as String?,
      numeroDocumentoVentaVinculada: data['numero_documento_venta_vinculada'] as String?,
      nombreProductoVentaVinculada: data['nombre_producto_venta_vinculada'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idProducto': idProducto,
      'idCategoria': idCategoria,
      'nombreProducto': nombreProducto,
      'precioCompra': precioCompra,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'descuentoPorcentaje': descuentoPorcentaje,
      'precioVentaNuevo': precioVentaNuevo,
      'idPendienteReposicionVinculado': idPendienteReposicionVinculado,
      'numeroDocumentoVentaVinculada': numeroDocumentoVentaVinculada,
      'nombreProductoVentaVinculada': nombreProductoVentaVinculada,
    };
  }

  ItemCompraModel copyWith({
    double? precioCompra,
    double? cantidad,
    double? subtotal,
    double? descuentoPorcentaje,
    double? precioVentaNuevo,
    Object? idPendienteReposicionVinculado = _sinCambio,
    Object? numeroDocumentoVentaVinculada = _sinCambio,
    Object? nombreProductoVentaVinculada = _sinCambio,
  }) {
    return ItemCompraModel(
      idProducto: idProducto,
      idCategoria: idCategoria,
      nombreProducto: nombreProducto,
      precioCompra: precioCompra ?? this.precioCompra,
      cantidad: cantidad ?? this.cantidad,
      subtotal: subtotal ?? this.subtotal,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      precioVentaNuevo: precioVentaNuevo ?? this.precioVentaNuevo,
      idPendienteReposicionVinculado: idPendienteReposicionVinculado == _sinCambio ? this.idPendienteReposicionVinculado : idPendienteReposicionVinculado as String?,
      numeroDocumentoVentaVinculada: numeroDocumentoVentaVinculada == _sinCambio ? this.numeroDocumentoVentaVinculada : numeroDocumentoVentaVinculada as String?,
      nombreProductoVentaVinculada: nombreProductoVentaVinculada == _sinCambio ? this.nombreProductoVentaVinculada : nombreProductoVentaVinculada as String?,
    );
  }
}
