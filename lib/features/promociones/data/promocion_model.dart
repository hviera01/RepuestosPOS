enum TipoPromocion { porcentaje, precioFijo, comboCantidad, comboMultiproducto, regalo }

TipoPromocion tipoPromocionDesdeTexto(String? texto) {
  return TipoPromocion.values.firstWhere((t) => t.name == texto, orElse: () => TipoPromocion.porcentaje);
}

class PromocionModel {
  final String id;
  final String nombre;
  final TipoPromocion tipo;

  final List<String> idsProductos;
  final List<String> nombresProductos;

  final double valor;

  final String idProductoBase;
  final String nombreProductoBase;
  final int cantidadRequerida;

  final double precioCombo;

  final List<String> idsProductosCombo;
  final List<String> nombresProductosCombo;

  final List<String> idsProductosRegalo;
  final List<String> nombresProductosRegalo;
  final int cantidadRegalo;

  final DateTime fechaInicio;
  final DateTime? fechaFin;

  final String alcancePago;

  final List<String> metodosPagoAlcance;

  final bool activo;
  final DateTime? creadoEn;
  final String creadoPor;

  PromocionModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.idsProductos = const [],
    this.nombresProductos = const [],
    this.valor = 0,
    this.idProductoBase = '',
    this.nombreProductoBase = '',
    this.cantidadRequerida = 1,
    this.precioCombo = 0,
    this.idsProductosCombo = const [],
    this.nombresProductosCombo = const [],
    this.idsProductosRegalo = const [],
    this.nombresProductosRegalo = const [],
    this.cantidadRegalo = 1,
    required this.fechaInicio,
    this.fechaFin,
    this.alcancePago = 'Todos',
    this.metodosPagoAlcance = const [],
    this.activo = true,
    this.creadoEn,
    this.creadoPor = '',
  });

  bool get esIndefinida => fechaFin == null;
  bool get esPorcentajeOFijo => tipo == TipoPromocion.porcentaje || tipo == TipoPromocion.precioFijo;
  bool get esComboORegalo => tipo == TipoPromocion.comboCantidad || tipo == TipoPromocion.regalo;

  bool vigente(DateTime ahora) {
    if (!activo) return false;
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    if (ahora.isBefore(inicio)) return false;
    final fin = fechaFin;
    if (fin != null) {
      final finInclusive = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);
      if (ahora.isAfter(finInclusive)) return false;
    }
    return true;
  }

  bool aplicaCondicion(String condicion) {
    if (alcancePago == 'Todos') return true;
    return alcancePago == condicion;
  }

  bool aplicaMetodoPago(String metodoPago) {
    if (metodosPagoAlcance.isEmpty) return true;
    return metodosPagoAlcance.contains(metodoPago);
  }

  bool aplicaAlProducto(String idProducto) {
    if (tipo == TipoPromocion.comboMultiproducto) return idsProductosCombo.contains(idProducto);
    if (esComboORegalo) return idProductoBase == idProducto;
    return idsProductos.contains(idProducto);
  }

  String get etiquetaCorta {
    switch (tipo) {
      case TipoPromocion.porcentaje:
        return '-${valor.toStringAsFixed(valor == valor.roundToDouble() ? 0 : 1)}%';
      case TipoPromocion.precioFijo:
        return 'Precio especial';
      case TipoPromocion.comboCantidad:
        return 'Combo x$cantidadRequerida';
      case TipoPromocion.comboMultiproducto:
        return 'Combo x${idsProductosCombo.length}';
      case TipoPromocion.regalo:
        return 'Lleva $cantidadRequerida y te regalamos $cantidadRegalo';
    }
  }

  factory PromocionModel.fromMap(
    String id,
    Map<String, dynamic> data, {
    List<String> idsProductos = const [],
    List<String> nombresProductos = const [],
    List<String> idsProductosCombo = const [],
    List<String> nombresProductosCombo = const [],
    List<String> idsProductosRegalo = const [],
    List<String> nombresProductosRegalo = const [],
  }) {
    return PromocionModel(
      id: id,
      nombre: data['nombre'] ?? '',
      tipo: tipoPromocionDesdeTexto(data['tipo'] as String?),
      idsProductos: idsProductos,
      nombresProductos: nombresProductos,
      valor: (data['valor'] ?? 0).toDouble(),
      idProductoBase: data['id_producto_base'] ?? '',
      nombreProductoBase: data['nombre_producto_base'] ?? '',
      cantidadRequerida: (data['cantidad_requerida'] ?? 1).toInt(),
      precioCombo: (data['precio_combo'] ?? 0).toDouble(),
      idsProductosCombo: idsProductosCombo,
      nombresProductosCombo: nombresProductosCombo,
      idsProductosRegalo: idsProductosRegalo,
      nombresProductosRegalo: nombresProductosRegalo,
      cantidadRegalo: (data['cantidad_regalo'] ?? 1).toInt(),
      fechaInicio: data['fecha_inicio'] == null ? DateTime.now() : DateTime.parse(data['fecha_inicio'] as String),
      fechaFin: data['fecha_fin'] == null ? null : DateTime.parse(data['fecha_fin'] as String),
      alcancePago: data['alcance_pago'] ?? 'Todos',
      metodosPagoAlcance: List<String>.from(data['metodos_pago_alcance'] ?? const []),
      activo: data['activo'] ?? true,
      creadoEn: data['creado_en'] == null ? null : DateTime.parse(data['creado_en'] as String),
      creadoPor: data['creado_por'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo.name,
      'valor': valor,
      'id_producto_base': idProductoBase.isEmpty ? null : idProductoBase,
      'nombre_producto_base': nombreProductoBase,
      'cantidad_requerida': cantidadRequerida,
      'precio_combo': precioCombo,
      'cantidad_regalo': cantidadRegalo,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'alcance_pago': alcancePago,
      'metodos_pago_alcance': metodosPagoAlcance,
      'activo': activo,
      'creado_por': creadoPor,
    };
  }

  String get textoBusqueda =>
      '$nombre ${nombresProductos.join(' ')} $nombreProductoBase ${nombresProductosCombo.join(' ')} ${nombresProductosRegalo.join(' ')}';
}
