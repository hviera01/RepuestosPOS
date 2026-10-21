import '../../../../core/theme/marca.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../../core/utils/busqueda_producto.dart';
import '../../../../core/widgets/filtro_vehiculo_campos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../productos/data/producto_model.dart';
import '../../../productos/providers/productos_provider.dart';
import '../../../productos/presentation/widgets/producto_form_dialog.dart';
import '../../../productos/presentation/widgets/detalle_producto_dialog.dart';
import '../../../categorias/providers/categorias_provider.dart';
import '../../../promociones/data/promocion_model.dart';
import '../../../promociones/providers/promociones_provider.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/utils/codigo_barras_utils.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/imagen_zoom_dialog.dart';
import '../../../../core/utils/mayusculas_input_formatter.dart';
import '../../../../core/widgets/campo_teclado_compacto.dart';

class ProductoConPrecio {
  final ProductoModel producto;
  final double precio;
  final int nivelPrecio;

  ProductoConPrecio({
    required this.producto,
    required this.precio,
    required this.nivelPrecio,
  });
}

class BuscarProductoDialog extends ConsumerStatefulWidget {
  final String condicion;

  final String metodoPago;
  final bool esCotizacion;
  final bool permiteSinExistencia;

  const BuscarProductoDialog({
    super.key,
    this.condicion = 'Contado',
    this.metodoPago = 'Efectivo',
    this.esCotizacion = false,
    this.permiteSinExistencia = false,
  });

  @override
  ConsumerState<BuscarProductoDialog> createState() =>
      _BuscarProductoDialogState();
}

class _BuscarProductoDialogState extends ConsumerState<BuscarProductoDialog> {
  final _busquedaController = TextEditingController();
  final _vehiculoCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  FiltroVehiculo _vehiculo = const FiltroVehiculo();
  FiltroVehiculo? _vehiculoCacheado;
  final _focusNodeLista = FocusNode();
  final _focusBusqueda = FocusNode();
  String _busquedaAplicada = '';
  bool _busquedaExacta = false;
  List<ProductoModel> _listaActual = [];
  String? _filaSeleccionada;
  int _nivelActivo = 1;
  String? _columnaOrden;
  bool _ordenAscendente = true;
  bool _verCombos = false;

  List<ProductoModel>? _productosCacheados;
  String? _busquedaFiltroCacheada;
  bool? _exactaFiltroCacheada;
  String? _columnaOrdenCacheada;
  bool? _ordenAscendenteCacheado;
  bool? _verCombosCacheado;

  final Map<int, GlobalKey> _clavesFila = {};

  bool get _esPlataformaMovil =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get _esWebMovil => kIsWeb && _esPlataformaMovil;

  @override
  void initState() {
    super.initState();
    if (_esWebMovil) {
      _columnaOrden = 'existencia';
      _ordenAscendente = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusBusqueda.requestFocus();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _focusNodeLista.dispose();
    _focusBusqueda.dispose();
    _vehiculoCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  List<ProductoModel> _filtrar(
    List<ProductoModel> productos,
    Map<String, ProductoModel> mapaProductos,
  ) {
    if (identical(productos, _productosCacheados) &&
        _busquedaFiltroCacheada == _busquedaAplicada &&
        identical(_vehiculoCacheado, _vehiculo) &&
        _exactaFiltroCacheada == _busquedaExacta &&
        _columnaOrdenCacheada == _columnaOrden &&
        _ordenAscendenteCacheado == _ordenAscendente &&
        _verCombosCacheado == _verCombos) {
      return _listaActual;
    }
    _productosCacheados = productos;
    _busquedaFiltroCacheada = _busquedaAplicada;
    _vehiculoCacheado = _vehiculo;
    _exactaFiltroCacheada = _busquedaExacta;
    _columnaOrdenCacheada = _columnaOrden;
    _ordenAscendenteCacheado = _ordenAscendente;
    _verCombosCacheado = _verCombos;
    var lista = productos
        .where(
          (p) =>
              p.estado &&
              p.esCombo == _verCombos &&
              _coincide(p, _busquedaAplicada),
        )
        .toList();
    if (!_busquedaExacta) lista = ordenarPorCodigoPrimero(lista, _busquedaAplicada);
    lista = filtrarPorVehiculo(lista, _vehiculo);
    if (_columnaOrden == 'existencia') {
      double existencia(ProductoModel p) =>
          _verCombos ? p.stockDisponibleCombo(mapaProductos) : p.stock;
      lista.sort(
        (a, b) => _ordenAscendente
            ? existencia(a).compareTo(existencia(b))
            : existencia(b).compareTo(existencia(a)),
      );
    }
    return lista;
  }

  void _moverSeleccion(int delta) {
    if (_listaActual.isEmpty) return;
    final indiceActual = _filaSeleccionada == null
        ? -1
        : _listaActual.indexWhere((p) => p.id == _filaSeleccionada);
    var nuevoIndice = indiceActual + delta;
    if (nuevoIndice < 0) nuevoIndice = 0;
    if (nuevoIndice >= _listaActual.length)
      nuevoIndice = _listaActual.length - 1;
    setState(() => _filaSeleccionada = _listaActual[nuevoIndice].id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _clavesFila[nuevoIndice]?.currentContext;
      if (contexto != null)
        Scrollable.ensureVisible(
          contexto,
          duration: const Duration(milliseconds: 120),
          alignment: 0.5,
        );
    });
  }

  KeyEventResult _manejarTeclado(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moverSeleccion(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moverSeleccion(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _seleccionarAlPresionarEnter();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _tomarFocoLista() {
    if (!_focusNodeLista.hasFocus) _focusNodeLista.requestFocus();
  }

  static const _ventanaDobleTap = Duration(milliseconds: 300);
  DateTime? _ultimoTapProductoEn;
  String? _ultimoTapProductoId;

  void _tocarFilaProducto(ProductoModel p) {
    final ahora = DateTime.now();
    final esDobleTap =
        _ultimoTapProductoId == p.id &&
        _ultimoTapProductoEn != null &&
        ahora.difference(_ultimoTapProductoEn!) < _ventanaDobleTap;
    _ultimoTapProductoEn = esDobleTap
        ? null
        : ahora;
    _ultimoTapProductoId = p.id;

    _tomarFocoLista();
    setState(() => _filaSeleccionada = p.id);
    if (esDobleTap) _confirmarSeleccion(p);
  }

  double? _precioNivel(ProductoModel p, int nivel) {
    final valor = switch (nivel) {
      2 => p.precioVenta2,
      3 => p.precioVenta3,
      _ => p.precioVenta,
    };
    return valor > 0 ? valor : null;
  }

  ({double precio, int nivel})? _precioActivo(ProductoModel p) {
    final directo = _precioNivel(p, _nivelActivo);
    if (directo != null) return (precio: directo, nivel: _nivelActivo);
    for (final nivel in [1, 2, 3]) {
      final precio = _precioNivel(p, nivel);
      if (precio != null) return (precio: precio, nivel: nivel);
    }
    return null;
  }

  bool _controlaExistencia(ProductoModel producto) {
    final categorias = ref.read(categoriasStreamProvider).value ?? [];
    final coincidencias = categorias.where((c) => c.id == producto.idCategoria).toList();
    return coincidencias.isEmpty ? true : coincidencias.first.controlaStock;
  }

  bool _cerrando = false;

  void _confirmarSeleccion(ProductoModel producto) {
    if (_cerrando) return;
    if (!producto.esCombo &&
        producto.stock <= 0 &&
        !widget.esCotizacion &&
        !widget.permiteSinExistencia &&
        _controlaExistencia(producto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${producto.nombre}" no tiene existencia disponible: no se puede agregar a la venta.')),
      );
      return;
    }
    final precio = _precioActivo(producto);
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto no tiene un precio configurado'),
        ),
      );
      return;
    }
    _cerrando = true;
    Navigator.pop(
      context,
      ProductoConPrecio(
        producto: producto,
        precio: precio.precio,
        nivelPrecio: precio.nivel,
      ),
    );
  }

  void _seleccionarAlPresionarEnter() {
    if (_listaActual.isEmpty) return;
    final resaltado = _listaActual
        .where((p) => p.id == _filaSeleccionada)
        .toList();
    _confirmarSeleccion(
      resaltado.isNotEmpty ? resaltado.first : _listaActual.first,
    );
  }

  bool _coincideExacto(ProductoModel p, String texto) => coincideCodigoProducto(p, texto);

  void _buscar({bool exacta = false}) {
    var texto = limpiarCodigoEscaneado(_busquedaController.text);
    final productos = ref.read(productosStreamProvider).value ?? [];
    if (!exacta && pareceCodigoDeBarras(texto) && productos.any((p) => p.estado && _coincideExacto(p, texto))) {
      exacta = true;
    }
    setState(() {
      _busquedaAplicada = texto;
      _vehiculo = exacta ? const FiltroVehiculo() : filtroDesdeCampos(_vehiculoCtrl, _anioCtrl);
      _filaSeleccionada = null;
      _busquedaExacta = exacta;
      _clavesFila.clear();
    });
    if (texto.isEmpty) return;
    final coincidencias = productos
        .where((p) => p.estado && _coincide(p, texto))
        .toList();
    if (coincidencias.length == 1 && exacta) {
      _confirmarSeleccion(coincidencias.first);
    }
  }

  void _buscarYElegirPrimero() {
    final texto = limpiarCodigoEscaneado(_busquedaController.text);
    if (texto.isNotEmpty && texto == _busquedaAplicada && _listaActual.isNotEmpty) {
      final resaltado = _listaActual.where((p) => p.id == _filaSeleccionada).toList();
      _confirmarSeleccion(resaltado.isNotEmpty ? resaltado.first : _listaActual.first);
      return;
    }
    _buscar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _listaActual.isEmpty || _cerrando) return;
      setState(() => _filaSeleccionada = _listaActual.first.id);
    });
  }

  bool _coincide(ProductoModel p, String texto) {
    if (_busquedaExacta) return _coincideExacto(p, texto);
    return coincideProductoEstricto(p, texto);
  }

  Future<void> _crearProductoNuevo() async {
    final nuevo = await showDialog<ProductoModel>(
      useRootNavigator: false,
      context: context,
      builder: (context) => const ProductoFormDialog(),
    );
    if (nuevo == null || !mounted) return;
    _confirmarSeleccion(nuevo);
  }

  Future<void> _editarProducto(ProductoModel p) async {
    await showDialog<ProductoModel>(
      useRootNavigator: false,
      context: context,
      builder: (context) => ProductoFormDialog(producto: p),
    );
  }

  void _verFoto(ProductoModel p) {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => ImagenZoomDialog(url: p.imagenUrl),
    );
  }

  void _verComponentes(
    ProductoModel p,
    Map<String, String> mapaCategorias,
    Map<String, ProductoModel> mapaProductos,
  ) {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => DetalleProductoDialog(
        producto: p,
        categoria: mapaCategorias[p.idCategoria] ?? '-',
        mapaProductos: mapaProductos,
      ),
    );
  }

  Future<void> _escanear() async {
    final codigo = await escanearCodigoBarras(context);
    if (codigo == null || codigo.isEmpty || !mounted) return;
    _busquedaController.text = codigo;
    if (ref.read(productosStreamProvider).value == null) {
      try {
        await ref.read(productosStreamProvider.future);
      } catch (_) {}
      if (!mounted) return;
    }
    _buscar(exacta: true);
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosStreamProvider);
    final categoriasAsync = ref.watch(categoriasStreamProvider);
    final categoriasLista = categoriasAsync.value ?? <dynamic>[];
    final mapaCategorias = {
      for (final c in categoriasLista) c.id as String: c.descripcion as String,
    };
    final promociones =
        ref.watch(promocionesStreamProvider).value ?? const <PromocionModel>[];

    final tamano = MediaQuery.of(context).size;
    final esMovil = tamano.width < 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(esMovil ? 14 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Buscar Producto',
                      style: GoogleFonts.poppins(
                        fontSize: esMovil ? 18 : 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: esMovil ? 0 : 54),
                child: Text(
                  'Enter en el buscador busca · doble clic o Enter en la lista agrega el producto resaltado',
                  style: GoogleFonts.poppins(
                    fontSize: esMovil ? 11.5 : 12.5,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: esMovil ? double.infinity : 400,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFB6BCC7)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CampoTecladoCompacto(
                              controller: _busquedaController,
                              numerico: false,
                              onSubmitted: (_) => _buscarYElegirPrimero(),
                              titulo: 'Escribí y presioná Enter para buscar...',
                              child: TextField(
                                inputFormatters: [mayusculasInputFormatter],
                                autocorrect: false,
                                enableSuggestions: false,
                                controller: _busquedaController,
                                focusNode: _focusBusqueda,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText:
                                      'Escribí y presioná Enter para buscar...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _buscarYElegirPrimero(),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Buscar',
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            onPressed: _buscar,
                          ),
                        ],
                      ),
                    ),
                  ),
                  FiltroVehiculoCampos(vehiculoCtrl: _vehiculoCtrl, anioCtrl: _anioCtrl, onBuscar: _buscar, compacto: esMovil),
                  _selectorSeccion(),
                  _selectorNivelPrecio(),
                  if (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
                    OutlinedButton.icon(
                      onPressed: _escanear,
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: Text(
                        'Escanear',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFB6BCC7)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _crearProductoNuevo,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(
                      'Producto Nuevo',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Marca.primario,
                      side: BorderSide(color: Marca.primario),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC7CBD3)),
                  ),
                  child: Focus(
                    focusNode: _focusNodeLista,
                    onKeyEvent: _manejarTeclado,
                    child: productosAsync.when(
                      data: (productos) {
                        final mapaProductos = {
                          for (final p in productos) p.id: p,
                        };
                        if (_busquedaAplicada.isEmpty && !_vehiculo.activo && !_verCombos) {
                          _listaActual = [];
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Escribí algo y presioná Enter para buscar',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final lista = _filtrar(productos, mapaProductos);
                        _listaActual = lista;
                        if (lista.isEmpty) {
                          return Center(
                            child: Text(
                              _verCombos
                                  ? 'No hay combos que coincidan'
                                  : 'No se encontraron productos',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!esMovil) ...[
                              _encabezadoTabla(),
                              const SizedBox(height: 10),
                              Divider(height: 1, color: Colors.grey.shade300),
                            ],
                            Expanded(
                              child: ListView.separated(
                                itemCount: lista.length,
                                separatorBuilder: (context, i) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                                itemBuilder: (context, i) {
                                  final p = lista[i];
                                  return esMovil
                                      ? _tarjetaMovil(
                                          i,
                                          p,
                                          mapaCategorias,
                                          promociones,
                                          mapaProductos,
                                        )
                                      : _filaTabla(
                                          i,
                                          p,
                                          mapaCategorias,
                                          promociones,
                                          mapaProductos,
                                        );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: Marca.primario,
                        ),
                      ),
                      error: (e, st) => Center(
                        child: Text(
                          'Error: $e',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorSeccion() {
    Widget opcion(String texto, bool combos) {
      final activo = _verCombos == combos;
      return InkWell(
        onTap: () {
          if (_verCombos == combos) return;
          setState(() {
            _verCombos = combos;
            _filaSeleccionada = null;
            _clavesFila.clear();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: activo ? Marca.primario : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: activo ? Colors.white : const Color(0xFF666A72),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB6BCC7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [opcion('Productos', false), opcion('Combos', true)],
      ),
    );
  }

  Widget _selectorNivelPrecio() {
    Widget opcion(String texto, int nivel) {
      final activo = _nivelActivo == nivel;
      return InkWell(
        onTap: () => setState(() => _nivelActivo = nivel),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: activo ? Marca.primario : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: activo ? Colors.white : const Color(0xFF666A72),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB6BCC7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          opcion('Precio 1', 1),
          opcion('Precio 2', 2),
          opcion('Precio 3', 3),
        ],
      ),
    );
  }

  Widget _encabezadoTabla() {
    final estilo = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 2, child: Text('Código', style: estilo)),
        Expanded(flex: 6, child: Text('Descripción', style: estilo)),
        Expanded(flex: 3, child: Text('Categoría', style: estilo)),
        Expanded(flex: 3, child: Text('Ubicación', style: estilo)),
        Expanded(
          flex: 3,
          child: Text('Precio', textAlign: TextAlign.right, style: estilo),
        ),
        Expanded(
          flex: 2,
          child: _encabezadoOrdenable('Existencia', 'existencia', estilo),
        ),
        const SizedBox(width: 80),
      ],
    );
  }

  Widget _encabezadoOrdenable(String texto, String clave, TextStyle estilo) {
    final activo = _columnaOrden == clave;
    return InkWell(
      onTap: () => setState(() {
        if (activo) {
          _ordenAscendente = !_ordenAscendente;
        } else {
          _columnaOrden = clave;
          _ordenAscendente = true;
        }
        _clavesFila.clear();
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            texto,
            style: activo
                ? estilo.copyWith(color: Marca.primario)
                : estilo,
          ),
          const SizedBox(width: 3),
          Icon(
            activo
                ? (_ordenAscendente ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
            color: activo ? Marca.primario : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget? _badgePromo(ProductoModel p, List<PromocionModel> promociones) {
    final promo = promoParaBadge(
      promociones: promociones,
      idProducto: p.id,
      condicion: widget.condicion,
      metodoPago: widget.metodoPago,
    );
    if (promo == null) return null;
    return Tooltip(
      message: promo.nombre,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Marca.primario,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_offer, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              promo.etiquetaCorta,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _celdaPrecio(ProductoModel p) {
    final precio = _precioActivo(p);
    if (precio == null) {
      return Text(
        '—',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatearMoneda(precio.precio),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B6CB0),
          ),
        ),
        if (precio.nivel != _nivelActivo)
          Text(
            'Nivel ${precio.nivel}',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _filaTabla(
    int indice,
    ProductoModel p,
    Map<String, String> mapaCategorias,
    List<PromocionModel> promociones,
    Map<String, ProductoModel> mapaProductos,
  ) {
    final existencia = p.esCombo
        ? p.stockDisponibleCombo(mapaProductos)
        : p.stock;
    final bajoStock = existencia <= 0;
    final seleccionada = _filaSeleccionada == p.id;
    return Material(
      key: _clavesFila.putIfAbsent(indice, () => GlobalKey()),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _tocarFilaProducto(p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: seleccionada ? const Color(0xFFFBEAEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: seleccionada
                ? Border.all(color: Marca.primario, width: 1.4)
                : Border.all(color: Colors.transparent, width: 1.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  p.codigo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          p.nombre,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_badgePromo(p, promociones) case final badge?) ...[
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    mapaCategorias[p.idCategoria] ?? '-',
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    p.ubicacion.isEmpty ? '-' : p.ubicacion,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _celdaPrecio(p),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bajoStock
                          ? const Color(0xFFFCE4E4)
                          : const Color(0xFFF0FBF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      existencia.toStringAsFixed(
                        existencia == existencia.roundToDouble() ? 0 : 2,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: bajoStock
                            ? Marca.primario
                            : const Color(0xFF1E9E5A),
                      ),
                    ),
                  ),
                ),
              ),
              if (p.esCombo)
                SizedBox(
                  width: 40,
                  child: IconButton(
                    tooltip: 'Ver qué incluye',
                    icon: const Icon(
                      Icons.list_alt_outlined,
                      size: 18,
                      color: Color(0xFF6A1B9A),
                    ),
                    onPressed: () =>
                        _verComponentes(p, mapaCategorias, mapaProductos),
                  ),
                ),
              SizedBox(
                width: 40,
                child: IconButton(
                  tooltip: 'Editar producto',
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () => _editarProducto(p),
                ),
              ),
              SizedBox(
                width: 40,
                child: p.imagenUrl.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Ver foto',
                        icon: Icon(
                          Icons.photo_outlined,
                          size: 18,
                          color: Marca.primario,
                        ),
                        onPressed: () => _verFoto(p),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaMovil(
    int indice,
    ProductoModel p,
    Map<String, String> mapaCategorias,
    List<PromocionModel> promociones,
    Map<String, ProductoModel> mapaProductos,
  ) {
    final existencia = p.esCombo
        ? p.stockDisponibleCombo(mapaProductos)
        : p.stock;
    final bajoStock = existencia <= 0;
    final seleccionada = _filaSeleccionada == p.id;
    return Material(
      key: _clavesFila.putIfAbsent(indice, () => GlobalKey()),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _tocarFilaProducto(p),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: seleccionada ? const Color(0xFFFBEAEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: seleccionada
                ? Border.all(color: Marca.primario, width: 1.4)
                : Border.all(color: Colors.transparent, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.nombre,
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_badgePromo(p, promociones)
                                case final badge?) ...[
                              const SizedBox(width: 8),
                              badge,
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.codigo} · ${mapaCategorias[p.idCategoria] ?? '-'}${p.ubicacion.isEmpty ? '' : ' · ${p.ubicacion}'}',
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bajoStock
                          ? const Color(0xFFFCE4E4)
                          : const Color(0xFFF0FBF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Existencia: ${existencia.toStringAsFixed(existencia == existencia.roundToDouble() ? 0 : 2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: bajoStock
                            ? Marca.primario
                            : const Color(0xFF1E9E5A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _celdaPrecio(p)),
                  if (p.imagenUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'Ver foto',
                      icon: Icon(
                        Icons.photo_outlined,
                        size: 18,
                        color: Marca.primario,
                      ),
                      onPressed: () => _verFoto(p),
                    ),
                  if (p.esCombo)
                    IconButton(
                      tooltip: 'Ver qué incluye',
                      icon: const Icon(
                        Icons.list_alt_outlined,
                        size: 18,
                        color: Color(0xFF6A1B9A),
                      ),
                      onPressed: () =>
                          _verComponentes(p, mapaCategorias, mapaProductos),
                    ),
                  IconButton(
                    tooltip: 'Editar producto',
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () => _editarProducto(p),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
