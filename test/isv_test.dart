import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/features/productos/data/producto_model.dart';
import 'package:repuestos_pos/features/ventas/providers/carrito_provider.dart';

ProductoModel prod(double precio) => ProductoModel(
      id: 'p1',
      codigo: 'C1',
      codigoBarras: '',
      nombre: 'DISCO',
      descripcion: '',
      idCategoria: '',
      stock: 10,
      precioCompra: 50,
      precioVenta: precio,
      precioVenta2: 0,
      precioVenta3: 0,
      estado: true,
    );

void main() {
  test('en factura el precio del inventario es el final y el ISV solo se desglosa', () {
    final c = ProviderContainer();
    final n = c.read(carritoVentaProvider.notifier);
    n.establecerTipoDocumento('Factura');
    n.agregarProductoDirecto(prod(115));
    n.actualizarLinea(0, cantidad: 2);
    final s = c.read(carritoVentaProvider);
    expect(s.totalAPagar, 230);
    expect(s.subtotal, 200);
    expect(s.impuesto, 30);
  });

  test('en venta simple no hay ISV y el total es el precio', () {
    final c = ProviderContainer();
    final n = c.read(carritoVentaProvider.notifier);
    n.establecerTipoDocumento('VentaSinFacturar');
    n.agregarProductoDirecto(prod(115));
    final s = c.read(carritoVentaProvider);
    expect(s.totalAPagar, 115);
    expect(s.impuesto, 0);
  });

  test('cambiar de tipo no cambia el total a pagar', () {
    final c = ProviderContainer();
    final n = c.read(carritoVentaProvider.notifier);
    n.establecerTipoDocumento('VentaSinFacturar');
    n.agregarProductoDirecto(prod(1450));
    n.agregarProductoDirecto(prod(680));
    final antes = c.read(carritoVentaProvider).totalAPagar;
    n.establecerTipoDocumento('Factura');
    final f = c.read(carritoVentaProvider);
    expect(f.totalAPagar, antes);
    expect(f.impuesto, closeTo(antes - antes / 1.15, 0.02));
    n.establecerTipoDocumento('VentaSinFacturar');
    expect(c.read(carritoVentaProvider).totalAPagar, antes);
  });

  test('descuento de linea y global se aplican sobre el precio final', () {
    final c = ProviderContainer();
    final n = c.read(carritoVentaProvider.notifier);
    n.establecerTipoDocumento('Factura');
    n.agregarProductoDirecto(prod(1000));
    n.actualizarLinea(0, descuentoPorcentaje: 10);
    final s = c.read(carritoVentaProvider);
    expect(s.totalAPagar, 900);
  });
}
