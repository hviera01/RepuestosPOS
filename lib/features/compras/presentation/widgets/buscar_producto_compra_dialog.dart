import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../../../../core/theme/marca.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/busqueda_producto.dart';
import '../../../../core/widgets/filtro_vehiculo_campos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../productos/data/producto_model.dart';
import '../../../productos/providers/productos_provider.dart';
import '../../../productos/presentation/widgets/producto_form_dialog.dart';
import '../../../categorias/providers/categorias_provider.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/widgets/imagen_zoom_dialog.dart';
import '../../../../core/utils/mayusculas_input_formatter.dart';
import '../../../../core/widgets/campo_teclado_compacto.dart';

class BuscarProductoCompraDialog extends ConsumerStatefulWidget {
  const BuscarProductoCompraDialog({super.key});

  @override
  ConsumerState<BuscarProductoCompraDialog> createState() =>
      _BuscarProductoCompraDialogState();
}

class _BuscarProductoCompraDialogState
    extends ConsumerState<BuscarProductoCompraDialog> {
  final _busquedaController = TextEditingController();
  final _vehiculoCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  FiltroVehiculo _vehiculo = const FiltroVehiculo();
  FiltroVehiculo? _vehiculoCacheado;
  final _focusNodeLista = FocusNode();
  final _focusBusqueda = FocusNode();
  String _busquedaAplicada = '';
  List<ProductoModel> _listaActual = [];
  String? _filaSeleccionada;

  List<ProductoModel>? _productosCacheados;
  String? _busquedaFiltroCacheada;

  final Map<int, GlobalKey> _clavesFila = {};

  @override
  void initState() {
    super.initState();
    _focusBusqueda.onKeyEvent = (nodo, evento) {
      if (evento is! KeyDownEvent) return KeyEventResult.ignored;
      if (evento.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moverSeleccion(1);
        return KeyEventResult.handled;
      }
      if (evento.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moverSeleccion(-1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
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

  List<ProductoModel> _filtrar(List<ProductoModel> productos) {
    if (identical(productos, _productosCacheados) &&
        identical(_vehiculoCacheado, _vehiculo) &&
        _busquedaFiltroCacheada == _busquedaAplicada) {
      return _listaActual;
    }
    _productosCacheados = productos;
    _busquedaFiltroCacheada = _busquedaAplicada;
    _vehiculoCacheado = _vehiculo;
    var lista = productos
        .where(
          (p) =>
              p.estado &&
              !p.esCombo &&
              coincideProductoEstricto(p, _busquedaAplicada),
        )
        .toList();
    lista = ordenarPorCodigoPrimero(lista, _busquedaAplicada);
    return filtrarPorVehiculo(lista, _vehiculo);
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

  bool _cerrando = false;

  void _confirmarSeleccion(ProductoModel producto) {
    if (_cerrando) return;
    _cerrando = true;
    Navigator.pop(context, producto);
  }

  void _buscarYElegirPrimero() {
    final tactil = MediaQuery.of(context).size.width < 720 ||
        MediaQuery.of(context).viewInsets.bottom > 0 ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (tactil) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _focusBusqueda.requestFocus();
    }
    final texto = _busquedaController.text.trim();
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

  void _seleccionarAlPresionarEnter() {
    if (_listaActual.isEmpty) return;
    final resaltado = _listaActual
        .where((p) => p.id == _filaSeleccionada)
        .toList();
    _confirmarSeleccion(
      resaltado.isNotEmpty ? resaltado.first : _listaActual.first,
    );
  }

  void _buscar() {
    final texto = _busquedaController.text.trim();
    setState(() {
      _busquedaAplicada = texto;
      _vehiculo = filtroDesdeCampos(_vehiculoCtrl, _anioCtrl);
      _filaSeleccionada = null;
      _clavesFila.clear();
    });
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

  void _verFoto(ProductoModel p) {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => ImagenZoomDialog(url: p.imagenUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosStreamProvider);
    final categoriasAsync = ref.watch(categoriasStreamProvider);
    final categoriasLista = categoriasAsync.value ?? <dynamic>[];
    final mapaCategorias = {
      for (final c in categoriasLista) c.id as String: c.descripcion as String,
    };

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
                                onEditingComplete: () {},
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
                  FiltroVehiculoCampos(vehiculoCtrl: _vehiculoCtrl, anioCtrl: _anioCtrl, onBuscar: _buscar),
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
                        if (_busquedaAplicada.isEmpty && !_vehiculo.activo) {
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

                        final lista = _filtrar(productos);
                        _listaActual = lista;
                        if (lista.isEmpty) {
                          return Center(
                            child: Text(
                              'No se encontraron productos',
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
                                      ? _tarjetaMovil(i, p, mapaCategorias)
                                      : _filaTabla(i, p, mapaCategorias);
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
          child: Text('Costo', textAlign: TextAlign.right, style: estilo),
        ),
        Expanded(
          flex: 2,
          child: Text('Existencia', textAlign: TextAlign.center, style: estilo),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _filaTabla(
    int indice,
    ProductoModel p,
    Map<String, String> mapaCategorias,
  ) {
    final seleccionada = _filaSeleccionada == p.id;
    return Material(
      key: _clavesFila.putIfAbsent(indice, () => GlobalKey()),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _tomarFocoLista();
          setState(() => _filaSeleccionada = p.id);
        },
        onDoubleTap: () => _confirmarSeleccion(p),
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
                  child: Text(
                    p.nombre,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
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
                child: Text(
                  formatearMoneda(p.precioCompra),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B6CB0),
                  ),
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
                      color: const Color(0xFFF0FBF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.stock.toStringAsFixed(
                        p.stock == p.stock.roundToDouble() ? 0 : 2,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E9E5A),
                      ),
                    ),
                  ),
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
  ) {
    final seleccionada = _filaSeleccionada == p.id;
    return Material(
      key: _clavesFila.putIfAbsent(indice, () => GlobalKey()),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _tomarFocoLista();
          setState(() => _filaSeleccionada = p.id);
        },
        onDoubleTap: () => _confirmarSeleccion(p),
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
                        Text(
                          p.nombre,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                      color: const Color(0xFFF0FBF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Existencia: ${p.stock.toStringAsFixed(p.stock == p.stock.roundToDouble() ? 0 : 2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E9E5A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatearMoneda(p.precioCompra),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2B6CB0),
                      ),
                    ),
                  ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
