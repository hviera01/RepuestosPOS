import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/core/utils/busqueda_producto.dart';
import 'package:repuestos_pos/features/productos/data/compatibilidad_model.dart';
import 'package:repuestos_pos/features/productos/data/producto_model.dart';

ProductoModel producto(String nombre, List<CompatibilidadModel> compat) => ProductoModel(
      id: nombre,
      codigo: 'C-$nombre',
      codigoBarras: '',
      nombre: nombre,
      descripcion: '',
      idCategoria: '',
      stock: 1,
      precioCompra: 1,
      precioVenta: 2,
      precioVenta2: 0,
      precioVenta3: 0,
      estado: true,
      compatibilidad: compat,
    );

void main() {
  test('nombre automatico corto con varios vehiculos', () {
    final nombre = generarNombreProducto('pastillas freno del', const [
      CompatibilidadModel(marca: 'Toyota', modelo: 'Hilux', anioDesde: 2005, anioHasta: 2015),
      CompatibilidadModel(marca: 'Toyota', modelo: 'Fortuner', anioDesde: 2009),
      CompatibilidadModel(marca: 'Nissan', modelo: 'Frontier'),
      CompatibilidadModel(marca: 'Ford', modelo: 'Ranger'),
    ]);
    expect(nombre, 'PASTILLAS FRENO DEL TOYOTA HILUX 05-15, FORTUNER 09-UP, NISSAN FRONTIER +1');
  });

  test('filtro por vehiculo y año estructurado', () {
    final hilux = producto('A', const [CompatibilidadModel(marca: 'TOYOTA', modelo: 'HILUX', anioDesde: 2005, anioHasta: 2015)]);
    final otro = producto('B', const [CompatibilidadModel(marca: 'NISSAN', modelo: 'FRONTIER', anioDesde: 2010)]);
    final sinAnio = producto('C', const [CompatibilidadModel(marca: 'TOYOTA', modelo: 'HILUX')]);
    final lista = filtrarPorVehiculo([hilux, otro, sinAnio], const FiltroVehiculo(texto: 'toyota hilux', anio: 2012));
    expect(lista.map((p) => p.id).toList(), ['A', 'C']);
    expect(filtrarPorVehiculo([hilux, otro], const FiltroVehiculo(texto: 'hilux', anio: 2020)), isEmpty);
  });

  test('producto viejo sin compatibilidad usa el año del nombre', () {
    final viejo = producto('PASTILLA FORD RANGER 06-12', const []);
    expect(filtrarPorVehiculo([viejo], const FiltroVehiculo(texto: 'ranger', anio: 2008)), hasLength(1));
    expect(filtrarPorVehiculo([viejo], const FiltroVehiculo(texto: 'ranger', anio: 2018)), isEmpty);
  });

  test('busqueda estricta exige todas las palabras', () {
    final p = producto('DISCO FRENO CIVIC', const []);
    expect(coincideProductoEstricto(p, 'disco civic'), isTrue);
    expect(coincideProductoEstricto(p, 'disco accord'), isFalse);
  });
}
