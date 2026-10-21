class PermisosEspeciales {
  static const inventarioEditarProducto = 'inventario_editar_producto';
  static const inventarioAjustarStock = 'inventario_ajustar_stock';
  static const ventasCreditoEliminar = 'ventas_credito_eliminar';
  static const ventasCambiarPrecio = 'ventas_cambiar_precio';
  static const ventasEditarDescripcion = 'ventas_editar_descripcion';
  static const ventasVenderSinStock = 'ventas_vender_sin_stock';

  static const comprasCrear = 'compras_crear';
  static const comprasEditar = 'compras_editar';
  static const comprasEliminar = 'compras_eliminar';
  static const inventarioCrearProducto = 'inventario_crear_producto';
  static const inventarioEliminarProducto = 'inventario_eliminar_producto';
  static const clientesCrear = 'clientes_crear';
  static const clientesEditar = 'clientes_editar';
  static const clientesEliminar = 'clientes_eliminar';
  static const ventasEliminar = 'ventas_eliminar';
  static const trasladosAnular = 'traslados_anular';

  static const Map<String, String> etiquetas = {
    inventarioEditarProducto: 'Editar productos en Inventario',
    inventarioAjustarStock: 'Cambiar existencias en Inventario',
    ventasCreditoEliminar: 'Eliminar créditos en Ventas a Crédito',
    ventasCambiarPrecio: 'Cambiar precio de un producto en Ventas',
    ventasEditarDescripcion: 'Editar descripción de un producto en Ventas',
    ventasVenderSinStock: 'Permitir vender un producto sin existencia (con clave)',
    comprasCrear: 'Registrar compras',
    comprasEditar: 'Editar compras',
    comprasEliminar: 'Anular compras',
    inventarioCrearProducto: 'Crear productos en Inventario',
    inventarioEliminarProducto: 'Eliminar productos en Inventario',
    clientesCrear: 'Crear clientes',
    clientesEditar: 'Editar clientes',
    clientesEliminar: 'Eliminar clientes',
    ventasEliminar: 'Anular ventas',
    trasladosAnular: 'Anular traslados',
  };

  static const Map<String, String> descripciones = {
    inventarioEditarProducto:
        'Pide la clave especial antes de guardar cambios en un producto existente.',
    inventarioAjustarStock:
        'Pide la clave especial antes de confirmar un ajuste de existencia.',
    ventasCreditoEliminar:
        'Pide la clave especial antes de eliminar un crédito.',
    ventasCambiarPrecio:
        'Pide la clave especial antes de modificar el precio unitario de un producto dentro de una venta.',
    ventasEditarDescripcion:
        'Pide la clave especial antes de cambiar la descripción de un producto dentro de una venta.',
    ventasVenderSinStock:
        'Por defecto el sistema NO deja vender un producto sin existencia: muestra un aviso y no lo agrega. Si activa esto (y hay clave especial), se podrá agregar un producto sin existencia, o vender más de lo que hay, pidiendo la clave especial.',
    comprasCrear: 'Permite registrar una nueva compra.',
    comprasEditar: 'Permite editar una compra ya registrada.',
    comprasEliminar: 'Permite anular una compra ya registrada.',
    inventarioCrearProducto: 'Permite dar de alta un producto nuevo en Inventario.',
    inventarioEliminarProducto: 'Permite eliminar un producto de Inventario.',
    clientesCrear: 'Permite dar de alta un cliente nuevo.',
    clientesEditar: 'Permite editar los datos de un cliente existente.',
    clientesEliminar: 'Permite eliminar un cliente.',
    ventasEliminar: 'Permite anular una venta ya registrada.',
    trasladosAnular: 'Permite anular un traslado ya registrado.',
  };
}

class ModoImpresion {
  static const preguntar = 'preguntar';
  static const directo = 'directo';
}

class NegocioModel {
  final String nombre;
  final String correo;
  final String rtn;
  final String cai;
  final String direccion;
  final String telefono;
  final String eslogan;
  final String rangoPrefijo;
  final String rangoDesde;
  final String rangoHasta;
  final DateTime? fechaLimiteEmision;
  final String logoColorBase64;
  final String logoBnBase64;
  final bool tieneClaveEspecial;
  final Map<String, bool> permisos;
  final String impresoraTermicaUrl;
  final String impresoraTermicaNombre;
  final String impresoraEtiquetasUrl;
  final String impresoraEtiquetasNombre;
  final bool facturaImprimirCopia;
  final bool facturaPreciosConIsv;
  final String modoImpresion;
  final String impresoraRedIp;
  final int impresoraRedPuerto;
  final String impresoraBluetoothId;
  final String impresoraBluetoothNombre;
  final int anchoTicketMm;
  final String pcPrincipalHostname;
  final bool imprimirFacturas;
  final bool impresoraUsbUsarDriverWindows;
  final Map<String, dynamic> tema;
  final String tipoDocumentoDefecto;

  const NegocioModel({
    this.nombre = '',
    this.correo = '',
    this.rtn = '',
    this.cai = '',
    this.direccion = '',
    this.telefono = '',
    this.eslogan = '',
    this.rangoPrefijo = '',
    this.rangoDesde = '',
    this.rangoHasta = '',
    this.fechaLimiteEmision,
    this.logoColorBase64 = '',
    this.logoBnBase64 = '',
    this.tieneClaveEspecial = false,
    this.permisos = const {},
    this.impresoraTermicaUrl = '',
    this.impresoraTermicaNombre = '',
    this.impresoraEtiquetasUrl = '',
    this.impresoraEtiquetasNombre = '',
    this.facturaImprimirCopia = true,
    this.facturaPreciosConIsv = false,
    this.modoImpresion = ModoImpresion.preguntar,
    this.impresoraRedIp = '',
    this.impresoraRedPuerto = 9100,
    this.impresoraBluetoothId = '',
    this.impresoraBluetoothNombre = '',
    this.anchoTicketMm = 80,
    this.pcPrincipalHostname = '',
    this.imprimirFacturas = true,
    this.impresoraUsbUsarDriverWindows = false,
    this.tema = const {},
    this.tipoDocumentoDefecto = 'Factura',
  });

  bool tienePermiso(String key) => permisos[key] == true;

  factory NegocioModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const NegocioModel();
    return NegocioModel(
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rtn: data['rtn'] ?? '',
      cai: data['cai'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      eslogan: data['eslogan'] ?? '',
      rangoPrefijo: data['rango_prefijo'] ?? '',
      rangoDesde: data['rango_desde'] ?? '',
      rangoHasta: data['rango_hasta'] ?? '',
      fechaLimiteEmision: data['fecha_limite_emision'] == null ? null : DateTime.parse(data['fecha_limite_emision'] as String),
      logoColorBase64: data['logo_color_base64'] ?? '',
      logoBnBase64: data['logo_bn_base64'] ?? '',
      tieneClaveEspecial: data['tiene_clave_especial'] ?? false,
      permisos: Map<String, bool>.from(data['permisos'] ?? {}),
      impresoraTermicaUrl: data['impresora_termica_url'] ?? '',
      impresoraTermicaNombre: data['impresora_termica_nombre'] ?? '',
      impresoraEtiquetasUrl: data['impresora_etiquetas_url'] ?? '',
      impresoraEtiquetasNombre: data['impresora_etiquetas_nombre'] ?? '',
      facturaImprimirCopia: data['factura_imprimir_copia'] ?? true,
      facturaPreciosConIsv: data['factura_precios_con_isv'] ?? false,
      modoImpresion: data['modo_impresion'] ?? ModoImpresion.preguntar,
      impresoraRedIp: data['impresora_red_ip'] ?? '',
      impresoraRedPuerto: ((data['impresora_red_puerto'] ?? 9100) as num).toInt(),
      impresoraBluetoothId: data['impresora_bluetooth_id'] ?? '',
      impresoraBluetoothNombre: data['impresora_bluetooth_nombre'] ?? '',
      anchoTicketMm: ((data['ancho_ticket_mm'] ?? 80) as num).toInt(),
      pcPrincipalHostname: data['pc_principal_hostname'] ?? '',
      imprimirFacturas: data['imprimir_facturas'] ?? true,
      impresoraUsbUsarDriverWindows:
          data['impresora_usb_usar_driver_windows'] ?? false,
      tema: Map<String, dynamic>.from((data['tema'] as Map?) ?? const {}),
      tipoDocumentoDefecto: (data['tipo_documento_defecto'] ?? 'Factura') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rtn': rtn,
      'cai': cai,
      'direccion': direccion,
      'telefono': telefono,
      'eslogan': eslogan,
      'rango_prefijo': rangoPrefijo,
      'rango_desde': rangoDesde,
      'rango_hasta': rangoHasta,
      'fecha_limite_emision': fechaLimiteEmision?.toIso8601String(),
      'logo_color_base64': logoColorBase64,
      'logo_bn_base64': logoBnBase64,
      'permisos': permisos,
      'impresora_termica_url': impresoraTermicaUrl,
      'impresora_termica_nombre': impresoraTermicaNombre,
      'impresora_etiquetas_url': impresoraEtiquetasUrl,
      'impresora_etiquetas_nombre': impresoraEtiquetasNombre,
      'factura_imprimir_copia': facturaImprimirCopia,
      'factura_precios_con_isv': facturaPreciosConIsv,
      'modo_impresion': modoImpresion,
      'impresora_red_ip': impresoraRedIp,
      'impresora_red_puerto': impresoraRedPuerto,
      'impresora_bluetooth_id': impresoraBluetoothId,
      'impresora_bluetooth_nombre': impresoraBluetoothNombre,
      'ancho_ticket_mm': anchoTicketMm,
      'pc_principal_hostname': pcPrincipalHostname,
      'imprimir_facturas': imprimirFacturas,
      'impresora_usb_usar_driver_windows': impresoraUsbUsarDriverWindows,
      'tema': tema,
      'tipo_documento_defecto': tipoDocumentoDefecto,
    };
  }

  NegocioModel copyWith({
    String? nombre,
    String? correo,
    String? rtn,
    String? cai,
    String? direccion,
    String? telefono,
    String? eslogan,
    String? rangoPrefijo,
    String? rangoDesde,
    String? rangoHasta,
    DateTime? fechaLimiteEmision,
    String? logoColorBase64,
    String? logoBnBase64,
    bool? tieneClaveEspecial,
    Map<String, bool>? permisos,
    String? impresoraTermicaUrl,
    String? impresoraTermicaNombre,
    String? impresoraEtiquetasUrl,
    String? impresoraEtiquetasNombre,
    bool? facturaImprimirCopia,
    bool? facturaPreciosConIsv,
    String? modoImpresion,
    String? impresoraRedIp,
    int? impresoraRedPuerto,
    String? impresoraBluetoothId,
    String? impresoraBluetoothNombre,
    int? anchoTicketMm,
    String? pcPrincipalHostname,
    bool? imprimirFacturas,
    bool? impresoraUsbUsarDriverWindows,
    Map<String, dynamic>? tema,
    String? tipoDocumentoDefecto,
  }) {
    return NegocioModel(
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rtn: rtn ?? this.rtn,
      cai: cai ?? this.cai,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      eslogan: eslogan ?? this.eslogan,
      rangoPrefijo: rangoPrefijo ?? this.rangoPrefijo,
      rangoDesde: rangoDesde ?? this.rangoDesde,
      rangoHasta: rangoHasta ?? this.rangoHasta,
      fechaLimiteEmision: fechaLimiteEmision ?? this.fechaLimiteEmision,
      logoColorBase64: logoColorBase64 ?? this.logoColorBase64,
      logoBnBase64: logoBnBase64 ?? this.logoBnBase64,
      tieneClaveEspecial: tieneClaveEspecial ?? this.tieneClaveEspecial,
      permisos: permisos ?? this.permisos,
      impresoraTermicaUrl: impresoraTermicaUrl ?? this.impresoraTermicaUrl,
      impresoraTermicaNombre:
          impresoraTermicaNombre ?? this.impresoraTermicaNombre,
      impresoraEtiquetasUrl:
          impresoraEtiquetasUrl ?? this.impresoraEtiquetasUrl,
      impresoraEtiquetasNombre:
          impresoraEtiquetasNombre ?? this.impresoraEtiquetasNombre,
      facturaImprimirCopia: facturaImprimirCopia ?? this.facturaImprimirCopia,
      facturaPreciosConIsv: facturaPreciosConIsv ?? this.facturaPreciosConIsv,
      modoImpresion: modoImpresion ?? this.modoImpresion,
      impresoraRedIp: impresoraRedIp ?? this.impresoraRedIp,
      impresoraRedPuerto: impresoraRedPuerto ?? this.impresoraRedPuerto,
      impresoraBluetoothId: impresoraBluetoothId ?? this.impresoraBluetoothId,
      impresoraBluetoothNombre:
          impresoraBluetoothNombre ?? this.impresoraBluetoothNombre,
      anchoTicketMm: anchoTicketMm ?? this.anchoTicketMm,
      pcPrincipalHostname: pcPrincipalHostname ?? this.pcPrincipalHostname,
      imprimirFacturas: imprimirFacturas ?? this.imprimirFacturas,
      impresoraUsbUsarDriverWindows:
          impresoraUsbUsarDriverWindows ?? this.impresoraUsbUsarDriverWindows,
      tema: tema ?? this.tema,
      tipoDocumentoDefecto: tipoDocumentoDefecto ?? this.tipoDocumentoDefecto,
    );
  }
}
