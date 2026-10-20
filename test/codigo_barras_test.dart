import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/core/utils/codigo_barras_utils.dart';
import 'package:repuestos_pos/features/productos/data/producto_model.dart';

ProductoModel p(String id, String codigo, String barras, {bool activo = true}) => ProductoModel(
      id: id,
      codigo: codigo,
      codigoBarras: barras,
      nombre: 'P$id',
      descripcion: '',
      idCategoria: '',
      stock: 1,
      precioCompra: 1,
      precioVenta: 2,
      precioVenta2: 0,
      precioVenta3: 0,
      estado: activo,
    );

void main() {
  final lista = [
    p('1', 'PF-2210', '7501031311309'),
    p('2', 'DF-1042', '0012345678905'),
    p('3', 'AM-3301', '2012345678901'),
    p('4', 'BU-0001', '123456789012'),
    p('5', 'XX-1', '4006381333931', activo: false),
    p('6', 'AC-77', '5449000000996'),
  ];
  List<String> ids(String s, {bool activos = true}) =>
      buscarProductosPorCodigoEscaneado(lista, s, soloActivos: activos).map((e) => e.id).toList();

  test('limpia saltos de linea, tabulaciones y caracteres invisibles', () {
    expect(ids('\r\n7501031311309\r\n'), ['1']);
    expect(ids('​7501031311309\t'), ['1']);
    expect(ids('\u001D7501031311309'), ['1']);
  });

  test('prefijos de simbologia y asteriscos de Code 39', () {
    expect(ids(']E07501031311309'), ['1']);
    expect(ids('*PF-2210*'), ['1']);
  });

  test('mayusculas, guiones y espacios no importan', () {
    expect(ids('pf-2210'), ['1']);
    expect(ids('PF2210'), ['1']);
    expect(ids('pf 2210'), ['1']);
  });

  test('UPC-A contra EAN-13 con cero adelante y al reves', () {
    expect(ids('012345678905'), ['2']);
    expect(ids('0123456789012'), ['4']);
    expect(ids('123456789012'), ['4']);
  });

  test('con o sin digito verificador', () {
    expect(ids('750103131130'), ['1']);
    expect(ids('544900000099'), ['6']);
    expect(ids('5449000000996'), ['6']);
  });

  test('codigo leido al reves', () {
    expect(ids('9031131301057'), ['1']);
  });

  test('productos inactivos solo si se pide', () {
    expect(ids('4006381333931'), isEmpty);
    expect(ids('4006381333931', activos: false), ['5']);
  });

  test('coincidencia exacta gana sobre las aproximadas', () {
    final dos = [p('a', 'X', '123456789012'), p('b', 'Y', '0123456789012')];
    expect(buscarProductosPorCodigoEscaneado(dos, '123456789012').map((e) => e.id).toList(), ['a']);
  });

  test('deteccion de texto que parece codigo de barras', () {
    expect(pareceCodigoDeBarras('7501031311309'), isTrue);
    expect(pareceCodigoDeBarras('PF-2210'), isFalse);
    expect(pareceCodigoDeBarras('disco freno'), isFalse);
  });
}
