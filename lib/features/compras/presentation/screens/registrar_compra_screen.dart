import '../../../../core/theme/marca.dart';
import '../../../negocio/data/negocio_model.dart';
import '../../../../core/utils/permisos_usuario.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/compra_en_espera_model.dart';
import '../../providers/carrito_compra_provider.dart';
import '../../providers/compras_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../productos/data/producto_model.dart';
import '../../../productos/data/pendiente_reposicion_model.dart';
import '../../../productos/providers/productos_provider.dart';
import '../../data/item_compra_model.dart';
import '../widgets/vincular_pendiente_dialog.dart';
import '../../../proveedores/data/proveedor_model.dart';
import '../../../proveedores/providers/proveedores_provider.dart';
import '../../../../core/providers/tabs_provider.dart';
import '../../../../core/utils/codigo_barras_utils.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/exito_transaccion_overlay.dart';
import '../../../ventas/presentation/widgets/teclado_numerico_dialog.dart';
import '../widgets/buscar_producto_compra_dialog.dart';
import '../widgets/compras_en_espera_dialog.dart';
import 'detalle_compra_screen.dart';
import '../../../../core/utils/mayusculas_input_formatter.dart';
import '../../../../core/widgets/campo_teclado_compacto.dart';

const _metodosPago = ['Efectivo', 'Transferencia', 'Tarjeta', 'Cheque'];

class RegistrarCompraScreen extends ConsumerStatefulWidget {
  final String? tabId;

  const RegistrarCompraScreen({super.key, this.tabId});

  @override
  ConsumerState<RegistrarCompraScreen> createState() =>
      _RegistrarCompraScreenState();
}

class _RegistrarCompraScreenState extends ConsumerState<RegistrarCompraScreen> {
  final _noFacturaController = TextEditingController();
  final _descuentoGlobalController = TextEditingController();
  final _isvController = TextEditingController(text: '15');
  final _ajusteManualController = TextEditingController();
  bool _datosExpandidos = false;
  bool _guardando = false;

  final Map<int, TextEditingController> _ctrlCantidad = {};
  final Map<int, TextEditingController> _ctrlPrecio = {};
  final Map<int, TextEditingController> _ctrlDescuento = {};
  final Map<int, TextEditingController> _ctrlMargen = {};
  final Map<int, TextEditingController> _ctrlPrecioVenta = {};
  final Map<String, FocusNode> _focusInline = {};
  final Map<String, VoidCallback> _confirmarInline = {};
  int _conteoItemsControladores = -1;

  final _ctrlCodigoBarras = TextEditingController();
  final _focusCodigoBarras = FocusNode();
  final _bufferEscanerFisico = StringBuffer();
  DateTime? _ultimaTeclaEscanerFisico;
  static const _intervaloMaximoEscanerFisico = Duration(milliseconds: 45);

  bool get _esPlataformaMovil =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get _esWebMovil => kIsWeb && _esPlataformaMovil;

  final _focusAnclaMovil = FocusNode(debugLabel: 'ancla_teclado_web_movil');

  bool _pausarLectorFisico = false;

  bool _tablaExpandida = false;
  void Function(void Function())? _refrescarDialogoExpandido;

  Timer? _debounceEnEspera;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_manejarAtajoTeclado);

    final compraOrigen = ref.read(compraParaCargarProvider);
    if (compraOrigen != null) {
      ref.read(compraParaCargarProvider.notifier).limpiar();
      ref.read(carritoCompraProvider.notifier).cargarDesdeCompra(compraOrigen);
      _descuentoGlobalController.text =
          compraOrigen.descuentoGlobalPorcentaje == 0
          ? ''
          : compraOrigen.descuentoGlobalPorcentaje.toStringAsFixed(1);
      _isvController.text = compraOrigen.isvPorcentaje.toStringAsFixed(0);
    }

    if (!_esPlataformaMovil) {
      FocusManager.instance.addListener(_alCambiarFocoGlobal);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alCambiarFocoGlobal(),
      );
    }
  }

  void _alCambiarFocoGlobal() {
    if (!mounted || _esPlataformaMovil) return;
    if (!_esPestanaActiva()) return;
    if (_pausarLectorFisico) return;
    if (FocusManager.instance.primaryFocus == null) {
      _focusCodigoBarras.requestFocus();
    }
  }

  bool _manejarAtajoTeclado(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.f10 ||
        event.logicalKey == LogicalKeyboardKey.f12) {
      if (event is KeyDownEvent &&
          mounted &&
          !_guardando &&
          _esPestanaActiva() &&
          !_pausarLectorFisico) {
        if (event.logicalKey == LogicalKeyboardKey.f10) {
          _agregarProductoDesdeBusqueda();
        } else {
          _confirmarCompra();
        }
      }
      return true;
    }
    if (event is! KeyDownEvent) return false;
    if (!mounted || _guardando) return false;
    if (!_esPestanaActiva()) return false;
    if (_pausarLectorFisico) return false;
    return _detectarEscaneoFisico(event);
  }

  bool _detectarEscaneoFisico(KeyEvent event) {
    final ahora = DateTime.now();
    final ultimaTecla = _ultimaTeclaEscanerFisico;
    final llegoRapido =
        ultimaTecla != null &&
        ahora.difference(ultimaTecla) < _intervaloMaximoEscanerFisico;
    _ultimaTeclaEscanerFisico = ahora;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final codigo = _bufferEscanerFisico.toString();
      _bufferEscanerFisico.clear();
      if (llegoRapido && codigo.length >= 3) {
        _ctrlCodigoBarras.clear();
        _procesarCodigoEscaneado(codigo);
        return true;
      }
      return false;
    }

    final caracter = event.character;
    if (caracter == null || caracter.isEmpty) return false;

    if (llegoRapido) {
      _bufferEscanerFisico.write(caracter);
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _bufferEscanerFisico
        ..clear()
        ..write(caracter);
    }
    return false;
  }

  bool _esPestanaActiva() {
    final tabId = widget.tabId;
    if (tabId == null) return true;
    final tabsState = ref.read(tabsProvider);
    if (tabsState.indiceActivo < 0 ||
        tabsState.indiceActivo >= tabsState.tabs.length)
      return false;
    return tabsState.tabs[tabsState.indiceActivo].id == tabId;
  }

  @override
  void dispose() {
    _debounceEnEspera?.cancel();
    HardwareKeyboard.instance.removeHandler(_manejarAtajoTeclado);
    if (!_esPlataformaMovil) {
      FocusManager.instance.removeListener(_alCambiarFocoGlobal);
    }
    _ctrlCodigoBarras.dispose();
    _focusCodigoBarras.dispose();
    _focusAnclaMovil.dispose();
    _noFacturaController.dispose();
    _descuentoGlobalController.dispose();
    _isvController.dispose();
    _ajusteManualController.dispose();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecio.values) {
      c.dispose();
    }
    for (final c in _ctrlDescuento.values) {
      c.dispose();
    }
    for (final c in _ctrlMargen.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecioVenta.values) {
      c.dispose();
    }
    for (final f in _focusInline.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<bool> _confirmarDialogo(String titulo, String mensaje) async {
    final resultado = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(mensaje, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Marca.primario,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }


  Future<void> _agregarProductoDesdeBusqueda() async {
    _pausarLectorFisico = true;
    try {
      final producto = await Navigator.of(context).push<ProductoModel>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const BuscarProductoCompraDialog(),
        ),
      );
      if (producto == null || !mounted) return;
      ref.read(carritoCompraProvider.notifier).agregarProductoDirecto(producto);
    } finally {
      _pausarLectorFisico = false;
    }
  }

  Widget _campoCodigoBarras() {
    return CampoTecladoCompacto(
      controller: _ctrlCodigoBarras,
      numerico: false,
      onSubmitted: (_) => _confirmarCodigoBarras(),
      child: TextField(
        inputFormatters: [mayusculasInputFormatter],
        autocorrect: false,
        enableSuggestions: false,
        controller: _ctrlCodigoBarras,
        focusNode: _focusCodigoBarras,
        onSubmitted: (_) => _confirmarCodigoBarras(),
      ),
    );
  }

  Future<void> _confirmarCodigoBarras() async {
    final codigo = _ctrlCodigoBarras.text.trim();
    _ctrlCodigoBarras.clear();
    if (codigo.isEmpty) return;
    await _procesarCodigoEscaneado(codigo);
    if (mounted) _focusCodigoBarras.requestFocus();
  }

  Future<void> _escanearConCamara() async {
    final codigo = await escanearCodigoBarras(context);
    if (codigo == null || codigo.isEmpty || !mounted) return;
    await _procesarCodigoEscaneado(codigo);
  }

  Future<void> _procesarCodigoEscaneado(String codigo) async {
    if (!mounted) return;
    final texto = codigo.trim();
    if (ref.read(productosStreamProvider).value == null) {
      try {
        await ref.read(productosStreamProvider.future);
      } catch (_) {}
      if (!mounted) return;
    }
    final productos = ref.read(productosStreamProvider).value ?? [];
    final coincidencias = buscarProductosPorCodigoEscaneado(productos, texto);
    if (coincidencias.isEmpty) {
      _mostrarMensaje('Código escaneado no encontrado: $texto');
      return;
    }
    ref
        .read(carritoCompraProvider.notifier)
        .agregarProductoDirecto(coincidencias.first);
  }

  void _quitarItem(int index) {
    ref.read(carritoCompraProvider.notifier).quitarItem(index);
  }

  Future<void> _abrirVincularPendiente(int index) async {
    final item = ref.read(carritoCompraProvider).items[index];
    final pendientes = ref.read(pendientesReposicionStreamProvider).value ?? [];
    final resultado = await showDialog<Object?>(
      useRootNavigator: false,
      context: context,
      builder: (context) => VincularPendienteDialog(
        pendientes: pendientes,
        idVinculadoActual: item.idPendienteReposicionVinculado,
      ),
    );
    if (resultado == null) return;
    if (identical(resultado, quitarVinculoPendiente)) {
      ref
          .read(carritoCompraProvider.notifier)
          .vincularPendienteReposicion(index, null);
    } else if (resultado is PendienteReposicionModel) {
      ref
          .read(carritoCompraProvider.notifier)
          .vincularPendienteReposicion(index, resultado);
    }
  }

  Widget _botonVincularPendiente(int index, ItemCompraModel item) {
    final vinculado = item.idPendienteReposicionVinculado != null;
    return SizedBox(
      width: 32,
      child: IconButton(
        tooltip: vinculado
            ? 'Repone la venta ${item.numeroDocumentoVentaVinculada} (${item.nombreProductoVentaVinculada}). Tocá para cambiar o quitar.'
            : 'Vincular a una venta anticipada (si esta compra repone un producto distinto al que se facturó)',
        icon: Icon(
          Icons.link,
          size: 18,
          color: vinculado ? const Color(0xFF16A34A) : Colors.grey.shade400,
        ),
        onPressed: () => _abrirVincularPendiente(index),
      ),
    );
  }

  Widget _chipVinculoPendiente(ItemCompraModel item) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, size: 13, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Repone venta ${item.numeroDocumentoVentaVinculada}: ${item.nombreProductoVentaVinculada}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _moverItem(int index, int nuevoIndex) {
    ref.read(carritoCompraProvider.notifier).moverItem(index, nuevoIndex);
    _conteoItemsControladores = -1;
  }

  Widget _botonOrdenIcono(IconData icono, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Icon(
          icono,
          size: 16,
          color: onPressed == null
              ? Colors.grey.shade300
              : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _botonesOrden(int index, int total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botonOrdenIcono(
          Icons.keyboard_arrow_up,
          index == 0 ? null : () => _moverItem(index, index - 1),
        ),
        _botonOrdenIcono(
          Icons.keyboard_arrow_down,
          index == total - 1 ? null : () => _moverItem(index, index + 1),
        ),
      ],
    );
  }

  void _actualizarCantidad(int index, double nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor a 0');
      return;
    }
    ref
        .read(carritoCompraProvider.notifier)
        .actualizarLinea(index, cantidad: nuevaCantidad);
  }

  void _actualizarPrecio(int index, double nuevoPrecio) {
    if (nuevoPrecio < 0) {
      _mostrarMensaje('Precio inválido');
      return;
    }
    ref
        .read(carritoCompraProvider.notifier)
        .actualizarLinea(index, precioCompra: nuevoPrecio);
    _sincronizarMargenControlador(index);
  }

  void _actualizarDescuentoLinea(int index, double descuento) {
    if (descuento < 0 || descuento > 100) {
      _mostrarMensaje('El descuento debe estar entre 0 y 100');
      return;
    }
    ref
        .read(carritoCompraProvider.notifier)
        .actualizarLinea(index, descuentoPorcentaje: descuento);
    _sincronizarMargenControlador(index);
  }

  double _costoFinalItem(dynamic item) {
    final isv = ref.read(carritoCompraProvider).isvPorcentaje;
    return redondearMoneda(
      (item.precioCompra as double) *
          (1 - (item.descuentoPorcentaje as double) / 100) *
          (1 + isv / 100),
    );
  }

  double _precioVentaFinal(dynamic item) =>
      redondearMoneda((item.precioVentaNuevo as double?) ?? 0);

  String get _etiquetaPrecioVenta => 'Precio de venta (c/ISV)';

  double _margenActual(dynamic item) {
    final costo = _costoFinalItem(item);
    final precioFinal = _precioVentaFinal(item);
    return costo > 0 ? ((precioFinal - costo) / costo * 100) : 0.0;
  }

  (TextEditingController, TextEditingController) _controladoresMargen(
    int index,
    dynamic item,
  ) {
    final ctrlMargen = _ctrlMargen.putIfAbsent(
      index,
      () => TextEditingController(text: _margenActual(item).toStringAsFixed(1)),
    );
    final ctrlPrecioVenta = _ctrlPrecioVenta.putIfAbsent(
      index,
      () => TextEditingController(
        text: _precioVentaFinal(item).toStringAsFixed(2),
      ),
    );
    return (ctrlMargen, ctrlPrecioVenta);
  }

  void _actualizarPrecioVentaCompra(int index, double nuevoPrecioVentaFinal) {
    if (nuevoPrecioVentaFinal < 0) {
      _mostrarMensaje('Precio inválido');
      return;
    }
    ref
        .read(carritoCompraProvider.notifier)
        .actualizarLinea(
          index,
          precioVentaNuevo: redondearMoneda(nuevoPrecioVentaFinal),
        );
    _sincronizarMargenControlador(index);
  }

  void _actualizarMargenCompra(int index, double nuevoMargen) {
    final carrito = ref.read(carritoCompraProvider);
    if (index >= carrito.items.length) return;
    final costo = _costoFinalItem(carrito.items[index]);
    final nuevoPrecioFinal = redondearMoneda(costo * (1 + nuevoMargen / 100));
    ref
        .read(carritoCompraProvider.notifier)
        .actualizarLinea(index, precioVentaNuevo: nuevoPrecioFinal);
    _ctrlPrecioVenta[index]?.text = nuevoPrecioFinal.toStringAsFixed(2);
  }

  void _sincronizarMargenControlador(int index) {
    final carrito = ref.read(carritoCompraProvider);
    if (index >= carrito.items.length) return;
    final item = carrito.items[index];
    final costo = _costoFinalItem(item);
    final precioFinal = _precioVentaFinal(item);
    final margen = costo > 0 ? ((precioFinal - costo) / costo * 100) : 0.0;
    _ctrlMargen[index]?.text = margen.toStringAsFixed(1);
  }

  double _descuentoLineaMonto(dynamic item) {
    final sinDescuento = redondearMoneda(
      (item.precioCompra as double) * (item.cantidad as double),
    );
    return redondearMoneda(sinDescuento - (item.subtotal as double));
  }

  double _importeBrutoItem(dynamic item) => redondearMoneda(
    (item.precioCompra as double) * (item.cantidad as double),
  );


  void _limpiarTodo() {
    ref.read(carritoCompraProvider.notifier).limpiar();
    _noFacturaController.clear();
    _descuentoGlobalController.clear();
    _isvController.text = '15';
    _ajusteManualController.clear();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecio.values) {
      c.dispose();
    }
    for (final c in _ctrlDescuento.values) {
      c.dispose();
    }
    for (final c in _ctrlMargen.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecioVenta.values) {
      c.dispose();
    }
    _ctrlCantidad.clear();
    _ctrlPrecio.clear();
    _ctrlDescuento.clear();
    _ctrlMargen.clear();
    _ctrlPrecioVenta.clear();
    _conteoItemsControladores = 0;
  }

  Future<void> _confirmarLimpiar() async {
    final carrito = ref.read(carritoCompraProvider);
    final hayAlgoQuePerder =
        carrito.items.isNotEmpty || carrito.razonSocial.isNotEmpty;
    if (hayAlgoQuePerder) {
      final continuar = await _confirmarDialogo(
        'Limpiar compra',
        '¿Seguro que querés borrar todos los productos y datos ingresados en esta compra?',
      );
      if (!continuar) return;
    }
    _debounceEnEspera?.cancel();
    if (carrito.idEnEspera != null) {
      unawaited(
        ref
            .read(compraRepositoryProvider)
            .eliminarCompraEnEspera(carrito.idEnEspera!),
      );
    }
    _limpiarTodo();
  }


  void _programarAutoguardado(CarritoCompraState carrito) {
    _debounceEnEspera?.cancel();
    if (carrito.items.isEmpty) return;
    _debounceEnEspera = Timer(
      const Duration(seconds: 2),
      _guardarEnEsperaAutomatico,
    );
  }

  Future<void> _guardarEnEsperaAutomatico() async {
    if (!mounted) return;
    final carrito = ref.read(carritoCompraProvider);
    if (carrito.items.isEmpty) return;
    final repo = ref.read(compraRepositoryProvider);
    final sesion = CompraEnEsperaModel(
      id: carrito.idEnEspera ?? '',
      fecha: DateTime.now(),
      idProveedor: carrito.idProveedor,
      documentoProveedor: carrito.documentoProveedor,
      razonSocial: carrito.razonSocial,
      noFactura: carrito.noFactura,
      condicion: carrito.condicion,
      metodoPago: carrito.metodoPago,
      fechaRegistro: carrito.fecha,
      fechaVencimiento: carrito.fechaVencimiento,
      descuentoGlobalPorcentaje: carrito.descuentoGlobalPorcentaje,
      isvPorcentaje: carrito.isvPorcentaje,
      ajusteManual: carrito.ajusteManual,
      items: carrito.items,
    );
    try {
      if (carrito.idEnEspera != null) {
        await repo.actualizarCompraEnEspera(carrito.idEnEspera!, sesion);
      } else {
        final id = await repo.guardarCompraEnEspera(sesion);
        if (!mounted) return;
        ref.read(carritoCompraProvider.notifier).establecerIdEnEspera(id);
      }
    } catch (_) {
    }
  }

  Future<void> _verEnEspera() async {
    final sesion = await showDialog<CompraEnEsperaModel>(
      useRootNavigator: false,
      context: context,
      builder: (context) => const ComprasEnEsperaDialog(),
    );
    if (sesion == null || !mounted) return;
    ref.read(carritoCompraProvider.notifier).cargarSesion(sesion);
    _noFacturaController.text = sesion.noFactura;
    _descuentoGlobalController.text = sesion.descuentoGlobalPorcentaje == 0
        ? ''
        : sesion.descuentoGlobalPorcentaje.toStringAsFixed(1);
    _isvController.text = sesion.isvPorcentaje.toStringAsFixed(0);
    _ajusteManualController.text = sesion.ajusteManual == 0
        ? ''
        : sesion.ajusteManual.toStringAsFixed(2);
  }


  Future<void> _confirmarCompra() async {
    final carrito = ref.read(carritoCompraProvider);
    if (carrito.items.isEmpty) {
      _mostrarMensaje('Debe ingresar productos en la compra');
      return;
    }
    if (carrito.idProveedor.isEmpty) {
      _mostrarMensaje('Seleccioná un proveedor');
      return;
    }
    if (carrito.esCredito && carrito.fechaVencimiento == null) {
      _mostrarMensaje('Definí la fecha de vencimiento del crédito');
      return;
    }

    setState(() => _guardando = true);
    try {
      final usuario = ref.read(authProvider).usuario?.nombreCompleto ?? '';
      final compra = await ref
          .read(compraRepositoryProvider)
          .registrarCompra(
            noFactura: _noFacturaController.text.trim(),
            idProveedor: carrito.idProveedor,
            documentoProveedor: carrito.documentoProveedor,
            razonSocial: carrito.razonSocial,
            condicion: carrito.condicion,
            metodoPago: carrito.esCredito ? 'N/A' : carrito.metodoPago,
            fechaRegistro: carrito.fecha,
            fechaVencimiento: carrito.esCredito
                ? carrito.fechaVencimiento
                : null,
            descuentoGlobalPorcentaje: carrito.descuentoGlobalPorcentaje,
            descuentoTotalMonto: carrito.descuentoTotalMonto,
            isvPorcentaje: carrito.isvPorcentaje,
            ajusteManual: carrito.ajusteManual,
            items: carrito.items,
            subtotal: carrito.subtotal,
            impuesto: carrito.impuesto,
            totalAPagar: carrito.totalAPagar,
            usuario: usuario,
          );

      if (!mounted) return;
      if (carrito.idEnEspera != null) {
        unawaited(
          ref
              .read(compraRepositoryProvider)
              .eliminarCompraEnEspera(carrito.idEnEspera!),
        );
      }
      _debounceEnEspera?.cancel();
      _limpiarTodo();
      _mostrarMensaje('Compra registrada: ${compra.numeroDocumento}');
      mostrarExitoTransaccion(context);
    } catch (e) {
      _mostrarMensaje(
        e is TimeoutException
            ? 'No se pudo guardar: se agotó el tiempo de espera. Revisá la conexión a internet e intentá de nuevo.'
            : 'Error al registrar: $e',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoCompraProvider);
    ref.listen<CarritoCompraState>(
      carritoCompraProvider,
      (previous, next) => _programarAutoguardado(next),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refrescarDialogoExpandido?.call(() {}),
    );

    return Focus(
      focusNode: _focusAnclaMovil,
      canRequestFocus: true,
      skipTraversal: true,
      child: Container(
        color: const Color(0xFFF2F3F7),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 900;
            final altoTabla = (constraints.maxHeight * 0.58).clamp(
              360.0,
              1000.0,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(esMovil ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezado(esMovil),
                  const SizedBox(height: 14),
                  _tarjetaDatosCompra(carrito, esMovil),
                  const SizedBox(height: 14),
                  esMovil
                      ? _tarjetaCarritoGrande(carrito, esMovil)
                      : SizedBox(
                          height: altoTabla,
                          child: _tarjetaCarritoGrande(carrito, esMovil),
                        ),
                  const SizedBox(height: 14),
                  _tarjetaTotales(carrito, esMovil),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _encabezado(bool esMovil) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Text(
          'Registrar Compra',
          style: GoogleFonts.poppins(
            fontSize: esMovil ? 19 : 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _confirmarLimpiar,
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: Text(
            'Limpiar Compra',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          onPressed: _verDetalleCompra,
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: Text('Ver Detalle', style: GoogleFonts.poppins(fontSize: 13)),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          onPressed: _verEnEspera,
          icon: const Icon(Icons.pause_circle_outline, size: 18),
          label: Text(
            'Compras en Espera',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          style: _estiloBotonSecundario(),
        ),
      ],
    );
  }

  void _verDetalleCompra() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const DetalleCompraScreen(),
      ),
    );
  }

  ButtonStyle _estiloBotonSecundario() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A1A1A),
      side: const BorderSide(color: Color(0xFFB6BCC7)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _tarjeta({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7CBD3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _decoracion(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(fontSize: 12.5),
      hintStyle: GoogleFonts.poppins(
        fontSize: 11.5,
        color: Colors.grey.shade400,
      ),
      filled: true,
      fillColor: const Color(0xFFE8EAF0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _tarjetaDatosCompra(CarritoCompraState carrito, bool esMovil) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final proveedoresAsync = ref.watch(proveedoresStreamProvider);

    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: esMovil ? double.infinity : 160,
                child: InkWell(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: carrito.fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (fecha != null)
                      ref
                          .read(carritoCompraProvider.notifier)
                          .establecerFecha(fecha);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            formatoFecha.format(carrito.fecha),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 260,
                child: proveedoresAsync.when(
                  data: (proveedores) {
                    final actual = proveedores
                        .where((p) => p.id == carrito.idProveedor)
                        .toList();
                    return DropdownButtonFormField<ProveedorModel>(
                      initialValue: actual.isNotEmpty ? actual.first : null,
                      isExpanded: true,
                      decoration: _decoracion('Proveedor'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1A1A1A),
                      ),
                      items: proveedores
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.razonSocial,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        ref
                            .read(carritoCompraProvider.notifier)
                            .establecerProveedor(
                              idProveedor: v.id,
                              documentoProveedor: v.rtn,
                              razonSocial: v.razonSocial,
                            );
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => Text(
                    'Error cargando proveedores',
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 180,
                child: CampoTecladoCompacto(
                  controller: _noFacturaController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _noFacturaController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('No. Factura'),
                    onChanged: (v) => ref
                        .read(carritoCompraProvider.notifier)
                        .establecerNoFactura(v),
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 150,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('cond-${carrito.condicion}'),
                  initialValue: carrito.condicion,
                  isExpanded: true,
                  decoration: _decoracion('Condición'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A1A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Contado', child: Text('Contado')),
                    DropdownMenuItem(value: 'Credito', child: Text('Crédito')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(carritoCompraProvider.notifier)
                        .establecerCondicion(v);
                  },
                ),
              ),
              if (carrito.condicion == 'Credito')
                SizedBox(
                  width: esMovil ? double.infinity : 160,
                  child: InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate:
                            carrito.fechaVencimiento ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null)
                        ref
                            .read(carritoCompraProvider.notifier)
                            .establecerFechaVencimiento(fecha);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Vence: ${carrito.fechaVencimiento != null ? formatoFecha.format(carrito.fechaVencimiento!) : 'Sin definir'}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: esMovil ? double.infinity : 160,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('met-${carrito.metodoPago}'),
                    initialValue: _metodosPago.contains(carrito.metodoPago)
                        ? carrito.metodoPago
                        : null,
                    isExpanded: true,
                    decoration: _decoracion('Método de pago'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1A1A1A),
                    ),
                    items: _metodosPago
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      ref
                          .read(carritoCompraProvider.notifier)
                          .establecerMetodoPago(v);
                    },
                  ),
                ),
              InkWell(
                onTap: () =>
                    setState(() => _datosExpandidos = !_datosExpandidos),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _datosExpandidos ? 'Ver menos' : 'Más datos',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Marca.primario,
                        ),
                      ),
                      Icon(
                        _datosExpandidos
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: Marca.primario,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: !_datosExpandidos
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 14),
                        Text(
                          'Descuento global, ISV y ajuste manual',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: esMovil ? double.infinity : 220,
                              child: CampoTecladoCompacto(
                                controller: _descuentoGlobalController,
                                numerico: true,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  controller: _descuentoGlobalController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion(
                                    'Descuento global (%)',
                                  ),
                                  onChanged: (v) {
                                    final valor = double.tryParse(
                                      v.replaceAll(',', '').trim(),
                                    );
                                    if (valor == null ||
                                        valor < 0 ||
                                        valor > 100)
                                      return;
                                    ref
                                        .read(carritoCompraProvider.notifier)
                                        .establecerDescuentoGlobal(valor);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: esMovil ? double.infinity : 160,
                              child: CampoTecladoCompacto(
                                controller: _isvController,
                                numerico: true,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  controller: _isvController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion('ISV (%)'),
                                  onChanged: (v) {
                                    final valor = double.tryParse(
                                      v.replaceAll(',', '').trim(),
                                    );
                                    if (valor == null || valor < 0) return;
                                    ref
                                        .read(carritoCompraProvider.notifier)
                                        .establecerIsv(valor);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: esMovil ? double.infinity : 260,
                              child: CampoTecladoCompacto(
                                controller: _ajusteManualController,
                                numerico: true,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  controller: _ajusteManualController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion(
                                    'Ajuste manual (+/-)',
                                    hint:
                                        'Para cuadrar centavos con la factura',
                                  ),
                                  onChanged: (v) {
                                    final valor = double.tryParse(
                                      v.replaceAll(',', '').trim(),
                                    );
                                    ref
                                        .read(carritoCompraProvider.notifier)
                                        .establecerAjusteManual(valor ?? 0);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaCarritoGrande(CarritoCompraState carrito, bool esMovil) {
    final productos = ref.watch(productosStreamProvider).value ?? [];
    final mapaProductos = {for (final p in productos) p.id: p};

    if (carrito.items.length != _conteoItemsControladores) {
      for (final c in _ctrlCantidad.values) {
        c.dispose();
      }
      for (final c in _ctrlPrecio.values) {
        c.dispose();
      }
      for (final c in _ctrlDescuento.values) {
        c.dispose();
      }
      for (final c in _ctrlMargen.values) {
        c.dispose();
      }
      for (final c in _ctrlPrecioVenta.values) {
        c.dispose();
      }
      _ctrlCantidad.clear();
      _ctrlPrecio.clear();
      _ctrlDescuento.clear();
      _ctrlMargen.clear();
      _ctrlPrecioVenta.clear();
      for (final f in _focusInline.values) {
        f.dispose();
      }
      _focusInline.clear();
      _confirmarInline.clear();
      _conteoItemsControladores = carrito.items.length;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7CBD3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          esMovil
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos en la compra',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _agregarProductoDesdeBusqueda,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              'Agregar Producto',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Marca.primario,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_esPlataformaMovil) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _escanearConCamara,
                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                            label: Text(
                              'Escanear',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A1A1A),
                              side: const BorderSide(color: Color(0xFFB6BCC7)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'Productos en la compra',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Ver la tabla más grande',
                      onPressed: _expandirTablaProductos,
                      icon: const Icon(Icons.open_in_full, size: 18),
                      color: Colors.grey.shade600,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _agregarProductoDesdeBusqueda,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Agregar Producto',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Marca.primario,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
          Offstage(offstage: true, child: _campoCodigoBarras()),
          const SizedBox(height: 14),
          if (!esMovil) ...[
            _encabezadoTablaCarrito(),
            Divider(height: 18, color: Colors.grey.shade300),
          ],
          if (carrito.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Todavía no agregaste productos.\nUsá "Agregar Producto" para buscar del inventario.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade500),
                ),
              ),
            )
          else if (esMovil)
            Column(
              children: [
                for (var i = 0; i < carrito.items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                  _filaCarritoMovil(
                    i,
                    carrito.items[i],
                    mapaProductos,
                    carrito.items.length,
                  ),
                ],
              ],
            )
          else if (_tablaExpandida)
            Expanded(
              child: Center(
                child: Text(
                  'Viendo la tabla ampliada…',
                  style: GoogleFonts.poppins(color: Colors.grey.shade400),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: carrito.items.length,
                separatorBuilder: (context, i) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, i) => _filaCarritoTabla(
                  i,
                  carrito.items[i],
                  mapaProductos,
                  carrito.items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _expandirTablaProductos() {
    setState(() => _tablaExpandida = true);
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (dialogContext) {
        final tamano = MediaQuery.of(dialogContext).size;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Container(
            width: tamano.width - 16,
            height: tamano.height - 16,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                _refrescarDialogoExpandido = setDialogState;
                final carrito = ref.read(carritoCompraProvider);
                final productos = ref.read(productosStreamProvider).value ?? [];
                final mapaProductos = {for (final p in productos) p.id: p};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Productos en la compra',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          onPressed: _agregarProductoDesdeBusqueda,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            'Agregar Producto',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1A1A),
                            side: const BorderSide(color: Color(0xFFB6BCC7)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _encabezadoTablaCarrito(),
                    Divider(height: 18, color: Colors.grey.shade300),
                    Expanded(
                      child: carrito.items.isEmpty
                          ? Center(
                              child: Text(
                                'Todavía no agregaste productos.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: carrito.items.length,
                              separatorBuilder: (context, i) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, i) => _filaCarritoTabla(
                                i,
                                carrito.items[i],
                                mapaProductos,
                                carrito.items.length,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    _barraTotalesCompacta(carrito),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      _refrescarDialogoExpandido = null;
      if (mounted) setState(() => _tablaExpandida = false);
    });
  }

  Widget _barraTotalesCompacta(CarritoCompraState carrito) {
    Widget total(String etiqueta, double valor, {bool destacado = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            formatearMoneda(valor),
            style: GoogleFonts.poppins(
              fontSize: destacado ? 15 : 12.5,
              fontWeight: FontWeight.w800,
              color: destacado
                  ? Marca.primario
                  : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          total('Subtotal', carrito.subtotal),
          const SizedBox(width: 20),
          total('ISV', carrito.impuesto),
          const SizedBox(width: 20),
          total('Total a pagar', carrito.totalAPagar, destacado: true),
          const Spacer(),
          if (puedeRealizarAccion(ref, PermisosEspeciales.comprasCrear))
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: _guardando ? null : _confirmarCompra,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Registrar Compra',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezadoTablaCarrito() {
    final estilo = GoogleFonts.poppins(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
    );
    return Row(
      children: [
        const SizedBox(width: 28),
        Expanded(flex: 2, child: Text('Código', style: estilo)),
        Expanded(flex: 4, child: Text('Descripción', style: estilo)),
        Expanded(
          flex: 2,
          child: Text('Cantidad', textAlign: TextAlign.center, style: estilo),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Costo unitario',
            textAlign: TextAlign.center,
            style: estilo,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Descuento %',
            textAlign: TextAlign.center,
            style: estilo,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Descuento (L)',
            textAlign: TextAlign.right,
            style: estilo,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('Importe', textAlign: TextAlign.right, style: estilo),
        ),
        const SizedBox(width: 32),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _campoInlineNumero(
    String claveFoco,
    TextEditingController controlador,
    double valorActual,
    void Function(double) alConfirmar, {
    String? sufijo,
    String? prefijo,
    bool dosDecimales = false,
  }) {
    final esMovilNativo = !kIsWeb && _esPlataformaMovil;

    final focusNode = _focusInline.putIfAbsent(claveFoco, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) _confirmarInline[claveFoco]?.call();
      });
      return node;
    });

    void confirmar() {
      final texto = controlador.text.replaceAll(',', '').trim();
      final valor = double.tryParse(texto);
      if (valor == null) return;
      if ((valor - valorActual).abs() >= 0.005) alConfirmar(valor);
      if (dosDecimales) controlador.text = valor.toStringAsFixed(2);
      if (esMovilNativo) {
        if (focusNode.hasFocus) focusNode.unfocus();
      } else if (_esWebMovil) {
        _focusAnclaMovil.requestFocus();
      } else {
        _focusCodigoBarras.requestFocus();
      }
    }

    _confirmarInline[claveFoco] = confirmar;

    Future<void> abrirTecladoNumerico() async {
      focusNode.unfocus();
      final texto = await showDialog<String>(
        useRootNavigator: false,
        context: context,
        builder: (context) => TecladoNumericoDialog(
          titulo: sufijo == '%' ? 'Descuento (%)' : 'Valor',
          valorInicial: controlador.text,
        ),
      );
      if (texto == null || !mounted) return;
      controlador.text = texto;
      confirmar();
    }

    final campo = CampoTecladoCompacto(
      controller: controlador,
      numerico: true,
      onSubmitted: (_) => confirmar(),
      child: TextField(
        inputFormatters: [mayusculasInputFormatter],
        autocorrect: false,
        enableSuggestions: false,
        controller: controlador,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          suffixText: sufijo,
          prefixText: prefijo,
          prefixStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          filled: true,
          fillColor: const Color(0xFFE8EAF0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        onSubmitted: (_) => confirmar(),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );

    if (esMovilNativo) return campo;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: abrirTecladoNumerico,
      child: AbsorbPointer(child: campo),
    );
  }

  Widget _campoInlineConEtiqueta(
    String claveFoco,
    String etiqueta,
    TextEditingController controlador,
    double valorActual,
    void Function(double) alConfirmar, {
    bool dosDecimales = false,
    String? prefijo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        _campoInlineNumero(
          claveFoco,
          controlador,
          valorActual,
          alConfirmar,
          prefijo: prefijo,
          dosDecimales: dosDecimales,
        ),
      ],
    );
  }

  Widget _filaCarritoTabla(
    int index,
    dynamic item,
    Map<String, ProductoModel> mapaProductos,
    int totalItems,
  ) {
    final producto = mapaProductos[item.idProducto as String];

    final ctrlCantidad = _ctrlCantidad.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.cantidad as double),
      ),
    );
    final ctrlPrecio = _ctrlPrecio.putIfAbsent(
      index,
      () => TextEditingController(
        text: (item.precioCompra as double).toStringAsFixed(2),
      ),
    );
    final ctrlDescuento = _ctrlDescuento.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.descuentoPorcentaje as double),
      ),
    );
    final (ctrlMargen, ctrlPrecioVenta) = _controladoresMargen(index, item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: _botonesOrden(index, totalItems)),
              Expanded(
                flex: 2,
                child: Text(
                  producto?.codigo ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  item.nombreProducto as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _campoInlineNumero(
                    'cantidad_$index',
                    ctrlCantidad,
                    item.cantidad as double,
                    (v) => _actualizarCantidad(index, v),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _campoInlineNumero(
                    'precio_$index',
                    ctrlPrecio,
                    item.precioCompra as double,
                    (v) => _actualizarPrecio(index, v),
                    prefijo: 'L.',
                    dosDecimales: true,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _campoInlineNumero(
                    'descuento_$index',
                    ctrlDescuento,
                    item.descuentoPorcentaje as double,
                    (v) => _actualizarDescuentoLinea(index, v),
                    sufijo: '%',
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatearMoneda(_descuentoLineaMonto(item)),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatearMoneda(_importeBrutoItem(item)),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _botonVincularPendiente(index, item as ItemCompraModel),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Marca.primario,
                  ),
                  onPressed: () => _quitarItem(index),
                ),
              ),
            ],
          ),
          if (item.idPendienteReposicionVinculado != null)
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: _chipVinculoPendiente(item),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Spacer(flex: 6),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _campoInlineConEtiqueta(
                      'margen_$index',
                      'Margen %',
                      ctrlMargen,
                      _margenActual(item),
                      (v) => _actualizarMargenCompra(index, v),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _campoInlineConEtiqueta(
                      'precioVenta_$index',
                      _etiquetaPrecioVenta,
                      ctrlPrecioVenta,
                      _precioVentaFinal(item),
                      (v) => _actualizarPrecioVentaCompra(index, v),
                      prefijo: 'L.',
                      dosDecimales: true,
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaCarritoMovil(
    int index,
    dynamic item,
    Map<String, ProductoModel> mapaProductos,
    int totalItems,
  ) {
    final producto = mapaProductos[item.idProducto as String];

    final ctrlCantidad = _ctrlCantidad.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.cantidad as double),
      ),
    );
    final ctrlPrecio = _ctrlPrecio.putIfAbsent(
      index,
      () => TextEditingController(
        text: (item.precioCompra as double).toStringAsFixed(2),
      ),
    );
    final ctrlDescuento = _ctrlDescuento.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.descuentoPorcentaje as double),
      ),
    );
    final (ctrlMargen, ctrlPrecioVenta) = _controladoresMargen(index, item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7CBD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _botonesOrden(index, totalItems),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombreProducto as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      producto?.codigo ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _botonVincularPendiente(index, item as ItemCompraModel),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Marca.primario,
                ),
                onPressed: () => _quitarItem(index),
              ),
            ],
          ),
          if (item.idPendienteReposicionVinculado != null)
            _chipVinculoPendiente(item),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _campoInlineConEtiqueta(
                  'cantidad_$index',
                  'Cantidad',
                  ctrlCantidad,
                  item.cantidad,
                  (v) => _actualizarCantidad(index, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _campoInlineConEtiqueta(
                  'precio_$index',
                  'Costo unitario',
                  ctrlPrecio,
                  item.precioCompra,
                  (v) => _actualizarPrecio(index, v),
                  prefijo: 'L.',
                  dosDecimales: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _campoInlineConEtiqueta(
                  'descuento_$index',
                  'Desc. %',
                  ctrlDescuento,
                  item.descuentoPorcentaje,
                  (v) => _actualizarDescuentoLinea(index, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _campoInlineConEtiqueta(
                  'margen_$index',
                  'Margen %',
                  ctrlMargen,
                  _margenActual(item),
                  (v) => _actualizarMargenCompra(index, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _campoInlineConEtiqueta(
                  'precioVenta_$index',
                  _etiquetaPrecioVenta,
                  ctrlPrecioVenta,
                  _precioVentaFinal(item),
                  (v) => _actualizarPrecioVentaCompra(index, v),
                  prefijo: 'L.',
                  dosDecimales: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Descuento: ${formatearMoneda(_descuentoLineaMonto(item))}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Importe: ${formatearMoneda(_importeBrutoItem(item))}',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatoCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble())
      return cantidad.toInt().toString();
    return cantidad.toStringAsFixed(2);
  }

  Widget _tarjetaTotales(CarritoCompraState carrito, bool esMovil) {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _filaTotalTexto(
                'Subtotal',
                carrito.subtotal +
                    carrito.descuentoLineasMonto +
                    carrito.descuentoTotalMonto,
              ),
              if (carrito.descuentoLineasMonto > 0)
                _filaTotalTexto(
                  'Descuentos y Rebajas',
                  carrito.descuentoLineasMonto,
                ),
              if (carrito.descuentoTotalMonto > 0)
                _filaTotalTexto(
                  'Descuento global',
                  carrito.descuentoTotalMonto,
                ),
              _filaTotalTexto(
                'ISV (${_formatoCantidad(carrito.isvPorcentaje)}%)',
                carrito.impuesto,
              ),
              if (carrito.ajusteManual != 0)
                _filaTotalTexto('Ajuste', carrito.ajusteManual),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Marca.primario,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL A PAGAR',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  formatearMoneda(carrito.totalAPagar),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (puedeRealizarAccion(ref, PermisosEspeciales.comprasCrear))
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardando ? null : _confirmarCompra,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      'Registrar Compra',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTotalTexto(String etiqueta, double valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          formatearMoneda(valor),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
