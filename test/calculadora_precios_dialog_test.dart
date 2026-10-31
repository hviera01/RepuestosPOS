import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repuestos_pos/features/categorias/data/categoria_model.dart';
import 'package:repuestos_pos/features/categorias/providers/categorias_provider.dart';
import 'package:repuestos_pos/features/productos/data/producto_model.dart';
import 'package:repuestos_pos/features/productos/presentation/widgets/calculadora_precios_dialog.dart';
import 'package:repuestos_pos/features/productos/providers/productos_provider.dart';

List<ProductoModel> _productos(int n) => List.generate(
      n,
      (i) => ProductoModel(
        id: 'p$i',
        codigo: '${100000 + i}',
        codigoBarras: '',
        nombre: 'AMORTIGUADOR DELANTERO MODELO ${i + 1}',
        descripcion: '',
        idCategoria: 'c1',
        stock: 5,
        precioCompra: 500.0 + i * 13,
        precioVenta: 900.0 + i * 20,
        precioVenta2: 0,
        precioVenta3: 0,
        estado: true,
        marca: 'MARCA',
      ),
    );

Future<void> _abrir(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productosStreamProvider.overrideWith((ref) => Stream.value(_productos(60))),
        categoriasStreamProvider.overrideWith((ref) => Stream.value(<CategoriaModel>[])),
      ],
      child: const MaterialApp(home: Scaffold(body: CalculadoraPreciosDialog())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

int _filasVisibles(WidgetTester tester) {
  final alto = tester.view.physicalSize.height;
  var n = 0;
  for (final f in tester.widgetList<Text>(find.textContaining('AMORTIGUADOR DELANTERO MODELO'))) {
    final r = tester.getRect(find.byWidget(f));
    if (r.top >= 0 && r.bottom <= alto) n++;
  }
  return n;
}

void main() {
  for (final t in [const Size(1366, 650), const Size(1366, 768), const Size(1920, 950)]) {
    testWidgets('tabla muestra varias filas en ${t.width.toInt()}x${t.height.toInt()}', (tester) async {
      await _abrir(tester, t);
      expect(tester.takeException(), isNull);
      final visibles = _filasVisibles(tester);
      // ignore: avoid_print
      print('${t.width.toInt()}x${t.height.toInt()}: $visibles filas visibles');
      expect(visibles, greaterThanOrEqualTo(6));
    });
  }

  testWidgets('ocultar fórmula deja más filas', (tester) async {
    await _abrir(tester, const Size(1366, 768));
    final antes = _filasVisibles(tester);
    await tester.tap(find.text('Ocultar fórmula'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    final despues = _filasVisibles(tester);
    // ignore: avoid_print
    print('antes $antes, despues $despues');
    expect(despues, greaterThan(antes));
    expect(find.text('Mostrar fórmula'), findsOneWidget);
    await tester.tap(find.text('Mostrar fórmula'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ocultar fórmula'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('celular 390x800 sin errores', (tester) async {
    await _abrir(tester, const Size(390, 800));
    expect(tester.takeException(), isNull);
  });
}
