import '../../../core/data/operaciones_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import '../../../core/data/consulta_paginada.dart';
import 'compatibilidad_model.dart';
import 'producto_model.dart';
import 'producto_import_service.dart';
import 'historial_stock_model.dart';
import 'historial_precio_compra_model.dart';
import 'historial_venta_producto_model.dart';

class ResumenImportacionProductos {
  final int creados;
  final int actualizados;
  final int categoriasCreadas;

  ResumenImportacionProductos({required this.creados, required this.actualizados, required this.categoriasCreadas});
}

class ProductoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static final TablaSincronizada<ProductoModel> _tabla = TablaSincronizada<ProductoModel>(
    tabla: 'productos',
    desdeFila: (f) => ProductoModel.fromMap(f['id'] as String, f),
    orden: (a, b) => a.nombre.compareTo(b.nombre),
  );

  Stream<List<ProductoModel>> obtenerProductos() => _tabla.observar();

  Future<void> sincronizarAhora() => _tabla.sincronizar();

  Exception _traducirDuplicado(PostgrestException e) {
    if (e.code == '23505') return Exception('Ya existe un producto con ese código');
    return Exception(e.message);
  }

  String _generarCodigo() {
    final ahora = DateTime.now().millisecondsSinceEpoch.toString();
    return 'PROD-${ahora.substring(ahora.length - 8)}';
  }

  String _generarCodigoBarras() {
    final ahora = DateTime.now().microsecondsSinceEpoch.toString();
    final cuerpo = '20${ahora.substring(ahora.length - 10)}';
    var suma = 0;
    for (var i = 0; i < cuerpo.length; i++) {
      final digito = int.parse(cuerpo[i]);
      suma += (i % 2 == 0) ? digito : digito * 3;
    }
    final verificador = (10 - (suma % 10)) % 10;
    return '$cuerpo$verificador';
  }

  Future<ProductoModel> crear({
    required String codigo,
    required String codigoBarras,
    required String nombre,
    required String descripcion,
    String ubicacion = '',
    required String idCategoria,
    required double stock,
    required double precioCompra,
    required double precioVenta,
    required double precioVenta2,
    required double precioVenta3,
    required bool estado,
    String imagenUrl = '',
    bool esCombo = false,
    List<ComponenteProductoModel> componentes = const [],
    String nombreBase = '',
    bool nombreAutomatico = false,
    List<CompatibilidadModel> compatibilidad = const [],
  }) {
    return conRedExito('Producto creado correctamente', () async {
      var codigoFinal = codigo.trim();
      if (codigoFinal.isEmpty) {
        codigoFinal = _generarCodigo();
      } else if (_tabla.actual.any((p) => p.codigo.toLowerCase() == codigoFinal.toLowerCase())) {
        throw Exception('Ya existe un producto con ese código');
      }
      final codigoBarrasFinal = codigoBarras.trim().isEmpty ? _generarCodigoBarras() : codigoBarras.trim();
      final Map<String, dynamic> fila;
      try {
        fila = await _db.from('productos').insert({
        'codigo': codigoFinal,
        'codigo_barras': codigoBarrasFinal,
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'ubicacion': ubicacion.trim(),
        'id_categoria': idCategoria.isEmpty ? null : idCategoria,
        'stock': stock,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'precio_venta2': precioVenta2,
        'precio_venta3': precioVenta3,
        'estado': estado,
        'imagen_url': imagenUrl,
        'es_combo': esCombo,
        'componentes': componentes.map((c) => c.toMap()).toList(),
        'nombre_base': nombreBase.trim(),
        'nombre_automatico': nombreAutomatico,
        'compatibilidad': compatibilidad.map((c) => c.toMap()).toList(),
      }).select().single();
      } on PostgrestException catch (e) {
        throw _traducirDuplicado(e);
      }
      final id = fila['id'] as String;
      _tabla.aplicarLocal(fila);

      if (stock > 0) {
        await _db.from('producto_lotes_costo').insert({
          'id_producto': id,
          'cantidad_original': stock,
          'cantidad_restante': stock,
          'costo_unitario': precioCompra,
          'fecha': DateTime.now().toIso8601String(),
          'origen': 'inicial',
        });
      }
      return ProductoModel(
        id: id,
        codigo: codigoFinal,
        codigoBarras: codigoBarrasFinal,
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        ubicacion: ubicacion.trim(),
        idCategoria: idCategoria,
        stock: stock,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        precioVenta2: precioVenta2,
        precioVenta3: precioVenta3,
        estado: estado,
        imagenUrl: imagenUrl,
        esCombo: esCombo,
        componentes: componentes,
        nombreBase: nombreBase.trim(),
        nombreAutomatico: nombreAutomatico,
        compatibilidad: compatibilidad,
      );
    });
  }

  Future<void> actualizar({
    required String id,
    required String codigo,
    required String codigoBarras,
    required String nombre,
    required String descripcion,
    String ubicacion = '',
    required String idCategoria,
    required double precioCompra,
    required double precioVenta,
    required double precioVenta2,
    required double precioVenta3,
    required bool estado,
    String imagenUrl = '',
    bool? esCombo,
    List<ComponenteProductoModel>? componentes,
    String? nombreBase,
    bool? nombreAutomatico,
    List<CompatibilidadModel>? compatibilidad,
  }) {
    return conRedExito('Producto actualizado correctamente', () async {
      final codigoFinal = codigo.trim().isEmpty ? _generarCodigo() : codigo.trim();
      if (_tabla.actual.any((p) => p.id != id && p.codigo.toLowerCase() == codigoFinal.toLowerCase())) {
        throw Exception('Ya existe un producto con ese código');
      }
      final datos = <String, dynamic>{
        'codigo': codigoFinal,
        'codigo_barras': codigoBarras.trim(),
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'id_categoria': idCategoria.isEmpty ? null : idCategoria,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'precio_venta2': precioVenta2,
        'precio_venta3': precioVenta3,
        'estado': estado,
        'imagen_url': imagenUrl,
      };
      if (esCombo != null) datos['es_combo'] = esCombo;
      if (componentes != null) datos['componentes'] = componentes.map((c) => c.toMap()).toList();
      if (nombreBase != null) datos['nombre_base'] = nombreBase.trim();
      if (nombreAutomatico != null) datos['nombre_automatico'] = nombreAutomatico;
      if (compatibilidad != null) datos['compatibilidad'] = compatibilidad.map((c) => c.toMap()).toList();
      _tabla.aplicarLocal({'id': id, ...datos});
      try {
        final fila = await _db.from('productos').update(datos).eq('id', id).select().single();
        _tabla.aplicarLocal(fila);
      } on PostgrestException catch (e) {
        unawaited(_tabla.sincronizar());
        throw _traducirDuplicado(e);
      }
    });
  }

  Future<void> eliminar(String id) {
    return conRedExito('Producto eliminado correctamente', () async {
      await _db.from('productos').delete().eq('id', id);
      _tabla.quitarLocal(id);
    });
  }

  Future<ResumenImportacionProductos> importarProductos(List<FilaImportacionProducto> filas) {
    return conRedExito('Productos importados correctamente', () async {
      final productosExistentes = await _db.from('productos').select('id, codigo, es_combo');
      final idPorCodigo = <String, String>{};
      for (final d in productosExistentes) {
        if (d['es_combo'] == true) continue;
        final codigo = (d['codigo'] as String? ?? '').trim().toLowerCase();
        if (codigo.isNotEmpty) idPorCodigo[codigo] = d['id'] as String;
      }

      final categoriasExistentes = await _db.from('categorias').select('id, descripcion');
      final idCategoriaPorNombre = <String, String>{};
      for (final d in categoriasExistentes) {
        final descripcion = (d['descripcion'] as String? ?? '').trim().toLowerCase();
        if (descripcion.isNotEmpty) idCategoriaPorNombre[descripcion] = d['id'] as String;
      }

      var creados = 0, actualizados = 0, categoriasCreadas = 0;
      final categoriasNuevas = <Map<String, dynamic>>[];
      final productosActualizar = <Map<String, dynamic>>[];
      final productosCrear = <Map<String, dynamic>>[];

      for (final fila in filas) {
        final nombreCategoriaNorm = fila.categoria.trim().toLowerCase();
        var idCategoria = idCategoriaPorNombre[nombreCategoriaNorm];
        if (idCategoria == null) {
          idCategoria = 'nueva:$nombreCategoriaNorm';
          if (!idCategoriaPorNombre.containsValue(idCategoria)) {
            categoriasNuevas.add({'descripcion': fila.categoria.trim(), 'estado': true});
            idCategoriaPorNombre[nombreCategoriaNorm] = idCategoria;
            categoriasCreadas++;
          }
        }

        final codigoNorm = fila.codigo.trim().toLowerCase();
        final idExistente = codigoNorm.isEmpty ? null : idPorCodigo[codigoNorm];

        final datosComunes = {
          'nombre': fila.nombre.trim(),
          'descripcion': fila.descripcion.trim(),
          'stock': fila.stock,
          'precio_compra': fila.precioCompra,
          'precio_venta': fila.precioVenta,
          'estado': fila.estado,
        };

        if (idExistente != null) {
          productosActualizar.add({'id': idExistente, 'id_categoria_clave': idCategoria, ...datosComunes, 'codigo': fila.codigo.trim()});
          actualizados++;
        } else {
          productosCrear.add({'id_categoria_clave': idCategoria, ...datosComunes, 'codigo': fila.codigo.trim(), 'codigo_barras': '', 'precio_venta2': 0.0, 'precio_venta3': 0.0});
          creados++;
        }
      }

      final idRealPorClave = <String, String>{};
      if (categoriasNuevas.isNotEmpty) {
        final insertadas = await _db.from('categorias').insert(categoriasNuevas).select('id, descripcion');
        for (final c in insertadas) {
          final clave = 'nueva:${(c['descripcion'] as String).trim().toLowerCase()}';
          idRealPorClave[clave] = c['id'] as String;
        }
      }
      String resolverCategoria(String clave) => idRealPorClave[clave] ?? clave;

      for (final p in productosActualizar) {
        final id = p.remove('id') as String;
        final claveCategoria = p.remove('id_categoria_clave') as String;
        await _db.from('productos').update({...p, 'id_categoria': resolverCategoria(claveCategoria)}).eq('id', id);
      }
      if (productosCrear.isNotEmpty) {
        final filasInsertar = productosCrear.map((p) {
          final claveCategoria = p.remove('id_categoria_clave') as String;
          return {...p, 'id_categoria': resolverCategoria(claveCategoria)};
        }).toList();
        await _db.from('productos').insert(filasInsertar);
      }

      return ResumenImportacionProductos(creados: creados, actualizados: actualizados, categoriasCreadas: categoriasCreadas);
    });
  }

  Future<void> registrarIngreso({
    required String id,
    required double cantidad,
    required double costoUnitario,
    required String usuario,
    String motivo = '',
  }) {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    return conRedExito('Ingreso de existencias registrado', () => OperacionesService.instancia.rpc('registrar_ingreso_stock', {
          'payload': {'id': id, 'cantidad': cantidad, 'costoUnitario': costoUnitario, 'usuario': usuario, 'motivo': motivo},
        }));
  }

  Future<void> registrarSalida({
    required String id,
    required double cantidad,
    String? idLote,
    required String usuario,
    String motivo = '',
  }) {
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    return conRedExito('Salida de existencias registrada', () => OperacionesService.instancia.rpc('registrar_salida_stock', {
          'payload': {'id': id, 'cantidad': cantidad, 'idLote': idLote, 'usuario': usuario, 'motivo': motivo},
        }));
  }

  Future<bool> descontarStock({
    required String id,
    required double cantidad,
    required String usuario,
    required String motivo,
  }) async {
    try {
      await OperacionesService.instancia.rpc('descontar_stock', {
        'payload': {'id': id, 'cantidad': cantidad, 'usuario': usuario, 'motivo': motivo},
      }).timeout(const Duration(seconds: 12));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<HistorialStockModel>> obtenerHistorialStock(String idProducto) {
    return conRed(() async {
      final filas = await traerTodo(() => _db.from('producto_historial_stock').select().eq('id_producto', idProducto).order('fecha', ascending: false).order('id'));
      return filas.map((d) => HistorialStockModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Stream<List<HistorialStockModel>> observarHistorialStock(String idProducto) {
    return conRedStream(() => _db
        .from('producto_historial_stock')
        .stream(primaryKey: ['id'])
        .eq('id_producto', idProducto)
        .map((filas) {
      final lista = filas.map((d) => HistorialStockModel.fromMap(d['id'] as String, d)).toList();
      lista.sort((a, b) => (b.fecha ?? DateTime(2000)).compareTo(a.fecha ?? DateTime(2000)));
      return lista;
    }));
  }

  Future<List<HistorialPrecioCompraModel>> obtenerHistorialPreciosCompra(String idProducto) {
    return conRed(() async {
      final filas = await traerTodo(() => _db.from('producto_historial_precios_compra').select().eq('id_producto', idProducto).order('fecha').order('id'));
      return filas.map((d) => HistorialPrecioCompraModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Future<List<HistorialVentaProductoModel>> obtenerHistorialVentas(String idProducto) {
    return conRed(() async {
      final filas = await traerTodo(() => _db.from('producto_historial_ventas').select().eq('id_producto', idProducto).order('fecha').order('id'));
      return filas.map((d) => HistorialVentaProductoModel.fromMap(d['id'] as String, d)).toList();
    });
  }
}
