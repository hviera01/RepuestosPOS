import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/compra_en_espera_model.dart';
import '../data/compra_model.dart';
import '../data/item_compra_model.dart';
import '../../productos/data/producto_model.dart';
import '../../productos/data/pendiente_reposicion_model.dart';
import '../../../core/utils/formato_moneda.dart';

class CompraParaCargarNotifier extends Notifier<CompraModel?> {
  @override
  CompraModel? build() => null;

  void establecer(CompraModel compra) => state = compra;
  void limpiar() => state = null;
}

final compraParaCargarProvider = NotifierProvider<CompraParaCargarNotifier, CompraModel?>(CompraParaCargarNotifier.new);

double _subtotalLinea(double precioCompra, double cantidad, double descuentoPorcentaje) {
  return redondearMoneda(precioCompra * cantidad * (1 - descuentoPorcentaje / 100));
}

class CarritoCompraState {
  final String? idEnEspera;
  final List<ItemCompraModel> items;
  final String idProveedor;
  final String documentoProveedor;
  final String razonSocial;
  final String noFactura;
  final String condicion;
  final String metodoPago;
  final DateTime fecha;
  final DateTime? fechaVencimiento;
  final double descuentoGlobalPorcentaje;
  final double isvPorcentaje;
  final double ajusteManual;

  CarritoCompraState({
    this.idEnEspera,
    this.items = const [],
    this.idProveedor = '',
    this.documentoProveedor = '',
    this.razonSocial = '',
    this.noFactura = '',
    this.condicion = 'Contado',
    this.metodoPago = 'Efectivo',
    DateTime? fecha,
    this.fechaVencimiento,
    this.descuentoGlobalPorcentaje = 0,
    this.isvPorcentaje = 15,
    this.ajusteManual = 0,
  }) : fecha = fecha ?? DateTime.now();

  bool get esCredito => condicion == 'Credito';

  double get _subtotalLineasSinDescuentoGlobal => items.fold<double>(0, (s, i) => s + i.subtotal);

  double get subtotal => redondearMoneda(_subtotalLineasSinDescuentoGlobal * (1 - descuentoGlobalPorcentaje / 100));

  double get descuentoTotalMonto => redondearMoneda(_subtotalLineasSinDescuentoGlobal - subtotal);

  double get descuentoLineasMonto {
    final bruto = items.fold<double>(0, (s, i) => s + redondearMoneda(i.precioCompra * i.cantidad));
    final neto = items.fold<double>(0, (s, i) => s + i.subtotal);
    return redondearMoneda(bruto - neto);
  }

  double get impuesto => redondearMoneda(subtotal * isvPorcentaje / 100);

  double get totalAPagar => redondearMoneda(subtotal + impuesto + ajusteManual);

  double get cantidadTotalProductos => items.fold<double>(0, (s, i) => s + i.cantidad);

  CarritoCompraState copyWith({
    Object? idEnEspera = _sinCambio,
    List<ItemCompraModel>? items,
    String? idProveedor,
    String? documentoProveedor,
    String? razonSocial,
    String? noFactura,
    String? condicion,
    String? metodoPago,
    DateTime? fecha,
    Object? fechaVencimiento = _sinCambio,
    double? descuentoGlobalPorcentaje,
    double? isvPorcentaje,
    double? ajusteManual,
  }) {
    return CarritoCompraState(
      idEnEspera: idEnEspera == _sinCambio ? this.idEnEspera : idEnEspera as String?,
      items: items ?? this.items,
      idProveedor: idProveedor ?? this.idProveedor,
      documentoProveedor: documentoProveedor ?? this.documentoProveedor,
      razonSocial: razonSocial ?? this.razonSocial,
      noFactura: noFactura ?? this.noFactura,
      condicion: condicion ?? this.condicion,
      metodoPago: metodoPago ?? this.metodoPago,
      fecha: fecha ?? this.fecha,
      fechaVencimiento: fechaVencimiento == _sinCambio ? this.fechaVencimiento : fechaVencimiento as DateTime?,
      descuentoGlobalPorcentaje: descuentoGlobalPorcentaje ?? this.descuentoGlobalPorcentaje,
      isvPorcentaje: isvPorcentaje ?? this.isvPorcentaje,
      ajusteManual: ajusteManual ?? this.ajusteManual,
    );
  }
}

const _sinCambio = Object();

class CarritoCompraNotifier extends Notifier<CarritoCompraState> {
  @override
  CarritoCompraState build() => CarritoCompraState();

  void agregarProductoDirecto(ProductoModel producto) {
    final precioCompra = state.isvPorcentaje > 0
        ? redondearMoneda(producto.precioCompra / (1 + state.isvPorcentaje / 100))
        : producto.precioCompra;
    final item = ItemCompraModel(
      idProducto: producto.id,
      idCategoria: producto.idCategoria,
      nombreProducto: producto.nombre,
      precioCompra: precioCompra,
      cantidad: 1,
      subtotal: _subtotalLinea(precioCompra, 1, 0),
      precioVentaNuevo: producto.precioVenta,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void quitarItem(int index) {
    final nuevos = [...state.items]..removeAt(index);
    state = state.copyWith(items: nuevos);
  }

  void vincularPendienteReposicion(int index, PendienteReposicionModel? pendiente) {
    final nuevos = [...state.items];
    nuevos[index] = nuevos[index].copyWith(
      idPendienteReposicionVinculado: pendiente?.id,
      numeroDocumentoVentaVinculada: pendiente?.numeroDocumentoVenta,
      nombreProductoVentaVinculada: pendiente?.nombreProducto,
    );
    state = state.copyWith(items: nuevos);
  }

  void moverItem(int oldIndex, int newIndex) {
    final nuevos = [...state.items];
    final item = nuevos.removeAt(oldIndex);
    nuevos.insert(newIndex, item);
    state = state.copyWith(items: nuevos);
  }

  void actualizarLinea(int index, {double? cantidad, double? precioCompra, double? descuentoPorcentaje, double? precioVentaNuevo}) {
    final actual = state.items[index];
    final nuevaCantidad = cantidad ?? actual.cantidad;
    final nuevoPrecio = precioCompra ?? actual.precioCompra;
    final nuevoDescuento = descuentoPorcentaje ?? actual.descuentoPorcentaje;
    final nuevos = [...state.items];
    nuevos[index] = ItemCompraModel(
      idProducto: actual.idProducto,
      idCategoria: actual.idCategoria,
      nombreProducto: actual.nombreProducto,
      precioCompra: nuevoPrecio,
      cantidad: nuevaCantidad,
      subtotal: _subtotalLinea(nuevoPrecio, nuevaCantidad, nuevoDescuento),
      descuentoPorcentaje: nuevoDescuento,
      precioVentaNuevo: precioVentaNuevo ?? actual.precioVentaNuevo,
    );
    state = state.copyWith(items: nuevos);
  }

  void establecerProveedor({required String idProveedor, required String documentoProveedor, required String razonSocial}) {
    state = state.copyWith(idProveedor: idProveedor, documentoProveedor: documentoProveedor, razonSocial: razonSocial);
  }

  void establecerNoFactura(String v) => state = state.copyWith(noFactura: v);

  void establecerCondicion(String v) {
    state = state.copyWith(
      condicion: v,
      metodoPago: v == 'Credito' ? '' : 'Efectivo',
      fechaVencimiento: v == 'Credito' ? (state.fechaVencimiento ?? state.fecha.add(const Duration(days: 30))) : null,
    );
  }

  void establecerMetodoPago(String v) => state = state.copyWith(metodoPago: v);

  void establecerFecha(DateTime v) => state = state.copyWith(fecha: v, fechaVencimiento: v.add(const Duration(days: 30)));
  void establecerFechaVencimiento(DateTime v) => state = state.copyWith(fechaVencimiento: v);
  void establecerDescuentoGlobal(double v) => state = state.copyWith(descuentoGlobalPorcentaje: v);
  void establecerIsv(double v) => state = state.copyWith(isvPorcentaje: v);
  void establecerAjusteManual(double v) => state = state.copyWith(ajusteManual: v);

  void establecerIdEnEspera(String id) => state = state.copyWith(idEnEspera: id);

  void cargarSesion(CompraEnEsperaModel sesion) {
    state = CarritoCompraState(
      idEnEspera: sesion.id,
      items: sesion.items,
      idProveedor: sesion.idProveedor,
      documentoProveedor: sesion.documentoProveedor,
      razonSocial: sesion.razonSocial,
      noFactura: sesion.noFactura,
      condicion: sesion.condicion,
      metodoPago: sesion.metodoPago,
      fecha: sesion.fechaRegistro ?? DateTime.now(),
      fechaVencimiento: sesion.fechaVencimiento,
      descuentoGlobalPorcentaje: sesion.descuentoGlobalPorcentaje,
      isvPorcentaje: sesion.isvPorcentaje,
      ajusteManual: sesion.ajusteManual,
    );
  }

  void cargarDesdeCompra(CompraModel compra) {
    state = CarritoCompraState(
      idProveedor: compra.idProveedor,
      documentoProveedor: compra.documentoProveedor,
      razonSocial: compra.razonSocial,
      condicion: compra.condicion,
      metodoPago: compra.condicion == 'Credito' ? '' : (compra.metodoPago.isEmpty ? 'Efectivo' : compra.metodoPago),
      fechaVencimiento: compra.condicion == 'Credito' ? DateTime.now().add(const Duration(days: 30)) : null,
      descuentoGlobalPorcentaje: compra.descuentoGlobalPorcentaje,
      isvPorcentaje: compra.isvPorcentaje,
      items: compra.detalle
          .map((item) => ItemCompraModel(
                idProducto: item.idProducto,
                idCategoria: item.idCategoria,
                nombreProducto: item.nombreProducto,
                precioCompra: item.precioCompra,
                cantidad: item.cantidad,
                subtotal: _subtotalLinea(item.precioCompra, item.cantidad, item.descuentoPorcentaje),
                descuentoPorcentaje: item.descuentoPorcentaje,
                precioVentaNuevo: item.precioVentaNuevo,
              ))
          .toList(),
    );
  }

  void limpiar() {
    state = CarritoCompraState();
  }
}

final carritoCompraProvider = NotifierProvider<CarritoCompraNotifier, CarritoCompraState>(CarritoCompraNotifier.new);
