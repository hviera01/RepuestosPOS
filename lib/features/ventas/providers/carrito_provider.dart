import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/item_venta_model.dart';
import '../data/pago_detalle_model.dart';
import '../data/venta_en_espera_model.dart';
import '../data/venta_model.dart';
import '../data/registrar_venta_vista_storage.dart';
import '../../productos/data/producto_model.dart';
import '../../../core/utils/formato_moneda.dart';

class DatosVentaParaCargar {
  final VentaModel venta;
  final bool forzarFactura;

  DatosVentaParaCargar({required this.venta, this.forzarFactura = false});
}

class VentaParaCargarNotifier extends Notifier<DatosVentaParaCargar?> {
  @override
  DatosVentaParaCargar? build() => null;

  void establecer(VentaModel venta, {bool forzarFactura = false}) =>
      state = DatosVentaParaCargar(venta: venta, forzarFactura: forzarFactura);
  void limpiar() => state = null;
}

final ventaParaCargarProvider =
    NotifierProvider<VentaParaCargarNotifier, DatosVentaParaCargar?>(
      VentaParaCargarNotifier.new,
    );

double _subtotalLinea(
  double precioVenta,
  double cantidad,
  double descuentoPorcentaje,
) {
  return redondearMoneda(
    precioVenta * cantidad * (1 - descuentoPorcentaje / 100),
  );
}

String tipoDocumentoVentaPorDefecto = 'Factura';

bool tipoAplicaIsv(String tipo) => tipo == 'Factura' || tipo == 'Boleta';

List<ItemVentaModel> convertirPreciosItems(List<ItemVentaModel> items, double factor) {
  return [
    for (final i in items)
      i.copyWith(
        precioVenta: i.precioVenta * factor,
        subtotal: _subtotalLinea(i.precioVenta * factor, i.cantidad, i.descuentoPorcentaje),
      ),
  ];
}

class CarritoVentaState {
  final String? idEnEspera;
  final List<ItemVentaModel> items;
  final String tipoDocumento;
  final String condicion;
  final String metodoPago;
  final String documentoCliente;
  final String nombreCliente;
  final String? idCliente;
  final DateTime fecha;
  final DateTime? fechaVencimiento;
  final String telefonoCredito;
  final String oc;
  final String regExonerado;
  final String regSag;
  final String observaciones;
  final double pagoCon;
  final double cambio;
  final double descuentoGlobalPorcentaje;
  final List<PagoDetalle> pagosMixtos;
  final bool cotizacionConIsv;

  CarritoVentaState({
    this.idEnEspera,
    this.items = const [],
    String? tipoDocumento,
    this.condicion = 'Contado',
    this.metodoPago = 'Efectivo',
    this.documentoCliente = '',
    this.nombreCliente = '',
    this.idCliente,
    DateTime? fecha,
    this.fechaVencimiento,
    this.telefonoCredito = '',
    this.oc = '',
    this.regExonerado = '',
    this.regSag = '',
    this.observaciones = '',
    this.pagoCon = 0,
    this.cambio = 0,
    this.descuentoGlobalPorcentaje = 0,
    this.pagosMixtos = const [],
    this.cotizacionConIsv = false,
  })  : tipoDocumento = tipoDocumento ?? tipoDocumentoVentaPorDefecto,
        fecha = fecha ?? DateTime.now();

  bool get esCotizacion => tipoDocumento == 'Cotizacion';
  bool get esVentaSinFacturar => tipoDocumento == 'VentaSinFacturar';
  bool get esCredito => condicion == 'Credito';
  bool get esPagoMixto => metodoPago == 'Mixto';

  bool get _aplicaIsv =>
      tipoDocumento == 'Factura' ||
      tipoDocumento == 'Boleta' ||
      (tipoDocumento == 'Cotizacion' && cotizacionConIsv);

  bool get aplicaIsv => _aplicaIsv;

  double get factorIsv => _aplicaIsv ? 1.15 : 1.0;

  double get _subtotalLineasSinDescuentoGlobal =>
      items.fold<double>(0, (s, i) => s + i.subtotal);

  double get subtotal => redondearMoneda(
    _subtotalLineasSinDescuentoGlobal * (1 - descuentoGlobalPorcentaje / 100),
  );

  double get descuentosYRebajas {
    final listaSinDescuento = items.fold<double>(
      0,
      (s, i) => s + redondearMoneda(i.precioVenta * i.cantidad),
    );
    return redondearMoneda(listaSinDescuento - subtotal);
  }

  double get _totalConImpuestoBase {
    var total = 0.0;
    for (final i in items) {
      final precioConIsv = _aplicaIsv ? redondearMoneda(i.precioVenta * 1.15) : i.precioVenta;
      total += _subtotalLinea(precioConIsv, i.cantidad, i.descuentoPorcentaje);
    }
    total *= (1 - descuentoGlobalPorcentaje / 100);
    return redondearMoneda(total);
  }

  double get impuesto => redondearMoneda(_totalConImpuestoBase - subtotal);

  double get totalAPagar {
    final t = _totalConImpuestoBase;
    final base = t.floorToDouble();
    final resto = t - base;
    return resto >= 0.90 ? base + 1 : base;
  }

  double get cantidadTotalProductos =>
      items.fold<double>(0, (s, i) => s + i.cantidad);

  CarritoVentaState copyWith({
    Object? idEnEspera = _sinCambio,
    List<ItemVentaModel>? items,
    String? tipoDocumento,
    String? condicion,
    String? metodoPago,
    String? documentoCliente,
    String? nombreCliente,
    Object? idCliente = _sinCambio,
    DateTime? fecha,
    Object? fechaVencimiento = _sinCambio,
    String? telefonoCredito,
    String? oc,
    String? regExonerado,
    String? regSag,
    String? observaciones,
    double? pagoCon,
    double? cambio,
    double? descuentoGlobalPorcentaje,
    List<PagoDetalle>? pagosMixtos,
    bool? cotizacionConIsv,
  }) {
    return CarritoVentaState(
      idEnEspera: idEnEspera == _sinCambio
          ? this.idEnEspera
          : idEnEspera as String?,
      items: items ?? this.items,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      condicion: condicion ?? this.condicion,
      metodoPago: metodoPago ?? this.metodoPago,
      documentoCliente: documentoCliente ?? this.documentoCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      idCliente: idCliente == _sinCambio
          ? this.idCliente
          : idCliente as String?,
      fecha: fecha ?? this.fecha,
      fechaVencimiento: fechaVencimiento == _sinCambio
          ? this.fechaVencimiento
          : fechaVencimiento as DateTime?,
      telefonoCredito: telefonoCredito ?? this.telefonoCredito,
      oc: oc ?? this.oc,
      regExonerado: regExonerado ?? this.regExonerado,
      regSag: regSag ?? this.regSag,
      observaciones: observaciones ?? this.observaciones,
      pagoCon: pagoCon ?? this.pagoCon,
      cambio: cambio ?? this.cambio,
      descuentoGlobalPorcentaje:
          descuentoGlobalPorcentaje ?? this.descuentoGlobalPorcentaje,
      pagosMixtos: pagosMixtos ?? this.pagosMixtos,
      cotizacionConIsv: cotizacionConIsv ?? this.cotizacionConIsv,
    );
  }
}

const _sinCambio = Object();

class CarritoVentaNotifier extends Notifier<CarritoVentaState> {
  @override
  CarritoVentaState build() => CarritoVentaState();

  void agregarItem(ItemVentaModel item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void agregarProductoDirecto(
    ProductoModel producto, {
    double? precioSeleccionado,
    double precioCompraUsado = 0,
  }) {
    final precio = (precioSeleccionado ?? producto.precioVenta) / state.factorIsv;
    final item = ItemVentaModel(
      idProducto: producto.id,
      idCategoria: producto.idCategoria,
      nombreProducto: producto.nombre,
      precioVenta: precio,
      cantidad: 1,
      subtotal: _subtotalLinea(precio, 1, 0),
      precioCompraUsado: precioCompraUsado > 0
          ? precioCompraUsado
          : producto.precioCompra,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  int agregarOFusionarProductoDirecto(
    ProductoModel producto, {
    double? precioSeleccionado,
    double precioCompraUsado = 0,
    bool fusionarSiYaExiste = false,
  }) {
    if (fusionarSiYaExiste) {
      final idx = state.items.indexWhere(
        (i) => i.idProducto == producto.id && !i.esCombo,
      );
      if (idx != -1) {
        actualizarLinea(idx, cantidad: state.items[idx].cantidad + 1);
        return idx;
      }
    }
    agregarProductoDirecto(
      producto,
      precioSeleccionado: precioSeleccionado,
      precioCompraUsado: precioCompraUsado,
    );
    return state.items.length - 1;
  }

  void agregarComboDirecto(
    ProductoModel combo, {
    required Map<String, ProductoModel> mapaProductos,
    double? precioSeleccionado,
  }) {
    final precio = (precioSeleccionado ?? combo.precioVenta) / state.factorIsv;
    final componentesSnapshot = combo.componentes.map((c) {
      final productoComponente = mapaProductos[c.idProducto];
      return ComponenteComboSnapshot(
        idProducto: c.idProducto,
        idCategoria: productoComponente?.idCategoria ?? '',
        nombreProducto: productoComponente?.nombre ?? '',
        cantidad: c.cantidad,
        precioCompraUsado: productoComponente?.precioCompra ?? 0,
      );
    }).toList();
    final item = ItemVentaModel(
      idProducto: combo.id,
      idCategoria: combo.idCategoria,
      nombreProducto: combo.nombre,
      precioVenta: precio,
      cantidad: 1,
      subtotal: _subtotalLinea(precio, 1, 0),
      precioCompraUsado: combo.precioCompra,
      componentes: componentesSnapshot,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void quitarItem(int index) {
    final nuevos = [...state.items]..removeAt(index);
    state = state.copyWith(items: nuevos);
  }

  void moverItem(int oldIndex, int newIndex) {
    final nuevos = [...state.items];
    final item = nuevos.removeAt(oldIndex);
    nuevos.insert(newIndex, item);
    state = state.copyWith(items: nuevos);
  }

  void actualizarItem(int index, ItemVentaModel nuevo) {
    final nuevos = [...state.items];
    nuevos[index] = nuevo;
    state = state.copyWith(items: nuevos);
  }

  void actualizarLinea(
    int index, {
    double? cantidad,
    double? precioNuevo,
    double? descuentoPorcentaje,
  }) {
    final actual = state.items[index];
    final nuevaCantidad = cantidad ?? actual.cantidad;
    final nuevoPrecio = precioNuevo ?? actual.precioVenta;
    final nuevoDescuento = descuentoPorcentaje ?? actual.descuentoPorcentaje;
    final nuevos = [...state.items];
    nuevos[index] = ItemVentaModel(
      idProducto: actual.idProducto,
      idCategoria: actual.idCategoria,
      nombreProducto: actual.nombreProducto,
      precioVenta: nuevoPrecio,
      cantidad: nuevaCantidad,
      subtotal: _subtotalLinea(nuevoPrecio, nuevaCantidad, nuevoDescuento),
      precioCompraUsado: actual.precioCompraUsado,
      descuentoPorcentaje: nuevoDescuento,
      componentes: actual.componentes,
      pendienteCompra: actual.pendienteCompra,
    );
    state = state.copyWith(items: nuevos);
  }

  void marcarPendienteCompra(int index, bool valor) {
    final nuevos = [...state.items];
    nuevos[index] = nuevos[index].copyWith(pendienteCompra: valor);
    state = state.copyWith(items: nuevos);
  }

  void actualizarDescripcion(int index, String nuevaDescripcion) {
    final texto = nuevaDescripcion.trim();
    if (texto.isEmpty) return;
    final nuevos = [...state.items];
    nuevos[index] = nuevos[index].copyWith(nombreProducto: texto);
    state = state.copyWith(items: nuevos);
  }

  void establecerDescuentoGlobal(double v) =>
      state = state.copyWith(descuentoGlobalPorcentaje: v);

  void establecerTipoDocumento(String v, {bool cotizacionConIsv = false}) {
    final conIsv = v == 'Cotizacion' && cotizacionConIsv;
    final antes = state.aplicaIsv;
    final despues = tipoAplicaIsv(v) || conIsv;
    if (antes == despues) {
      state = state.copyWith(tipoDocumento: v, cotizacionConIsv: conIsv);
      return;
    }
    final factor = despues ? 1 / 1.15 : 1.15;
    state = state.copyWith(
      tipoDocumento: v,
      cotizacionConIsv: conIsv,
      items: convertirPreciosItems(state.items, factor),
    );
  }

  void establecerCondicion(String v) {
    state = state.copyWith(
      condicion: v,
      metodoPago: v == 'Credito' ? '' : 'Efectivo',
      fechaVencimiento: v == 'Credito'
          ? (state.fechaVencimiento ??
                DateTime.now().add(const Duration(days: 15)))
          : null,
      pagosMixtos: const [],
    );
  }

  void establecerMetodoPago(String v) => state = state.copyWith(
    metodoPago: v,
    pagosMixtos: v == 'Mixto' ? state.pagosMixtos : const [],
  );

  void establecerPagosMixtos(List<PagoDetalle> pagos) =>
      state = state.copyWith(pagosMixtos: pagos);

  void establecerCliente({
    required String documento,
    required String nombre,
    String? idCliente,
  }) {
    state = state.copyWith(
      documentoCliente: documento,
      nombreCliente: nombre,
      idCliente: idCliente,
    );
  }

  void establecerDocumentoCliente(String v) =>
      state = state.copyWith(documentoCliente: v, idCliente: null);

  void establecerNombreClienteManual(String v) =>
      state = state.copyWith(nombreCliente: v, idCliente: null);
  void establecerFecha(DateTime v) => state = state.copyWith(fecha: v);
  void establecerFechaVencimiento(DateTime v) =>
      state = state.copyWith(fechaVencimiento: v);
  void establecerTelefonoCredito(String v) =>
      state = state.copyWith(telefonoCredito: v);
  void establecerOc(String v) => state = state.copyWith(oc: v);
  void establecerRegExonerado(String v) =>
      state = state.copyWith(regExonerado: v);
  void establecerRegSag(String v) => state = state.copyWith(regSag: v);
  void establecerObservaciones(String v) =>
      state = state.copyWith(observaciones: v);
  void establecerPago({required double pagoCon, required double cambio}) {
    state = state.copyWith(pagoCon: pagoCon, cambio: cambio);
  }

  void establecerIdEnEspera(String id) =>
      state = state.copyWith(idEnEspera: id);

  void cargarSesion(VentaEnEsperaModel sesion) {
    state = CarritoVentaState(
      idEnEspera: sesion.id,
      items: sesion.items,
      tipoDocumento: sesion.tipoDocumento,
      condicion: sesion.condicion,
      metodoPago: sesion.metodoPago,
      documentoCliente: sesion.documentoCliente,
      nombreCliente: sesion.nombreCliente,
      idCliente: sesion.idCliente,
      fechaVencimiento: sesion.fechaVencimiento,
      oc: sesion.oc,
      regExonerado: sesion.regExonerado,
      regSag: sesion.regSag,
      observaciones: sesion.observaciones,
      descuentoGlobalPorcentaje: sesion.descuentoGlobal,
    );
  }

  void cargarDesdeVenta(VentaModel venta, {bool forzarFactura = false}) {
    final cotConIsv = venta.tipoDocumento == 'Cotizacion' && venta.impuesto > 0;
    final aFactura = forzarFactura && venta.tipoDocumento == 'Cotizacion' && !cotConIsv;
    state = CarritoVentaState(
      items: (aFactura ? convertirPreciosItems(venta.detalle, 1 / 1.15) : venta.detalle)
          .map(
            (item) => ItemVentaModel(
              idProducto: item.idProducto,
              idCategoria: item.idCategoria,
              nombreProducto: item.nombreProducto,
              precioVenta: item.precioVenta,
              cantidad: item.cantidad,
              subtotal: item.subtotal,
              precioCompraUsado: item.precioCompraUsado,
              descuentoPorcentaje: item.descuentoPorcentaje,
              componentes: item.componentes,
            ),
          )
          .toList(),
      tipoDocumento: (forzarFactura && venta.tipoDocumento == 'Cotizacion')
          ? 'Factura'
          : venta.tipoDocumento,
      cotizacionConIsv: cotConIsv && !forzarFactura,
      condicion: venta.condicion,
      metodoPago: venta.condicion == 'Credito'
          ? ''
          : (venta.metodoPago.isEmpty ? 'Efectivo' : venta.metodoPago),
      documentoCliente: venta.documentoCliente,
      nombreCliente: venta.nombreCliente,
      idCliente: venta.idCliente,
      fechaVencimiento: venta.condicion == 'Credito'
          ? DateTime.now().add(const Duration(days: 30))
          : null,
      oc: venta.oc,
      regExonerado: venta.regExonerado,
      regSag: venta.regSag,
      observaciones: venta.observaciones,
      descuentoGlobalPorcentaje: venta.descuentoGlobal,
    );
  }

  void limpiar() {
    state = CarritoVentaState();
  }
}

final carritoVentaProvider =
    NotifierProvider<CarritoVentaNotifier, CarritoVentaState>(
      CarritoVentaNotifier.new,
    );

class RegistrarVentaVistaNotifier extends Notifier<String> {
  @override
  String build() {
    obtenerVistaGuardada().then((valor) {
      if (ref.mounted && valor != state) state = valor;
    });
    return registrarVentaVistaClasica;
  }

  void elegir(String valor) {
    state = valor;
    guardarVista(valor);
  }
}

final registrarVentaVistaProvider =
    NotifierProvider<RegistrarVentaVistaNotifier, String>(
      RegistrarVentaVistaNotifier.new,
    );
