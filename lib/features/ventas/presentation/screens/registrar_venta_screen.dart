import '../../../../core/theme/marca.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../data/escaneo_remoto_repository.dart';
import '../../data/item_venta_model.dart';
import '../../data/venta_en_espera_model.dart';
import '../../data/venta_export_service.dart';
import '../../data/venta_model.dart';
import '../../data/venta_repository.dart';
import '../../data/venta_ticket_escpos_service.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/usuario_venta_provider.dart';
import '../../../../core/providers/tabs_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../clientes/data/cliente_model.dart';
import '../../../clientes/providers/clientes_provider.dart';
import '../../../clientes/presentation/widgets/cliente_form_dialog.dart';
import '../../../ventas_credito/providers/ventas_credito_provider.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../../negocio/data/negocio_model.dart';
import '../../../negocio/presentation/widgets/acceso_especial.dart';
import '../../../productos/data/producto_model.dart';
import '../../../productos/providers/productos_provider.dart';
import '../../../categorias/providers/categorias_provider.dart';
import '../../../promociones/data/promocion_model.dart';
import '../../../promociones/providers/promociones_provider.dart';
import '../../../promociones/presentation/widgets/promocion_detectada_dialog.dart';
import '../../../promociones/presentation/widgets/promociones_vigentes_dialog.dart';
import '../../../../core/services/impresora_bluetooth_service.dart';
import '../../../../core/services/impresora_red_service.dart';
import '../../../../core/services/impresora_usb_windows_service.dart';
import '../../../../core/utils/codigo_barras_utils.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../../core/utils/impresion_calentamiento.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/exito_transaccion_overlay.dart';
import '../../../../core/widgets/pdf_preview_dialog.dart';
import '../widgets/buscar_producto_dialog.dart';
import '../widgets/panel_buscador_grid.dart';
import '../../data/registrar_venta_vista_storage.dart';
import '../widgets/buscar_cliente_dialog.dart';
import '../widgets/cambiar_usuario_venta_dialog.dart';
import '../widgets/cobrar_dialog.dart';
import '../widgets/pago_mixto_dialog.dart';
import '../../data/pago_detalle_model.dart';
import '../widgets/ventas_en_espera_dialog.dart';
import '../widgets/ventas_pendientes_impresion_dialog.dart';
import '../widgets/teclado_numerico_dialog.dart';
import '../widgets/escanear_remoto_dialog.dart';
import '../widgets/ticket_escpos_preview.dart';
import '../widgets/datos_envio_dialog.dart';
import 'ver_facturas_screen.dart';
import '../../data/tipos_documento.dart';
import '../../../../core/utils/mayusculas_input_formatter.dart';
import '../../../../core/utils/texto_utils.dart';
import '../../../../core/widgets/campo_teclado_compacto.dart';

const _metodosPago = [
  'Efectivo',
  'Tarjeta',
  'Transferencia',
  'Cheque',
  'Mixto',
];

class RegistrarVentaScreen extends ConsumerStatefulWidget {
  final String? tabId;

  final bool autoAbrirBusqueda;

  const RegistrarVentaScreen({
    super.key,
    this.tabId,
    this.autoAbrirBusqueda = false,
  });

  @override
  ConsumerState<RegistrarVentaScreen> createState() =>
      _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends ConsumerState<RegistrarVentaScreen> {
  final _nombreClienteController = TextEditingController();
  final _documentoClienteController = TextEditingController();
  final _telefonoCreditoController = TextEditingController();
  final _ocController = TextEditingController();
  final _regExoneradoController = TextEditingController();
  final _regSagController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _descuentoGlobalController = TextEditingController();
  bool _datosExpandidos = false;
  String _panelMovilDividida = 'buscar';
  bool _precioCarritoConIsv = true;

  bool get _ventaEsFacturable {
    final tipo = ref.read(carritoVentaProvider).tipoDocumento;
    return tipo == 'Factura' || tipo == 'Boleta';
  }

  bool get _mostrarPrecioConIsv => _ventaEsFacturable && _precioCarritoConIsv;

  String get _etiquetaColumnaPrecio {
    if (!_ventaEsFacturable) return 'Precio';
    return _precioCarritoConIsv ? 'Precio (c/ISV)' : 'Precio (s/ISV)';
  }

  String get _etiquetaColumnaImporte {
    if (!_ventaEsFacturable) return 'Importe';
    return _precioCarritoConIsv ? 'Importe (c/ISV)' : 'Importe (s/ISV)';
  }
  ClienteModel? _clienteVinculado;
  bool _esEnvio = false;
  String _envioNombre = '';
  String _envioDireccion = '';
  String _envioTelefono = '';
  bool _imprimirGuiaAlConfirmar = false;
  bool _formatoGuiaGrande = false;
  final _focusNombreCliente = FocusNode();
  final _clienteLayerLink = LayerLink();
  OverlayEntry? _overlaySugerenciasCliente;
  double? _saldoVencidoCliente;
  String? _claveUltimaVerificacionCredito;
  bool _tablaExpandida = false;

  Timer? _debounceEnEspera;

  bool _pausarLectorFisico = false;
  void Function(void Function())? _refrescarDialogoExpandido;
  void Function(void Function())? _refrescarModalDatosVenta;

  final _servicioExport = VentaExportService();
  final _servicioTicketEscPos = VentaTicketEscPosService();
  final _servicioImpresoraRed = ImpresoraRedService();
  final _servicioImpresoraBluetooth = ImpresoraBluetoothService();
  bool _guardando = false;

  final _ctrlCodigoBarras = TextEditingController();
  final _focusCodigoBarras = FocusNode();

  final _focusAnclaMovil = FocusNode(debugLabel: 'ancla_teclado_web_movil');

  final _bufferEscanerFisico = StringBuffer();
  DateTime? _ultimaTeclaEscanerFisico;
  static const _intervaloMaximoEscanerFisico = Duration(milliseconds: 45);

  bool get _esPlataformaMovil =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get _esWebMovil => kIsWeb && _esPlataformaMovil;

  bool _tablaConScrollPropio(bool esMovil) => !esMovil && !_esPlataformaMovil;

  final _scrollControllerMovil = ScrollController();
  bool _mostrarBarraFlotante = true;

  final _escaneoRemoto = EscaneoRemotoRepository();
  String? _codigoEscaneoRemoto;
  bool _escaneoRemotoConectado = false;
  StreamSubscription<String>? _suscripcionEscaneoRemoto;
  StreamSubscription<bool>? _suscripcionConectadoEscaneo;

  final Map<int, TextEditingController> _ctrlCantidad = {};
  final Map<int, TextEditingController> _ctrlPrecio = {};
  final Map<int, TextEditingController> _ctrlDescuento = {};
  final Map<int, TextEditingController> _ctrlDescripcion = {};
  final Map<String, FocusNode> _focusInline = {};
  final Map<String, VoidCallback> _confirmarInline = {};
  final Map<int, FocusNode> _focusDescripcion = {};
  final Map<int, Future<void> Function()> _confirmarDescripcion = {};
  int _conteoItemsControladores = -1;

  final _keyCliente = GlobalKey();
  final _keyTipoDocumento = GlobalKey();
  final _keyCondicion = GlobalKey();
  final _keyMetodoPago = GlobalKey();
  final _keyMasDatos = GlobalKey();
  final _keyFechaVencimiento = GlobalKey();
  final _keyTelefonoCredito = GlobalKey();
  final _keyDescuentoGlobal = GlobalKey();
  final _keyAgregarProducto = GlobalKey();
  final _keyTablaProductos = GlobalKey();
  final _keyBotonRegistrarVenta = GlobalKey();
  final _keyGuardarEnEspera = GlobalKey();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_manejarAtajoTeclado);

    if (_esWebMovil) _scrollControllerMovil.addListener(_alScrollearMovil);


    if (!_esPlataformaMovil) {
      FocusManager.instance.addListener(_alCambiarFocoGlobal);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alCambiarFocoGlobal(),
      );
    }

    final datosOrigen = ref.read(ventaParaCargarProvider);
    if (datosOrigen != null) {
      ref.read(ventaParaCargarProvider.notifier).limpiar();
      final ventaOrigen = datosOrigen.venta;
      ref
          .read(carritoVentaProvider.notifier)
          .cargarDesdeVenta(
            ventaOrigen,
            forzarFactura: datosOrigen.forzarFactura,
          );
      _nombreClienteController.text = ventaOrigen.nombreCliente;
      _documentoClienteController.text = ventaOrigen.documentoCliente;
      _ocController.text = ventaOrigen.oc;
      _regExoneradoController.text = ventaOrigen.regExonerado;
      _regSagController.text = ventaOrigen.regSag;
      _observacionesController.text = ventaOrigen.observaciones;
      _descuentoGlobalController.text = ventaOrigen.descuentoGlobal == 0
          ? ''
          : _formatoCantidad(ventaOrigen.descuentoGlobal);
    }

    if (widget.autoAbrirBusqueda) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _agregarProductoDesdeBusqueda();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _verificarCreditoVencido(ref.read(carritoVentaProvider));
    });
  }

  void _alScrollearMovil() {
    if (!mounted || !_scrollControllerMovil.hasClients) return;
    final posicion = _scrollControllerMovil.position;
    final cercaDelFinal =
        posicion.maxScrollExtent <= 0 ||
        (posicion.maxScrollExtent - posicion.pixels) < 220;
    final debeMostrarse = !cercaDelFinal;
    if (debeMostrarse != _mostrarBarraFlotante)
      setState(() => _mostrarBarraFlotante = debeMostrarse);
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
          _confirmarVenta();
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
    if (_esWebMovil) _scrollControllerMovil.removeListener(_alScrollearMovil);
    _scrollControllerMovil.dispose();
    _suscripcionEscaneoRemoto?.cancel();
    _suscripcionConectadoEscaneo?.cancel();
    final codigoEscaneo = _codigoEscaneoRemoto;
    if (codigoEscaneo != null) _escaneoRemoto.eliminarSesion(codigoEscaneo);
    _ctrlCodigoBarras.dispose();
    _focusCodigoBarras.dispose();
    _focusAnclaMovil.dispose();
    _ocultarSugerenciasCliente();
    _focusNombreCliente.dispose();
    _nombreClienteController.dispose();
    _documentoClienteController.dispose();
    _telefonoCreditoController.dispose();
    _ocController.dispose();
    _regExoneradoController.dispose();
    _regSagController.dispose();
    _observacionesController.dispose();
    _descuentoGlobalController.dispose();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecio.values) {
      c.dispose();
    }
    for (final c in _ctrlDescuento.values) {
      c.dispose();
    }
    for (final c in _ctrlDescripcion.values) {
      c.dispose();
    }
    for (final f in _focusInline.values) {
      f.dispose();
    }
    for (final f in _focusDescripcion.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), showCloseIcon: true));
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


  Future<void> _buscarCliente() async {
    final cliente = await showDialog<ClienteModel>(
      useRootNavigator: false,
      context: context,
      builder: (context) => const BuscarClienteDialog(),
    );
    if (cliente == null) return;
    final documento = cliente.dni;
    final nombre = cliente.nombreCompleto;
    setState(() {
      _nombreClienteController.text = nombre;
      _documentoClienteController.text = documento;
      _telefonoCreditoController.text = cliente.telefono;
      _clienteVinculado = cliente;
    });
    ref
        .read(carritoVentaProvider.notifier)
        .establecerCliente(
          documento: documento,
          nombre: nombre,
          idCliente: cliente.id,
        );
    ref
        .read(carritoVentaProvider.notifier)
        .establecerTelefonoCredito(cliente.telefono);
  }

  void _actualizarSugerenciasCliente(String texto) {
    final consulta = texto.trim();
    if (consulta.length < 2 || !_focusNombreCliente.hasFocus) {
      _ocultarSugerenciasCliente();
      return;
    }
    final todos =
        ref.read(clientesStreamProvider).value ?? const <ClienteModel>[];
    final consultaNorm = normalizarTexto(consulta);
    final coincidencias =
        todos
            .where((c) => c.estado && coincideFuzzy(c.textoBusqueda, consulta))
            .toList()
          ..sort(
            (a, b) => _rangoCoincidenciaCliente(
              a,
              consultaNorm,
            ).compareTo(_rangoCoincidenciaCliente(b, consultaNorm)),
          );
    final top = coincidencias.take(5).toList();
    if (top.isEmpty) {
      _ocultarSugerenciasCliente();
      return;
    }
    if (_overlaySugerenciasCliente == null) {
      _overlaySugerenciasCliente = OverlayEntry(
        builder: (context) => _sugerenciasClienteOverlay(top),
      );
      Overlay.of(context).insert(_overlaySugerenciasCliente!);
    } else {
      _sugerenciasClienteActuales = top;
      _overlaySugerenciasCliente!.markNeedsBuild();
    }
  }

  int _rangoCoincidenciaCliente(ClienteModel c, String consultaNorm) {
    final nombreNorm = normalizarTexto(c.nombreCompleto);
    if (nombreNorm.startsWith(consultaNorm)) return 0;
    if (nombreNorm.split(RegExp(r'\s+')).any((p) => p.startsWith(consultaNorm)))
      return 1;
    if (nombreNorm.contains(consultaNorm)) return 2;
    return 3;
  }

  List<ClienteModel> _sugerenciasClienteActuales = const [];

  Widget _sugerenciasClienteOverlay(List<ClienteModel> coincidencias) {
    _sugerenciasClienteActuales = coincidencias;
    return Positioned(
      width: 320,
      child: CompositedTransformFollower(
        link: _clienteLayerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 58),
        child: TapRegion(
          groupId: 'sugerencias-cliente',
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _sugerenciasClienteActuales.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, i) {
                  final c = _sugerenciasClienteActuales[i];
                  return InkWell(
                    onTap: () => _seleccionarClienteSugerido(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.nombreCompleto,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (c.dni.isNotEmpty)
                            Text(
                              'DNI: ${c.dni}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _seleccionarClienteSugerido(ClienteModel cliente) {
    _ocultarSugerenciasCliente();
    setState(() {
      _nombreClienteController.text = cliente.nombreCompleto;
      _documentoClienteController.text = cliente.dni;
      _telefonoCreditoController.text = cliente.telefono;
      _clienteVinculado = cliente;
    });
    ref
        .read(carritoVentaProvider.notifier)
        .establecerCliente(
          documento: cliente.dni,
          nombre: cliente.nombreCompleto,
          idCliente: cliente.id,
        );
    ref
        .read(carritoVentaProvider.notifier)
        .establecerTelefonoCredito(cliente.telefono);
    _focusNombreCliente.unfocus();
  }

  void _ocultarSugerenciasCliente() {
    _overlaySugerenciasCliente?.remove();
    _overlaySugerenciasCliente = null;
  }

  Widget _chipClienteVinculado() {
    final nombre = _nombreClienteController.text.trim();
    return Tooltip(
      message: 'Quitar cliente y volver a escribir',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _desvincularClienteDelCampo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF16A34A).withOpacity(0.45),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre.isEmpty ? 'Cliente' : nombre,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14532D),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.close,
                size: 16,
                color: const Color(0xFF14532D).withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _desvincularClienteDelCampo() {
    _ocultarSugerenciasCliente();
    setState(() => _clienteVinculado = null);
    ref
        .read(carritoVentaProvider.notifier)
        .establecerNombreClienteManual(_nombreClienteController.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNombreCliente.requestFocus();
    });
  }

  Future<ClienteModel?> _resolverClienteVinculado(String idCliente) async {
    final actual = _clienteVinculado;
    if (actual != null && actual.id == idCliente) return actual;
    final lista =
        ref.read(clientesStreamProvider).value ?? const <ClienteModel>[];
    for (final c in lista) {
      if (c.id == idCliente) return c;
    }
    return ref.read(clienteRepositoryProvider).obtenerPorId(idCliente);
  }

  Future<void> _completarDatosCliente() async {
    final idCliente = ref.read(carritoVentaProvider).idCliente;
    if (idCliente == null) return;
    final cliente = await _resolverClienteVinculado(idCliente);
    if (!mounted) return;
    if (cliente == null) {
      _mostrarMensaje('No se encontró el cliente vinculado a esta venta.');
      return;
    }
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => ClienteFormDialog(cliente: cliente),
    );
    if (!mounted) return;
    final actualizado = await ref
        .read(clienteRepositoryProvider)
        .obtenerPorId(idCliente);
    if (!mounted || actualizado == null) return;
    setState(() {
      _clienteVinculado = actualizado;
      _nombreClienteController.text = actualizado.nombreCompleto;
      _documentoClienteController.text = actualizado.dni;
      _telefonoCreditoController.text = actualizado.telefono;
    });
    ref
        .read(carritoVentaProvider.notifier)
        .establecerCliente(
          documento: actualizado.dni,
          nombre: actualizado.nombreCompleto,
          idCliente: actualizado.id,
        );
    ref
        .read(carritoVentaProvider.notifier)
        .establecerTelefonoCredito(actualizado.telefono);
  }

  Future<void> _verificarCreditoVencido(CarritoVentaState carrito) async {
    final idCliente = carrito.idCliente;
    final documento = carrito.documentoCliente.trim();
    if ((idCliente == null || idCliente.isEmpty) &&
        (documento.isEmpty || documento == 'N/A')) {
      _claveUltimaVerificacionCredito = null;
      if (_saldoVencidoCliente != null && mounted)
        setState(() => _saldoVencidoCliente = null);
      return;
    }
    final clave = idCliente ?? documento;
    if (_claveUltimaVerificacionCredito == clave) return;
    _claveUltimaVerificacionCredito = clave;
    try {
      final creditos = await ref
          .read(ventaCreditoRepositoryProvider)
          .obtenerCreditosDeCliente(
            idCliente: idCliente,
            documentoCliente: documento,
          );
      final totalVencido = creditos
          .where((c) => c.vencida)
          .fold<double>(0, (s, c) => s + c.saldoPendiente);
      if (!mounted) return;
      setState(
        () => _saldoVencidoCliente = totalVencido > 0 ? totalVencido : null,
      );
    } catch (_) {
    }
  }

  Widget _avisoCreditoVencido(double saldoVencido) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este cliente tiene un crédito vencido de ${formatearMoneda(saldoVencido)} — revisá antes de continuar.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<bool> _ventaSinExistenciaPermitida() async {
    final negocio = await ref.read(negocioRepositoryProvider).obtenerNegocioActual();
    return negocio.tieneClaveEspecial && negocio.tienePermiso(PermisosEspeciales.ventasVenderSinStock);
  }

  void _avisarSinExistencia(String nombre) {
    _mostrarMensaje('"$nombre" no tiene existencia disponible: no se puede agregar a la venta.');
  }

  bool _categoriaControlaStock(String idCategoria) {
    final categorias = ref.read(categoriasStreamProvider).value ?? [];
    final coincidencias = categorias.where((c) => c.id == idCategoria).toList();
    return coincidencias.isEmpty ? true : coincidencias.first.controlaStock;
  }

  Future<void> _agregarProductoDesdeBusqueda() async {
    _pausarLectorFisico = true;
    try {
      final permiteSinExistencia = await _ventaSinExistenciaPermitida();
      if (!mounted) return;
      final carritoActual = ref.read(carritoVentaProvider);
      final resultado = await Navigator.of(context).push<ProductoConPrecio>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => BuscarProductoDialog(
            esCotizacion: ref.read(carritoVentaProvider).esCotizacion,
            permiteSinExistencia: permiteSinExistencia,
            condicion: carritoActual.condicion,
            metodoPago: carritoActual.metodoPago,
          ),
        ),
      );
      if (resultado == null || !mounted) return;
      await _procesarProductoSeleccionado(resultado);
    } finally {
      _pausarLectorFisico = false;
    }
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

  Future<void> _procesarProductoSeleccionado(
    ProductoConPrecio resultado, {
    bool esEscaneo = false,
  }) async {
    final producto = resultado.producto;
    if (producto.esCombo) {
      final mapaProductos = {
        for (final p
            in ref.read(productosStreamProvider).value ??
                const <ProductoModel>[])
          p.id: p,
      };
      ref
          .read(carritoVentaProvider.notifier)
          .agregarComboDirecto(
            producto,
            mapaProductos: mapaProductos,
            precioSeleccionado: resultado.precio,
          );
      return;
    }
    final carrito = ref.read(carritoVentaProvider);
    final sinExistencia =
        producto.stock <= 0 && _categoriaControlaStock(producto.idCategoria);

    if (sinExistencia && carrito.esCotizacion) {
      _mostrarMensaje(
        'Advertencia: "${producto.nombre}" no tiene existencia disponible, pero se agregará a la cotización.',
      );
    } else if (sinExistencia) {
      if (!await _ventaSinExistenciaPermitida()) {
        if (mounted) _avisarSinExistencia(producto.nombre);
        return;
      }
      if (!mounted) return;
      final autorizado = (await verificarAccesoEspecial(
        context,
        ref,
        PermisosEspeciales.ventasVenderSinStock,
      )).autorizado;
      if (!mounted) return;
      if (!autorizado) return;
    }
    if (!mounted) return;
    await _agregarProductoConPromos(
      producto,
      precioSeleccionado: resultado.precio,
      esEscaneo: esEscaneo,
    );
  }


  Future<void> _agregarProductoConPromos(
    ProductoModel producto, {
    required double precioSeleccionado,
    bool reembasado = false,
    bool esEscaneo = false,
  }) async {
    final carritoAntes = ref.read(carritoVentaProvider);
    final condicion = carritoAntes.condicion;
    final metodoPago = carritoAntes.metodoPago;
    final cantidadAntes = carritoAntes.items
        .where((i) => i.idProducto == producto.id)
        .fold<double>(0, (s, i) => s + i.cantidad);
    final promociones =
        ref.read(promocionesStreamProvider).value ?? const <PromocionModel>[];

    const fusionarSiYaExiste = true;
    final indiceNuevo = ref
        .read(carritoVentaProvider.notifier)
        .agregarOFusionarProductoDirecto(
          producto,
          precioSeleccionado: precioSeleccionado,
          reembasado: reembasado,
          fusionarSiYaExiste: fusionarSiYaExiste,
        );
    if (!mounted) return;
    _ctrlCantidad[indiceNuevo]?.text = _formatoCantidad(
      ref.read(carritoVentaProvider).items[indiceNuevo].cantidad,
    );

    final promoPrecio = mejorPromoPrecio(
      promociones: promociones,
      idProducto: producto.id,
      precioActual: precioSeleccionado,
      condicion: condicion,
      metodoPago: metodoPago,
    );
    if (promoPrecio != null) {
      final aceptar = await showDialog<bool>(
        useRootNavigator: false,
        context: context,
        builder: (context) => PromocionDetectadaDialog(promocion: promoPrecio),
      );
      if (!mounted) return;
      if (aceptar == true) {
        if (promoPrecio.tipo == TipoPromocion.porcentaje) {
          ref
              .read(carritoVentaProvider.notifier)
              .actualizarLinea(
                indiceNuevo,
                descuentoPorcentaje: promoPrecio.valor,
              );
        } else {
          ref
              .read(carritoVentaProvider.notifier)
              .actualizarLinea(
                indiceNuevo,
                precioNuevo: promoPrecio.valor / ref.read(carritoVentaProvider).factorIsv,
              );
        }
        _mostrarMensaje('Promoción "${promoPrecio.nombre}" aplicada.');
        return;
      }
    }

    final cantidadDespues = cantidadAntes + 1;
    final promoCombo = promoComboORegaloAplicable(
      promociones: promociones,
      idProducto: producto.id,
      cantidadEnCarrito: cantidadDespues,
      condicion: condicion,
      metodoPago: metodoPago,
    );
    if (promoCombo != null && cantidadAntes < promoCombo.cantidadRequerida) {
      await _ofrecerComboORegalo(
        promoCombo,
        precioUnitarioBase: precioSeleccionado,
      );
      return;
    }

    final cantidadesAntes = <String, double>{};
    for (final item in carritoAntes.items) {
      cantidadesAntes[item.idProducto] =
          (cantidadesAntes[item.idProducto] ?? 0) + item.cantidad;
    }
    final cantidadesDespues = Map<String, double>.from(cantidadesAntes);
    cantidadesDespues[producto.id] = (cantidadesDespues[producto.id] ?? 0) + 1;

    final promoComboMulti = promoComboMultiproductoAplicable(
      promociones: promociones,
      idProducto: producto.id,
      cantidadesEnCarrito: cantidadesDespues,
      condicion: condicion,
      metodoPago: metodoPago,
    );
    if (promoComboMulti == null) return;
    final yaEstabaCompleto = promoComboMulti.idsProductosCombo.every(
      (id) => (cantidadesAntes[id] ?? 0) >= 1,
    );
    if (yaEstabaCompleto) return;

    final precioNormalCombo = promoComboMulti.idsProductosCombo.fold<double>(
      0,
      (s, id) {
        if (id == producto.id) return s + redondearMoneda(precioSeleccionado);
        final itemExistente = carritoAntes.items.where(
          (i) => i.idProducto == id,
        );
        if (itemExistente.isEmpty) return s;
        return s + redondearMoneda(itemExistente.first.precioVenta);
      },
    );
    await _ofrecerComboORegalo(
      promoComboMulti,
      precioUnitarioBase: precioNormalCombo,
    );
  }

  Future<void> _ofrecerComboORegalo(
    PromocionModel promo, {
    required double precioUnitarioBase,
  }) async {
    if (!mounted) return;
    final aceptar = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => PromocionDetectadaDialog(
        promocion: promo,
        precioUnitarioBase: precioUnitarioBase,
      ),
    );
    if (!mounted || aceptar != true) return;
    _aplicarComboORegalo(promo);
    _mostrarMensaje('Promoción "${promo.nombre}" aplicada.');
  }

  Future<void> _revisarPromoComboTrasCambioCantidad(
    int index,
    double cantidadAnteriorLinea,
    double cantidadNuevaLinea,
  ) async {
    final carrito = ref.read(carritoVentaProvider);
    if (index >= carrito.items.length) return;
    final idProducto = carrito.items[index].idProducto;
    final totalOtrasLineas = [
      for (var i = 0; i < carrito.items.length; i++)
        if (i != index && carrito.items[i].idProducto == idProducto)
          carrito.items[i].cantidad,
    ].fold<double>(0, (s, c) => s + c);
    final cantidadAntes = totalOtrasLineas + cantidadAnteriorLinea;
    final cantidadDespues = totalOtrasLineas + cantidadNuevaLinea;
    if (cantidadDespues <= cantidadAntes) return;

    final promociones =
        ref.read(promocionesStreamProvider).value ?? const <PromocionModel>[];
    final promoCombo = promoComboORegaloAplicable(
      promociones: promociones,
      idProducto: idProducto,
      cantidadEnCarrito: cantidadDespues,
      condicion: carrito.condicion,
      metodoPago: carrito.metodoPago,
    );
    if (promoCombo == null || cantidadAntes >= promoCombo.cantidadRequerida)
      return;
    final precioUnit = carrito.items[index].precioVenta;
    await _ofrecerComboORegalo(promoCombo, precioUnitarioBase: precioUnit);
  }

  void _aplicarComboORegalo(PromocionModel promo) {
    final notifier = ref.read(carritoVentaProvider.notifier);
    if (promo.tipo == TipoPromocion.comboCantidad) {
      final carrito = ref.read(carritoVentaProvider);
      final indices = [
        for (var i = 0; i < carrito.items.length; i++)
          if (carrito.items[i].idProducto == promo.idProductoBase) i,
      ];
      if (indices.isEmpty) return;
      final cantidadTotal = indices.fold<double>(
        0,
        (s, i) => s + carrito.items[i].cantidad,
      );
      final totalNormal = indices.fold<double>(0, (s, i) {
        final item = carrito.items[i];
        return s + redondearMoneda(item.precioVenta * carrito.factorIsv) * item.cantidad;
      });
      if (totalNormal <= 0) return;
      final extra = (cantidadTotal - promo.cantidadRequerida).clamp(
        0,
        double.infinity,
      );
      final precioPromedioNormal = totalNormal / cantidadTotal;
      final objetivo = promo.precioCombo + extra * precioPromedioNormal;
      final descuentoPct = ((1 - objetivo / totalNormal) * 100)
          .clamp(0, 100)
          .toDouble();
      for (final i in indices) {
        notifier.actualizarLinea(i, descuentoPorcentaje: descuentoPct);
      }
    } else if (promo.tipo == TipoPromocion.comboMultiproducto) {
      final carrito = ref.read(carritoVentaProvider);
      final indices = [
        for (var i = 0; i < carrito.items.length; i++)
          if (promo.idsProductosCombo.contains(carrito.items[i].idProducto)) i,
      ];
      if (indices.isEmpty) return;
      final idsPresentes = indices
          .map((i) => carrito.items[i].idProducto)
          .toSet();
      if (!promo.idsProductosCombo.every(idsPresentes.contains)) return;

      final totalNormal = indices.fold<double>(0, (s, i) {
        final item = carrito.items[i];
        return s + redondearMoneda(item.precioVenta * carrito.factorIsv) * item.cantidad;
      });
      if (totalNormal <= 0) return;

      var extraNormalValue = 0.0;
      for (final idProd in promo.idsProductosCombo) {
        final indicesProd = indices
            .where((i) => carrito.items[i].idProducto == idProd)
            .toList();
        if (indicesProd.isEmpty) continue;
        final cantidadProd = indicesProd.fold<double>(
          0,
          (s, i) => s + carrito.items[i].cantidad,
        );
        final normalProd = indicesProd.fold<double>(0, (s, i) {
          final item = carrito.items[i];
          return s + redondearMoneda(item.precioVenta * carrito.factorIsv) * item.cantidad;
        });
        final extraCantidad = (cantidadProd - 1).clamp(0, double.infinity);
        if (cantidadProd > 0)
          extraNormalValue += extraCantidad * (normalProd / cantidadProd);
      }

      final objetivo = promo.precioCombo + extraNormalValue;
      final descuentoPct = ((1 - objetivo / totalNormal) * 100)
          .clamp(0, 100)
          .toDouble();
      for (final i in indices) {
        notifier.actualizarLinea(i, descuentoPorcentaje: descuentoPct);
      }
    } else {
      final productos =
          ref.read(productosStreamProvider).value ?? const <ProductoModel>[];
      for (var i = 0; i < promo.idsProductosRegalo.length; i++) {
        final idRegalo = promo.idsProductosRegalo[i];
        final nombreFallback = i < promo.nombresProductosRegalo.length
            ? promo.nombresProductosRegalo[i]
            : '';
        final coincidencias = productos.where((p) => p.id == idRegalo).toList();
        final precioRegalo = coincidencias.isNotEmpty
            ? coincidencias.first.precioVenta
            : 0.0;
        final nombreRegalo = coincidencias.isNotEmpty
            ? coincidencias.first.nombre
            : nombreFallback;
        notifier.agregarItem(
          ItemVentaModel(
            idProducto: idRegalo,
            idCategoria: coincidencias.isNotEmpty
                ? coincidencias.first.idCategoria
                : '',
            nombreProducto: '$nombreRegalo (regalo · ${promo.nombre})',
            precioVenta: precioRegalo / ref.read(carritoVentaProvider).factorIsv,
            cantidad: promo.cantidadRegalo.toDouble(),
            subtotal: 0,
            precioCompraUsado: coincidencias.isNotEmpty
                ? coincidencias.first.precioCompra
                : 0,
            descuentoPorcentaje: 100,
          ),
        );
      }
    }
  }

  Future<void> _abrirPromocionesVigentes() async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => const PromocionesVigentesDialog(),
    );
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
    final producto = coincidencias.first;
    final precio = _primerPrecioDisponible(producto);
    if (precio == null) {
      _mostrarMensaje('"${producto.nombre}" no tiene un precio configurado');
      return;
    }
    await _procesarProductoSeleccionado(
      ProductoConPrecio(producto: producto, precio: precio, nivelPrecio: 1),
      esEscaneo: true,
    );
  }

  double? _primerPrecioDisponible(ProductoModel p) {
    for (final valor in [p.precioVenta, p.precioVenta2, p.precioVenta3]) {
      if (valor > 0) return valor;
    }
    return null;
  }

  Future<String> _asegurarSesionEscaneoRemoto() async {
    final codigoActual = _codigoEscaneoRemoto;
    if (codigoActual != null) return codigoActual;
    final codigo = _escaneoRemoto.generarCodigo();
    await _escaneoRemoto.crearSesion(codigo);
    _codigoEscaneoRemoto = codigo;
    _escaneoRemotoConectado = false;
    _suscripcionEscaneoRemoto = _escaneoRemoto.escucharCodigosNuevos(codigo).listen((codigoEscaneado) {
      if (codigoEscaneado.isNotEmpty) _procesarCodigoEscaneado(codigoEscaneado);
    });
    _suscripcionConectadoEscaneo = _escaneoRemoto
        .escucharConectado(codigo)
        .listen((conectado) {
          if (mounted) setState(() => _escaneoRemotoConectado = conectado);
        });
    return codigo;
  }

  Future<void> _finalizarEscaneoRemoto() async {
    final codigo = _codigoEscaneoRemoto;
    if (codigo == null) return;
    await _suscripcionEscaneoRemoto?.cancel();
    await _suscripcionConectadoEscaneo?.cancel();
    _suscripcionEscaneoRemoto = null;
    _suscripcionConectadoEscaneo = null;
    _codigoEscaneoRemoto = null;
    if (mounted) setState(() => _escaneoRemotoConectado = false);
    await _escaneoRemoto.eliminarSesion(codigo);
  }

  Future<void> _abrirEscaneoRemoto() async {
    if (_codigoEscaneoRemoto != null && _escaneoRemotoConectado) {
      final codigoActivo = _codigoEscaneoRemoto!;
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => EscaneoActivoDialog(
          eventos: _escaneoRemoto.escucharEventos(codigoActivo),
          alFinalizar: () async {
            Navigator.pop(context);
            await _finalizarEscaneoRemoto();
          },
          alEscanearOtro: () async {
            Navigator.pop(context);
            await _finalizarEscaneoRemoto();
            await _abrirEscaneoRemoto();
          },
        ),
      );
      return;
    }

    final codigo = await _asegurarSesionEscaneoRemoto();
    if (!mounted) return;
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => EscanearRemotoDialog(
        codigo: codigo,
        eventos: _escaneoRemoto.escucharEventos(codigo),
        conectado: _escaneoRemoto.escucharConectado(codigo),
      ),
    );
  }

  void _quitarItem(int index) {
    ref.read(carritoVentaProvider.notifier).quitarItem(index);
  }

  void _alternarPendienteCompra(int index) {
    final item = ref.read(carritoVentaProvider).items[index];
    ref
        .read(carritoVentaProvider.notifier)
        .marcarPendienteCompra(index, !item.pendienteCompra);
  }

  Widget _botonPendienteCompra(int index, ItemVentaModel item) {
    if (item.esCombo) {
      return SizedBox(
        width: 32,
        child: Tooltip(
          message:
              'No aplica a combos (su existencia depende de sus componentes)',
          child: Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: Colors.grey.shade200,
          ),
        ),
      );
    }
    final activo = item.pendienteCompra;
    return SizedBox(
      width: 32,
      child: IconButton(
        tooltip: activo
            ? 'Venta anticipada: se vendió sin saber todavía qué compra la va a reponer. La próxima compra de este producto la completa sola y corrige el costo. Tocá para desmarcar.'
            : 'Marcar como venta anticipada: se vende sin tener (o sin saber exactamente cuál) producto real en existencia. La próxima compra de este producto la empareja sola y corrige el costo.',
        icon: Icon(
          Icons.hourglass_bottom,
          size: 18,
          color: activo ? const Color(0xFFF59E0B) : Colors.grey.shade400,
        ),
        onPressed: () => _alternarPendienteCompra(index),
      ),
    );
  }

  void _moverItem(int index, int nuevoIndex) {
    ref.read(carritoVentaProvider.notifier).moverItem(index, nuevoIndex);
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

  void _revertirCantidad(int index) {
    final carrito = ref.read(carritoVentaProvider);
    if (index >= carrito.items.length) return;
    _ctrlCantidad[index]?.text = _formatoCantidad(
      carrito.items[index].cantidad,
    );
  }

  Future<void> _actualizarCantidad(int index, double nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor a 0');
      _revertirCantidad(index);
      return;
    }
    final carrito = ref.read(carritoVentaProvider);
    if (index >= carrito.items.length) return;
    final item = carrito.items[index];
    final cantidadAnterior = item.cantidad;

    if (!_categoriaControlaStock(item.idCategoria)) {
      ref
          .read(carritoVentaProvider.notifier)
          .actualizarLinea(index, cantidad: nuevaCantidad);
      await _revisarPromoComboTrasCambioCantidad(
        index,
        cantidadAnterior,
        nuevaCantidad,
      );
      return;
    }

    final productos = ref.read(productosStreamProvider).value ?? [];
    final coincidencias = productos
        .where((p) => p.id == item.idProducto)
        .toList();
    final stockDisponible = coincidencias.isNotEmpty
        ? coincidencias.first.stock
        : 0.0;

    if (stockDisponible < nuevaCantidad && !carrito.esCotizacion) {
      if (!await _ventaSinExistenciaPermitida()) {
        if (mounted) {
          _mostrarMensaje('"${item.nombreProducto}" solo tiene ${_formatoCantidad(stockDisponible)} en existencia: no se puede vender más.');
          _revertirCantidad(index);
        }
        return;
      }
      if (!mounted) return;
      final autorizado = (await verificarAccesoEspecial(
        context,
        ref,
        PermisosEspeciales.ventasVenderSinStock,
      )).autorizado;
      if (!mounted) return;
      if (!autorizado) {
        _revertirCantidad(index);
        return;
      }
    } else if (stockDisponible < nuevaCantidad && carrito.esCotizacion) {
      _mostrarMensaje(
        'Advertencia: "${item.nombreProducto}" no tiene stock suficiente, pero se actualizará en la cotización.',
      );
    }

    ref
        .read(carritoVentaProvider.notifier)
        .actualizarLinea(index, cantidad: nuevaCantidad);
    await _revisarPromoComboTrasCambioCantidad(
      index,
      cantidadAnterior,
      nuevaCantidad,
    );
  }

  Future<void> _actualizarPrecio(int index, double nuevoPrecioConIsv) async {
    if (nuevoPrecioConIsv < 0) {
      _mostrarMensaje('Precio inválido');
      return;
    }
    final autorizado = (await verificarAccesoEspecial(
      context,
      ref,
      PermisosEspeciales.ventasCambiarPrecio,
    )).autorizado;
    if (!mounted) return;
    if (!autorizado) {
      final carrito = ref.read(carritoVentaProvider);
      if (index < carrito.items.length) {
        final item = carrito.items[index];
        final precioBase = item.precioVenta;
        final precioPorCuartoMostrado = _mostrarPrecioConIsv
            ? redondearMoneda(precioBase * 1.15)
            : precioBase;
        _ctrlPrecio[index]?.text = precioPorCuartoMostrado.toStringAsFixed(2);
      }
      return;
    }
    ref
        .read(carritoVentaProvider.notifier)
        .actualizarLinea(index, precioNuevo: nuevoPrecioConIsv / 1.15);
  }

  Future<void> _actualizarPrecioSinIsv(int index, double nuevoPrecioSinIsv) {
    return _actualizarPrecio(index, redondearMoneda(nuevoPrecioSinIsv * 1.15));
  }

  void _alternarVistaPrecioCarrito(bool conIsv) {
    final carrito = ref.read(carritoVentaProvider);
    setState(() {
      _precioCarritoConIsv = conIsv;
      for (var i = 0; i < carrito.items.length; i++) {
        final ctrl = _ctrlPrecio[i];
        if (ctrl == null) continue;
        final item = carrito.items[i];
        final base = item.precioVenta;
        final precioPorCuarto = conIsv ? redondearMoneda(base * 1.15) : base;
        ctrl.text = precioPorCuarto.toStringAsFixed(2);
      }
    });
  }

  void _actualizarDescuentoLinea(int index, double descuento) {
    if (descuento < 0 || descuento > 100) {
      _mostrarMensaje('El descuento debe estar entre 0 y 100');
      return;
    }
    ref
        .read(carritoVentaProvider.notifier)
        .actualizarLinea(index, descuentoPorcentaje: descuento);
  }

  double _subtotalConIsv(dynamic item) {
    final precioConIsv = redondearMoneda(item.precioVenta * 1.15);
    return redondearMoneda(
      precioConIsv * item.cantidad * (1 - item.descuentoPorcentaje / 100),
    );
  }

  double _subtotalSinIsv(dynamic item) {
    return redondearMoneda(
      (item.precioVenta as double) *
          item.cantidad *
          (1 - item.descuentoPorcentaje / 100),
    );
  }

  double _importeMostrado(dynamic item) =>
      _mostrarPrecioConIsv ? _subtotalConIsv(item) : _subtotalSinIsv(item);


  Future<void> _guardarEnEspera() async {
    final carrito = ref.read(carritoVentaProvider);
    if (carrito.items.isEmpty) {
      _mostrarMensaje('No hay productos para guardar en espera.');
      return;
    }
    final repo = ref.read(ventaRepositoryProvider);
    final sesion = VentaEnEsperaModel(
      id: carrito.idEnEspera ?? '',
      fecha: DateTime.now(),
      tipoDocumento: carrito.tipoDocumento,
      condicion: carrito.condicion,
      metodoPago: carrito.metodoPago,
      documentoCliente: carrito.documentoCliente,
      nombreCliente: _nombreClienteController.text.trim(),
      idCliente: carrito.idCliente,
      fechaVencimiento: carrito.fechaVencimiento,
      oc: carrito.oc,
      regExonerado: carrito.regExonerado,
      regSag: carrito.regSag,
      observaciones: carrito.observaciones,
      descuentoGlobal: carrito.descuentoGlobalPorcentaje,
      items: carrito.items,
    );

    final usuario =
        ref.read(usuarioVentaOverrideProvider)?.nombreCompleto ??
        ref.read(authProvider).usuario?.nombreCompleto ??
        '';
    final categorias = ref.read(categoriasStreamProvider).value ?? [];
    final categoriasSinControlStock = categorias
        .where((c) => !c.controlaStock)
        .map((c) => c.id)
        .toSet();
    try {
      await repo.guardarVentaEnEsperaManual(
        sesion,
        usuario: usuario,
        categoriasSinControlStock: categoriasSinControlStock,
      );
      _mostrarMensaje(
        carrito.idEnEspera != null
            ? 'Venta en espera actualizada.'
            : 'Venta guardada en espera.',
      );
    } catch (e) {
      _mostrarMensaje('No se pudo guardar en espera: $e');
      return;
    }
    _limpiarTodo();
  }

  void _verPendientesImpresion() {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (context) => const VentasPendientesImpresionDialog(),
    );
  }

  void _programarAutoguardadoEnEspera(CarritoVentaState carrito) {
    _debounceEnEspera?.cancel();
    if (carrito.items.isEmpty) return;
    _debounceEnEspera = Timer(
      const Duration(seconds: 2),
      _guardarEnEsperaAutomatico,
    );
  }

  Future<void> _guardarEnEsperaAutomatico() async {
    if (!mounted) return;
    final carrito = ref.read(carritoVentaProvider);
    if (carrito.items.isEmpty) return;
    final repo = ref.read(ventaRepositoryProvider);
    final sesion = VentaEnEsperaModel(
      id: carrito.idEnEspera ?? '',
      fecha: DateTime.now(),
      tipoDocumento: carrito.tipoDocumento,
      condicion: carrito.condicion,
      metodoPago: carrito.metodoPago,
      documentoCliente: carrito.documentoCliente,
      nombreCliente: _nombreClienteController.text.trim(),
      idCliente: carrito.idCliente,
      fechaVencimiento: carrito.fechaVencimiento,
      oc: carrito.oc,
      regExonerado: carrito.regExonerado,
      regSag: carrito.regSag,
      observaciones: carrito.observaciones,
      descuentoGlobal: carrito.descuentoGlobalPorcentaje,
      items: carrito.items,
    );
    try {
      final id = await repo.guardarVentaEnEsperaAutomatica(sesion);
      if (carrito.idEnEspera == null) {
        if (!mounted) return;
        ref.read(carritoVentaProvider.notifier).establecerIdEnEspera(id);
      }
    } catch (_) {
    }
  }

  Future<void> _verEnEspera() => _abrirVentasEnEsperaOPerdidas(perdidas: false);

  Future<void> _verPerdidas() => _abrirVentasEnEsperaOPerdidas(perdidas: true);

  Future<void> _abrirVentasEnEsperaOPerdidas({required bool perdidas}) async {
    final sesion = await showDialog<VentaEnEsperaModel>(
      useRootNavigator: false,
      context: context,
      builder: (context) => VentasEnEsperaDialog(perdidas: perdidas),
    );
    if (sesion == null || !mounted) return;
    setState(() {
      _nombreClienteController.text = sesion.nombreCliente;
      _documentoClienteController.text = sesion.documentoCliente;
      _ocController.text = sesion.oc;
      _regExoneradoController.text = sesion.regExonerado;
      _regSagController.text = sesion.regSag;
      _observacionesController.text = sesion.observaciones;
      _descuentoGlobalController.text = sesion.descuentoGlobal == 0
          ? ''
          : _formatoCantidad(sesion.descuentoGlobal);
      _clienteVinculado = null;
    });
    ref.read(carritoVentaProvider.notifier).cargarSesion(sesion);
  }

  void _limpiarTodo() {
    ref.read(carritoVentaProvider.notifier).limpiar();
    _nombreClienteController.clear();
    _documentoClienteController.clear();
    _telefonoCreditoController.clear();
    _ocController.clear();
    _regExoneradoController.clear();
    _regSagController.clear();
    _observacionesController.clear();
    _descuentoGlobalController.clear();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecio.values) {
      c.dispose();
    }
    for (final c in _ctrlDescuento.values) {
      c.dispose();
    }
    _ctrlCantidad.clear();
    _ctrlPrecio.clear();
    _ctrlDescuento.clear();
    for (final c in _ctrlDescripcion.values) {
      c.dispose();
    }
    _ctrlDescripcion.clear();
    for (final f in _focusInline.values) {
      f.dispose();
    }
    _focusInline.clear();
    _confirmarInline.clear();
    for (final f in _focusDescripcion.values) {
      f.dispose();
    }
    _focusDescripcion.clear();
    _confirmarDescripcion.clear();
    _conteoItemsControladores = 0;
    _clienteVinculado = null;
    _saldoVencidoCliente = null;
    _claveUltimaVerificacionCredito = null;
    _esEnvio = false;
    _envioNombre = '';
    _envioDireccion = '';
    _envioTelefono = '';
    _imprimirGuiaAlConfirmar = false;
    _formatoGuiaGrande = false;
  }

  Future<void> _abrirDatosEnvio() async {
    final resultado = await showDialog<DatosEnvioResultado>(
      useRootNavigator: false,
      context: context,
      builder: (context) => DatosEnvioDialog(
        nombreInicial: _envioNombre.isNotEmpty
            ? _envioNombre
            : _nombreClienteController.text.trim(),
        direccionInicial: _envioDireccion.isNotEmpty
            ? _envioDireccion
            : (_clienteVinculado?.direccion ?? ''),
        telefonoInicial: _envioTelefono.isNotEmpty
            ? _envioTelefono
            : (_clienteVinculado?.telefono ?? ''),
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _esEnvio = true;
      _envioNombre = resultado.nombre;
      _envioDireccion = resultado.direccion;
      _envioTelefono = resultado.telefono;
      _imprimirGuiaAlConfirmar = resultado.imprimir;
      _formatoGuiaGrande = resultado.formatoGrande;
    });
  }

  void _quitarEnvio() {
    setState(() {
      _esEnvio = false;
      _envioNombre = '';
      _envioDireccion = '';
      _envioTelefono = '';
      _imprimirGuiaAlConfirmar = false;
    });
  }

  Widget _chipEnvio() {
    if (!_esEnvio) {
      return OutlinedButton.icon(
        onPressed: _abrirDatosEnvio,
        icon: const Icon(Icons.local_shipping_outlined, size: 16),
        label: Text(
          'Es envío',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1565C0),
          side: const BorderSide(color: Color(0xFF1565C0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1565C0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 17, color: Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Envío a $_envioNombre${_imprimirGuiaAlConfirmar ? ' · se imprime guía al confirmar' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _abrirDatosEnvio,
            child: Text('Editar', style: GoogleFonts.poppins(fontSize: 12)),
          ),
          TextButton(
            onPressed: _quitarEnvio,
            child: Text(
              'Quitar',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Marca.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarLimpiar() async {
    final carrito = ref.read(carritoVentaProvider);
    final hayAlgoQuePerder =
        carrito.items.isNotEmpty ||
        _nombreClienteController.text.trim().isNotEmpty;
    if (hayAlgoQuePerder) {
      final continuar = await _confirmarDialogo(
        'Limpiar venta',
        '¿Seguro que querés borrar todos los productos y datos ingresados en esta venta?',
      );
      if (!continuar) return;
    }
    _debounceEnEspera?.cancel();
    if (carrito.idEnEspera != null) {
      final usuario =
          ref.read(usuarioVentaOverrideProvider)?.nombreCompleto ??
          ref.read(authProvider).usuario?.nombreCompleto ??
          '';
      unawaited(
        ref
            .read(ventaRepositoryProvider)
            .eliminarVentaEnEspera(carrito.idEnEspera!, usuario: usuario),
      );
    }
    _limpiarTodo();
  }


  String get _textoBoton {
    final tipo = ref.watch(carritoVentaProvider).tipoDocumento;
    switch (tipo) {
      case 'Cotizacion':
        return 'Crear Cotización';
      case 'VentaSinFacturar':
        return 'Registrar Venta';
      default:
        return 'Crear Venta';
    }
  }

  Future<void> _confirmarVenta() async {
    final carrito = ref.read(carritoVentaProvider);
    if (carrito.items.isEmpty) {
      _mostrarMensaje('Debe ingresar productos en la venta');
      return;
    }

    var montoPago = 0.0;
    var montoCambio = 0.0;
    var pagosMixtos = const <PagoDetalle>[];
    final esCotizacion = carrito.esCotizacion;
    NegocioModel? negocio;
    final ventaRepo = ref.read(ventaRepositoryProvider);

    setState(() => _guardando = true);
    try {
      if (!esCotizacion) {
        if (carrito.condicion == 'Credito') {
          montoPago = 0;
          montoCambio = 0;
        } else if (carrito.metodoPago == 'Efectivo') {
          final resultado = await showDialog<CobrarResultado>(
            useRootNavigator: false,
            context: context,
            builder: (context) => CobrarDialog(total: carrito.totalAPagar),
          );
          if (resultado == null) return;
          montoPago = resultado.pagoCon;
          montoCambio = resultado.cambio;
        } else if (carrito.metodoPago == 'Mixto') {
          final resultado = await showDialog<List<PagoDetalle>>(
            context: context,
            builder: (context) => PagoMixtoDialog(total: carrito.totalAPagar),
          );
          if (resultado == null) return;
          pagosMixtos = resultado;
          montoPago = resultado.fold<double>(0, (s, p) => s + p.monto);
          montoCambio = 0;
        }

        negocio = await ref
            .read(negocioRepositoryProvider)
            .obtenerNegocioActual();
        if (!mounted) return;
        if (carrito.tipoDocumento == 'Factura' ||
            carrito.tipoDocumento == 'Boleta') {
          final continuar = await _validarFechaLimite(negocio);
          if (!continuar) return;
        }
      }
    } catch (e) {
      _mostrarMensaje('Error: $e');
      return;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }

    final usuario =
        ref.read(usuarioVentaOverrideProvider)?.nombreCompleto ??
        ref.read(authProvider).usuario?.nombreCompleto ??
        '';
    final categorias = ref.read(categoriasStreamProvider).value ?? [];
    final categoriasSinControlStock = categorias
        .where((c) => !c.controlaStock)
        .map((c) => c.id)
        .toSet();
    final esFacturable =
        carrito.tipoDocumento == 'Factura' || carrito.tipoDocumento == 'Boleta';
    final negocioFinal = negocio;
    final nombreCliente = _nombreClienteController.text.trim().isEmpty
        ? 'CONSUMIDOR FINAL'
        : _nombreClienteController.text.trim();
    final telefonoCredito = _telefonoCreditoController.text.trim();
    final esEnvio = _esEnvio;
    final envioNombre = _envioNombre;
    final envioDireccion = _envioDireccion;
    final envioTelefono = _envioTelefono;
    final imprimirGuiaAlConfirmar = _imprimirGuiaAlConfirmar;
    final formatoGuiaGrande = _formatoGuiaGrande;

    _limpiarTodo();
    if (!esCotizacion && mounted) mostrarExitoTransaccion(context);

    unawaited(
      _guardarVentaEnSegundoPlano(
        ventaRepo: ventaRepo,
        carrito: carrito,
        esCotizacion: esCotizacion,
        esFacturable: esFacturable,
        nombreCliente: nombreCliente,
        telefonoCredito: telefonoCredito,
        montoPago: montoPago,
        montoCambio: montoCambio,
        pagosMixtos: pagosMixtos,
        usuario: usuario,
        categoriasSinControlStock: categoriasSinControlStock,
        negocio: negocioFinal,
        esEnvio: esEnvio,
        envioNombre: envioNombre,
        envioDireccion: envioDireccion,
        envioTelefono: envioTelefono,
        imprimirGuiaAlConfirmar: imprimirGuiaAlConfirmar,
        formatoGuiaGrande: formatoGuiaGrande,
      ),
    );
  }

  Future<void> _guardarVentaEnSegundoPlano({
    required VentaRepository ventaRepo,
    required CarritoVentaState carrito,
    required bool esCotizacion,
    required bool esFacturable,
    required String nombreCliente,
    String telefonoCredito = '',
    required double montoPago,
    required double montoCambio,
    List<PagoDetalle> pagosMixtos = const [],
    required String usuario,
    required Set<String> categoriasSinControlStock,
    required NegocioModel? negocio,
    bool esEnvio = false,
    String envioNombre = '',
    String envioDireccion = '',
    String envioTelefono = '',
    bool imprimirGuiaAlConfirmar = false,
    bool formatoGuiaGrande = false,
  }) async {
    try {
      final venta = await ventaRepo.registrarVenta(
        tipoDocumento: carrito.tipoDocumento,
        condicion: esCotizacion ? 'Contado' : carrito.condicion,
        metodoPago: esCotizacion
            ? 'N/A'
            : (carrito.condicion == 'Credito' ? 'N/A' : carrito.metodoPago),
        documentoCliente: carrito.documentoCliente.trim().isEmpty
            ? 'N/A'
            : carrito.documentoCliente.trim(),
        nombreCliente: nombreCliente,
        idCliente: carrito.idCliente,
        fechaRegistro: carrito.fecha,
        fechaVencimiento: (!esCotizacion && carrito.condicion == 'Credito')
            ? carrito.fechaVencimiento
            : null,
        telefonoCredito: (!esCotizacion && carrito.condicion == 'Credito')
            ? telefonoCredito
            : null,
        oc: carrito.oc,
        regExonerado: carrito.regExonerado,
        regSag: carrito.regSag,
        observaciones: carrito.observaciones,
        descuentoGlobal: carrito.descuentoGlobalPorcentaje,
        items: carrito.items,
        montoPago: montoPago,
        montoCambio: montoCambio,
        pagosMixtos: esCotizacion ? const [] : pagosMixtos,
        subtotal: carrito.subtotal,
        impuesto: carrito.impuesto,
        totalAPagar: carrito.totalAPagar,
        usuario: usuario,
        categoriasSinControlStock: categoriasSinControlStock,
        esEnvio: esEnvio,
        envioNombre: envioNombre,
        envioDireccion: envioDireccion,
        envioTelefono: envioTelefono,
      );

      if (carrito.idEnEspera != null) {
        unawaited(
          ventaRepo.eliminarVentaEnEspera(
            carrito.idEnEspera!,
            usuario: usuario,
          ),
        );
      }

      if (!esCotizacion && esEnvio && imprimirGuiaAlConfirmar) {
        unawaited(_imprimirGuiaEnvio(venta, grande: formatoGuiaGrande));
      }

      if (!esCotizacion) {
        unawaited(_imprimirEnSegundoPlano(venta));
        if (esFacturable && negocio != null) {
          _avisarSiRangoSuperado(negocio, venta);
        }
      } else {
        _mostrarMensaje(
          '${tiposDocumento[venta.tipoDocumento]} generada: ${venta.numeroDocumento}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      final mensaje = e is TimeoutException
          ? 'No se pudo guardar: se agotó el tiempo de espera. Revisá la conexión a internet.'
          : 'No se pudo guardar: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠ $mensaje',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Marca.primario,
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _guardarVentaEnSegundoPlano(
              ventaRepo: ventaRepo,
              carrito: carrito,
              esCotizacion: esCotizacion,
              esFacturable: esFacturable,
              nombreCliente: nombreCliente,
              telefonoCredito: telefonoCredito,
              montoPago: montoPago,
              montoCambio: montoCambio,
              pagosMixtos: pagosMixtos,
              usuario: usuario,
              categoriasSinControlStock: categoriasSinControlStock,
              negocio: negocio,
              esEnvio: esEnvio,
              envioNombre: envioNombre,
              envioDireccion: envioDireccion,
              envioTelefono: envioTelefono,
              imprimirGuiaAlConfirmar: imprimirGuiaAlConfirmar,
              formatoGuiaGrande: formatoGuiaGrande,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _imprimirEnSegundoPlano(VentaModel venta) async {
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    if (!mounted) return;
    await _manejarImpresion(venta, negocio);
  }

  Future<void> _manejarImpresion(VentaModel venta, NegocioModel negocio) async {
    if (!negocio.imprimirFacturas) return;
    if (!kIsWeb && Platform.isAndroid) {
      await _manejarImpresionAndroid(venta, negocio);
      return;
    }

    if (negocio.modoImpresion != ModoImpresion.directo) {
      final impresora = negocio.impresoraTermicaUrl.isEmpty
          ? null
          : Printer(
              url: negocio.impresoraTermicaUrl,
              name: negocio.impresoraTermicaNombre,
            );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      showDialog(
        useRootNavigator: false,
        context: context,
        builder: (context) => PdfPreviewDialog(
          titulo: 'Vista previa · ${venta.numeroDocumento}',
          nombreArchivo: 'venta_${venta.numeroDocumento}.pdf',
          generarPdf: () => _servicioExport.generarPdfFactura(venta, negocio),
          generarPdfConFormato: (formato) => _servicioExport.generarPdfFactura(
            venta,
            negocio,
            formatoImpresora: formato,
          ),
          impresora: impresora,
          generarTicketEscPos: () =>
              _servicioTicketEscPos.generarTicket(venta, negocio),
          nombreImpresoraWindows: negocio.impresoraUsbUsarDriverWindows
              ? null
              : negocio.impresoraTermicaNombre,
          vistaPreviaTicket: () => TicketEscPosPreview(
            venta: venta,
            negocio: negocio,
            esCopia: false,
          ),
          alFallarImprimir: () => _intentarImpresionRemota(venta),
        ),
      );
      return;
    }

    final esMovil =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (kIsWeb && esMovil) {
      final ventaRepoLocal = ref.read(ventaRepositoryProvider);
      final futurePendiente = ventaRepoLocal.marcarPendienteImpresion(
        venta.id,
        true,
      );
      final pcConectada = await ref
          .read(presenciaImpresionRepositoryProvider)
          .estaConectada();
      if (pcConectada) {
        await ventaRepoLocal.marcarSolicitudImpresionEnVivo(venta.id, true);
        _mostrarMensaje('Se envió la orden de impresión a la caja principal');
      } else {
        _mostrarMensaje(
          'No se puede imprimir directo desde el navegador del celular: la venta quedó pendiente de impresión',
        );
      }
      await futurePendiente;
      return;
    }

    if (kIsWeb) {
      ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? preparando;
      if (mounted) {
        preparando = ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando impresión…'),
            duration: Duration(seconds: 30),
          ),
        );
      }
      try {
        await Printing.layoutPdf(
          onLayout: (formato) =>
              _servicioExport.generarPdfFactura(venta, negocio),
          name: 'venta_${venta.numeroDocumento}.pdf',
        );
        preparando?.close();
      } catch (_) {
        preparando?.close();
        _mostrarMensaje(
          'No se pudo imprimir. La venta se guardó de todas formas.',
        );
      }
      return;
    }

    if (Platform.isIOS) {
      await _imprimirEscPosRed(venta, negocio);
      return;
    }

    if (negocio.impresoraTermicaUrl.isEmpty) {
      await _intentarImpresionRemota(venta);
      return;
    }
    if (!kIsWeb && Platform.isWindows && !negocio.impresoraUsbUsarDriverWindows) {
      try {
        final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio);
        final ok = ImpresoraUsbWindowsService().imprimir(
          nombreImpresora: negocio.impresoraTermicaNombre,
          bytes: bytes,
        );
        if (!ok) await _intentarImpresionRemota(venta);
      } catch (_) {
        await _intentarImpresionRemota(venta);
      }
      return;
    }
    try {
      if (!await calentarImpresionWindows(nombreImpresora: negocio.impresoraTermicaNombre)) {
        await _intentarImpresionRemota(venta);
        return;
      }
      final impresora = Printer(
        url: negocio.impresoraTermicaUrl,
        name: negocio.impresoraTermicaNombre,
      );
      await Printing.directPrintPdf(
        printer: impresora,
        onLayout: (formato) => _servicioExport.generarPdfFactura(
          venta,
          negocio,
          formatoImpresora: formato,
        ),
      );
    } catch (_) {
      await _intentarImpresionRemota(venta);
    }
  }

  Future<void> _intentarImpresionRemota(VentaModel venta) async {
    final ventaRepoLocal = ref.read(ventaRepositoryProvider);
    final futurePendiente = ventaRepoLocal.marcarPendienteImpresion(
      venta.id,
      true,
    );
    final pcConectada = await ref
        .read(presenciaImpresionRepositoryProvider)
        .estaConectada();
    if (pcConectada) {
      await ventaRepoLocal.marcarSolicitudImpresionEnVivo(venta.id, true);
      _mostrarMensaje(
        'No se pudo imprimir acá: se envió la orden a la PC principal',
      );
    } else {
      _mostrarMensaje(
        'No se pudo imprimir, la venta quedó pendiente de impresión',
      );
    }
    await futurePendiente;
  }

  Future<void> _imprimirGuiaEnvio(
    VentaModel venta, {
    bool grande = false,
  }) async {
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    if (!mounted) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _imprimirGuiaEscPosRedOPendiente(venta, negocio, grande);
      return;
    }

    try {
      final bytes = await _servicioTicketEscPos.generarGuiaEnvio(
        venta,
        negocio,
        grande: grande,
      );
      if (!kIsWeb && Platform.isWindows) {
        if (negocio.impresoraTermicaNombre.isEmpty) {
          _mostrarMensaje(
            'No hay impresora configurada, no se pudo imprimir la guía de envío',
          );
          return;
        }
        if (negocio.impresoraUsbUsarDriverWindows) {
          _mostrarMensaje(
            'Esta impresora no soporta la guía de envío (activaste "usar el driver de Windows"): usá el ticket normal',
          );
          return;
        }
        final ok = ImpresoraUsbWindowsService().imprimir(
          nombreImpresora: negocio.impresoraTermicaNombre,
          bytes: bytes,
        );
        if (!ok) _mostrarMensaje('No se pudo imprimir la guía de envío');
      } else if (negocio.impresoraUsbUsarDriverWindows) {
        _mostrarMensaje(
          'Esta impresora no soporta la guía de envío (activaste "usar el driver de Windows"): usá el ticket normal',
        );
      } else if (negocio.impresoraRedIp.isNotEmpty) {
        final ok = await _servicioImpresoraRed.imprimir(
          ip: negocio.impresoraRedIp,
          puerto: negocio.impresoraRedPuerto,
          bytes: bytes,
        );
        if (!ok) _mostrarMensaje('No se pudo imprimir la guía de envío');
      } else {
        _mostrarMensaje(
          'No hay impresora configurada, no se pudo imprimir la guía de envío',
        );
      }
    } catch (_) {
      _mostrarMensaje('No se pudo imprimir la guía de envío');
    }
  }

  Future<void> _imprimirGuiaEscPosRedOPendiente(
    VentaModel venta,
    NegocioModel negocio,
    bool grande,
  ) async {
    if (!negocio.impresoraUsbUsarDriverWindows && negocio.impresoraRedIp.isNotEmpty) {
      try {
        final bytes = await _servicioTicketEscPos.generarGuiaEnvio(
          venta,
          negocio,
          grande: grande,
        );
        final ok = await _servicioImpresoraRed.imprimir(
          ip: negocio.impresoraRedIp,
          puerto: negocio.impresoraRedPuerto,
          bytes: bytes,
        );
        if (ok) {
          _mostrarMensaje('Guía de envío impresa');
          return;
        }
      } catch (_) {
      }
    }
    if (!mounted) return;
    try {
      await ref
          .read(ventaRepositoryProvider)
          .marcarSolicitudImpresionGuiaEnvio(venta.id, true, grande: grande);
    } catch (_) {}
    final pcConectada = await ref
        .read(presenciaImpresionRepositoryProvider)
        .estaConectada();
    if (!mounted) return;
    if (pcConectada) {
      _mostrarMensaje(
        'Se envió la orden de impresión de la guía a la caja principal',
      );
    } else {
      _mostrarMensaje(
        'No se pudo imprimir la guía desde este dispositivo: quedó pendiente para la caja principal',
      );
    }
  }

  Future<void> _manejarImpresionAndroid(
    VentaModel venta,
    NegocioModel negocio,
  ) async {
    if (!mounted) return;
    final opcion = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Venta ${venta.numeroDocumento} registrada',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          '¿Qué querés hacer con el ticket?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'pendiente'),
            child: Text('Dejar pendiente', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'sistema'),
            child: Text(
              'Impresora del sistema',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Marca.primario,
            ),
            onPressed: () => Navigator.pop(context, 'imprimir'),
            child: Text('Bluetooth/red', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (opcion == 'imprimir') {
      await _imprimirEscPosRed(venta, negocio);
    } else if (opcion == 'sistema') {
      await _imprimirConDialogoSistema(venta, negocio);
    } else {
      await ref
          .read(ventaRepositoryProvider)
          .marcarPendienteImpresion(venta.id, true);
    }
  }

  Future<void> _imprimirConDialogoSistema(
    VentaModel venta,
    NegocioModel negocio,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (formato) =>
            _servicioExport.generarPdfFactura(venta, negocio),
        name: 'venta_${venta.numeroDocumento}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje(
        'No se pudo abrir el diálogo de impresión. La venta se guardó de todas formas.',
      );
    }
  }

  Future<void> _imprimirEscPosRed(
    VentaModel venta,
    NegocioModel negocio,
  ) async {
    if (!negocio.impresoraUsbUsarDriverWindows) {
      if (!kIsWeb && Platform.isAndroid && negocio.impresoraBluetoothId.isNotEmpty) {
        try {
          final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio);
          final ok = await _servicioImpresoraBluetooth.imprimir(
            macAddress: negocio.impresoraBluetoothId,
            bytes: bytes,
          );
          if (ok) return;
        } catch (_) {
        }
      }
      if (negocio.impresoraRedIp.isNotEmpty) {
        try {
          final bytes = await _servicioTicketEscPos.generarTicket(venta, negocio);
          final ok = await _servicioImpresoraRed.imprimir(
            ip: negocio.impresoraRedIp,
            puerto: negocio.impresoraRedPuerto,
            bytes: bytes,
          );
          if (ok) return;
        } catch (_) {
        }
      }
    }
    final ventaRepoLocal = ref.read(ventaRepositoryProvider);
    final futurePendiente = ventaRepoLocal.marcarPendienteImpresion(
      venta.id,
      true,
    );
    final pcConectada = await ref
        .read(presenciaImpresionRepositoryProvider)
        .estaConectada();
    if (pcConectada) {
      await ventaRepoLocal.marcarSolicitudImpresionEnVivo(venta.id, true);
      _mostrarMensaje('Se envió la orden de impresión a la caja principal');
    } else {
      _mostrarMensaje(
        'No se pudo imprimir: la venta quedó pendiente de impresión',
      );
    }
    await futurePendiente;
  }

  Future<bool> _validarFechaLimite(NegocioModel negocio) async {
    if (negocio.fechaLimiteEmision != null) {
      final hoy = DateTime.now();
      final limite = negocio.fechaLimiteEmision!;
      final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
      final limiteSinHora = DateTime(limite.year, limite.month, limite.day);
      if (!hoySinHora.isBefore(limiteSinHora)) {
        final continuar = await _confirmarDialogo(
          '¡Alerta!',
          'Se ha alcanzado la fecha límite de emisión. ¿Desea continuar con la venta?',
        );
        if (!continuar) return false;
      }
    }
    return true;
  }

  void _avisarSiRangoSuperado(NegocioModel negocio, VentaModel venta) {
    final rangoHasta = int.tryParse(negocio.rangoHasta) ?? 0;
    if (rangoHasta <= 0) return;
    final numero = int.tryParse(venta.numeroDocumento) ?? 0;
    if (numero > rangoHasta) {
      _mostrarMensaje(
        'Atención: se superó el rango autorizado para facturas (No. ${venta.numeroDocumento})',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoVentaProvider);
    ref.watch(categoriasStreamProvider);
    ref.listen<CarritoVentaState>(carritoVentaProvider, (previous, next) {
      _programarAutoguardadoEnEspera(next);
      _verificarCreditoVencido(next);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refrescarDialogoExpandido?.call(() {}),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refrescarModalDatosVenta?.call(() {}),
    );
    if (_esWebMovil) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _alScrollearMovil());
    }
    _sincronizarControladoresItems(carrito);
    final vista = ref.watch(registrarVentaVistaProvider);

    return Focus(
      focusNode: _focusAnclaMovil,
      canRequestFocus: true,
      skipTraversal: true,
      child: Container(
        color: const Color(0xFFF2F3F7),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 900;
            final altoMaximoTabla = (constraints.maxHeight * 0.72).clamp(
              420.0,
              1400.0,
            );
            final productos =
                ref.watch(productosStreamProvider).value ??
                const <ProductoModel>[];
            final mapaProductos = {for (final p in productos) p.id: p};

            final Widget contenido = switch (vista) {
              registrarVentaVistaDividida => _layoutDividido(
                carrito,
                esMovil,
                mapaProductos,
              ),
              registrarVentaVistaDynamics => _layoutDynamics(
                carrito,
                esMovil,
                mapaProductos,
              ),
              _ => _layoutClasico(carrito, esMovil, altoMaximoTabla),
            };

            final Widget pantalla =
                (_esWebMovil && vista == registrarVentaVistaClasica)
                ? Stack(children: [contenido, _barraFlotanteTotales(carrito)])
                : contenido;

            return Stack(
              children: [
                pantalla,
                Positioned(top: 0, right: 0, child: _botonSelectorVista(vista)),

              ],
            );
          },
        ),
      ),
    );
  }


  Widget _layoutClasico(
    CarritoVentaState carrito,
    bool esMovil,
    double altoMaximoTabla,
  ) {
    return SingleChildScrollView(
      controller: _esWebMovil ? _scrollControllerMovil : null,
      padding: EdgeInsets.all(esMovil ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado(esMovil),
          const SizedBox(height: 14),
          _tarjetaDatosVenta(carrito, esMovil),
          const SizedBox(height: 14),
          _tarjetaCarritoGrande(
            carrito,
            esMovil,
            altoMaximoTabla: altoMaximoTabla,
          ),
          const SizedBox(height: 14),
          _tarjetaTotales(carrito, esMovil),
        ],
      ),
    );
  }

  Widget _layoutDividido(
    CarritoVentaState carrito,
    bool esMovil,
    Map<String, ProductoModel> mapaProductos,
  ) {
    if (esMovil) return _layoutDivididoMovil(carrito, mapaProductos);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barraSuperiorCompacta(carrito, esMovil),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _tarjeta(
                    child: PanelBuscadorGrid(
                      onProductoElegido: (p) =>
                          _procesarProductoSeleccionado(p),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: _tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _barraAccionesCarritoCompacta(
                          mostrarAgregarProducto: false,
                        ),
                        Offstage(offstage: true, child: _campoCodigoBarras()),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _bloqueTablaCarritoMovil(
                            carrito,
                            mapaProductos,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _barraTotalesCompacta(carrito),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _layoutDivididoMovil(
    CarritoVentaState carrito,
    Map<String, ProductoModel> mapaProductos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: _barraSuperiorCompacta(carrito, true),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: _segmentoDividida('buscar', 'Buscar', Icons.search),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _segmentoDividida(
                  'carrito',
                  'Carrito (${carrito.items.length})',
                  Icons.shopping_cart_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Offstage(offstage: true, child: _campoCodigoBarras()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _panelMovilDividida == 'buscar'
                ? _tarjeta(
                    child: PanelBuscadorGrid(
                      onProductoElegido: (p) =>
                          _procesarProductoSeleccionado(p),
                    ),
                  )
                : _tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _barraAccionesCarritoCompacta(
                          mostrarAgregarProducto: false,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _bloqueTablaCarritoMovil(
                            carrito,
                            mapaProductos,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _barraTotalesCompacta(carrito),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _segmentoDividida(String valor, String texto, IconData icono) {
    final activo = _panelMovilDividida == valor;
    return InkWell(
      onTap: () => setState(() => _panelMovilDividida = valor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? Marca.primario : const Color(0xFFE8EAF0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 16,
              color: activo ? Colors.white : const Color(0xFF4B4F58),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: activo ? Colors.white : const Color(0xFF25272B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layoutDynamics(
    CarritoVentaState carrito,
    bool esMovil,
    Map<String, ProductoModel> mapaProductos,
  ) {
    return Padding(
      padding: EdgeInsets.all(esMovil ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barraSuperiorDynamics(carrito, esMovil),
          const SizedBox(height: 6),
          Offstage(offstage: true, child: _campoCodigoBarras()),
          Expanded(
            child: _tarjeta(
              child: esMovil
                  ? _bloqueTablaCarritoMovil(carrito, mapaProductos)
                  : _bloqueTablaCarrito(carrito, mapaProductos),
            ),
          ),
          const SizedBox(height: 8),
          _barraTotalesCompacta(carrito, destacarTotal: true),
        ],
      ),
    );
  }

  Widget _sinProductosEnCarrito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Todavía no agregaste productos.\nUsá "Agregar Producto" para buscar del inventario.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _bloqueTablaCarrito(
    CarritoVentaState carrito,
    Map<String, ProductoModel> mapaProductos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _encabezadoTablaCarrito(),
        Divider(height: 18, color: Colors.grey.shade300),
        Expanded(
          child: carrito.items.isEmpty
              ? _sinProductosEnCarrito()
              : ListView.separated(
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
    );
  }

  Widget _bloqueTablaCarritoMovil(
    CarritoVentaState carrito,
    Map<String, ProductoModel> mapaProductos,
  ) {
    if (carrito.items.isEmpty) return _sinProductosEnCarrito();
    return ListView.separated(
      itemCount: carrito.items.length,
      separatorBuilder: (context, i) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, i) => _filaCarritoMovil(
        i,
        carrito.items[i],
        mapaProductos,
        carrito.items.length,
      ),
    );
  }

  Widget _barraSuperiorDynamics(CarritoVentaState carrito, bool esMovil) {
    final nombreCliente = _nombreClienteController.text.trim().isEmpty
        ? 'Consumidor final'
        : _nombreClienteController.text.trim();

    final chipCliente = InkWell(
      onTap: () => _abrirDatosVentaModal(esMovil, disenioAmplio: true),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: BoxConstraints(maxWidth: esMovil ? 150 : 170),
        padding: EdgeInsets.symmetric(
          horizontal: esMovil ? 8 : 10,
          vertical: esMovil ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFDFE1E6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                nombreCliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: esMovil ? 10.5 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (esMovil) {
      return Row(
        children: [
          chipCliente,
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _barraAccionesCarritoCompacta(compacta: true),
            ),
          ),
          const SizedBox(width: 4),
          _botonMenuAccionesVenta(),
        ],
      );
    }

    final controles = <Widget>[
      chipCliente,
      _botonCompacto(
        icono: Icons.add_circle,
        texto: 'Agregar Producto',
        onPressed: _agregarProductoDesdeBusqueda,
        destacado: true,
      ),
      if (_esPlataformaMovil)
        _iconoCompacto(
          icono: Icons.qr_code_scanner,
          tooltip: 'Escanear con cámara',
          onPressed: _escanearConCamara,
        )
      else
        _iconoCompacto(
          icono: _escaneoRemotoConectado
              ? Icons.wifi_tethering
              : Icons.qr_code_scanner,
          tooltip: _escaneoRemotoConectado
              ? 'Escaneo activo'
              : 'Escanear con celular',
          onPressed: _abrirEscaneoRemoto,
          color: _escaneoRemotoConectado ? Colors.green.shade600 : null,
        ),
      _iconoCompacto(
        icono: Icons.local_offer_outlined,
        tooltip: 'Ver promociones vigentes',
        onPressed: _abrirPromocionesVigentes,
      ),
      _selectorPrecioIsvCarrito(compacto: true),
      _botonCompacto(
        icono: Icons.pause_circle_outline,
        texto: 'Guardar en Espera',
        onPressed: _guardarEnEspera,
      ),
      _botonCompacto(
        icono: Icons.list_alt_outlined,
        texto: 'Ver en Espera',
        onPressed: _verEnEspera,
      ),
      _botonCompacto(
        icono: Icons.find_in_page_outlined,
        texto: 'Ver Perdidas',
        onPressed: _verPerdidas,
      ),
      _botonCompacto(
        icono: Icons.receipt_long_outlined,
        texto: 'Ver Facturas',
        onPressed: _verFacturas,
      ),
      Badge(
        label: Text('$_cantidadPendientesImpresion'),
        backgroundColor: const Color(0xFFE0A63C),
        isLabelVisible: _cantidadPendientesImpresion > 0,
        child: _botonCompacto(
          icono: Icons.print_disabled_outlined,
          texto: 'Pendientes de Impresión',
          onPressed: _verPendientesImpresion,
        ),
      ),
      _botonCompacto(
        icono: Icons.delete_sweep_outlined,
        texto: 'Limpiar Venta',
        onPressed: _confirmarLimpiar,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < controles.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            controles[i],
          ],
        ],
      ),
    );
  }

  Widget _botonCompacto({
    required IconData icono,
    required String texto,
    required VoidCallback onPressed,
    bool destacado = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 15),
      label: Text(
        texto,
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: destacado ? Colors.white : const Color(0xFF1A1A1A),
        backgroundColor: destacado ? Marca.primario : Colors.white,
        side: BorderSide(
          color: destacado ? Marca.primario : const Color(0xFFDFE1E6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _iconoCompacto({
    required IconData icono,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icono, size: 17, color: color ?? Colors.grey.shade600),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDFE1E6)),
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        visualDensity: VisualDensity.compact,
        splashRadius: 16,
      ),
    );
  }

  Widget _botonMenuAccionesVenta() {
    Widget item(IconData icono, String texto) {
      return Row(
        children: [
          Icon(icono, size: 18, color: const Color(0xFF4B4F58)),
          const SizedBox(width: 10),
          Text(texto, style: GoogleFonts.poppins(fontSize: 12.5)),
        ],
      );
    }

    return Badge(
      label: Text('$_cantidadPendientesImpresion'),
      backgroundColor: const Color(0xFFE0A63C),
      isLabelVisible: _cantidadPendientesImpresion > 0,
      child: PopupMenuButton<String>(
        tooltip: 'Más acciones',
        icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF4B4F58)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (valor) {
          switch (valor) {
            case 'usuario':
              _cambiarUsuarioVenta();
              break;
            case 'limpiar':
              _confirmarLimpiar();
              break;
            case 'guardar_espera':
              _guardarEnEspera();
              break;
            case 'ver_espera':
              _verEnEspera();
              break;
            case 'ver_perdidas':
              _verPerdidas();
              break;
            case 'ver_facturas':
              _verFacturas();
              break;
            case 'pendientes':
              _verPendientesImpresion();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'usuario',
            child: item(Icons.person_outline, 'Cambiar usuario'),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'limpiar',
            child: item(Icons.delete_sweep_outlined, 'Limpiar Venta'),
          ),
          PopupMenuItem(
            value: 'guardar_espera',
            child: item(Icons.pause_circle_outline, 'Guardar en Espera'),
          ),
          PopupMenuItem(
            value: 'ver_espera',
            child: item(Icons.list_alt_outlined, 'Ver en Espera'),
          ),
          PopupMenuItem(
            value: 'ver_perdidas',
            child: item(Icons.find_in_page_outlined, 'Ver Perdidas'),
          ),
          PopupMenuItem(
            value: 'ver_facturas',
            child: item(Icons.receipt_long_outlined, 'Ver Facturas'),
          ),
          PopupMenuItem(
            value: 'pendientes',
            child: item(
              Icons.print_disabled_outlined,
              'Pendientes de Impresión',
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraSuperiorCompacta(CarritoVentaState carrito, bool esMovil) {
    final nombreCliente = _nombreClienteController.text.trim().isEmpty
        ? 'Consumidor final'
        : _nombreClienteController.text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE1E6)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _chipCompacto(
            carrito.esCotizacion ? 'Cotización' : carrito.condicion,
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () => _abrirDatosVentaModal(esMovil),
            icon: const Icon(Icons.tune, size: 16),
            label: Text(
              esMovil ? '' : 'Datos y acciones',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipCompacto(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3F434A),
        ),
      ),
    );
  }

  void _abrirDatosVentaModal(bool esMovil, {bool disenioAmplio = false}) {
    if (!disenioAmplio) {
      showDialog(
        useRootNavigator: false,
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  _refrescarModalDatosVenta = setDialogState;
                  final carritoActual = ref.read(carritoVentaProvider);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Datos de la venta',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _encabezado(esMovil),
                        const SizedBox(height: 14),
                        _tarjetaDatosVenta(carritoActual, esMovil),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ).then((_) => _refrescarModalDatosVenta = null);
      return;
    }

    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (dialogContext) {
        final tamano = MediaQuery.of(dialogContext).size;
        final anchoDialog = esMovil
            ? tamano.width - 24
            : (tamano.width - 100).clamp(0, 820).toDouble();
        final altoDialog = (tamano.height - 60).clamp(0, 820).toDouble();
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: anchoDialog,
              maxHeight: altoDialog,
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                _refrescarModalDatosVenta = setDialogState;
                final carritoActual = ref.read(carritoVentaProvider);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(esMovil ? 18 : 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0F1B3D,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: Marca.primario,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos de la Venta',
                                  style: GoogleFonts.poppins(
                                    fontSize: esMovil ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Cliente, documento y condición de pago',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _tarjetaDatosVenta(
                        carritoActual,
                        esMovil,
                        disenioAmplio: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) => _refrescarModalDatosVenta = null);
  }

  Widget _barraAccionesCarritoCompacta({
    bool mostrarAgregarProducto = true,
    bool compacta = false,
  }) {
    final botones = <Widget>[
      if (mostrarAgregarProducto)
        compacta
            ? _botonAccionChico(
                icono: Icons.add_circle,
                tooltip: 'Agregar Producto',
                onPressed: _agregarProductoDesdeBusqueda,
                color: Marca.primario,
              )
            : FilledButton.icon(
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      if (_esPlataformaMovil)
        compacta
            ? _botonAccionChico(
                icono: Icons.qr_code_scanner,
                tooltip: 'Escanear con cámara',
                onPressed: _escanearConCamara,
              )
            : IconButton(
                tooltip: 'Escanear con cámara',
                onPressed: _escanearConCamara,
                icon: Icon(Icons.qr_code_scanner, color: Colors.grey.shade600),
              ),
      if (!_esPlataformaMovil)
        compacta
            ? _botonAccionChico(
                icono: _escaneoRemotoConectado
                    ? Icons.wifi_tethering
                    : Icons.qr_code_scanner,
                tooltip: _escaneoRemotoConectado
                    ? 'Escaneo activo'
                    : 'Escanear con celular',
                onPressed: _abrirEscaneoRemoto,
                color: _escaneoRemotoConectado ? Colors.green.shade600 : null,
              )
            : IconButton(
                tooltip: _escaneoRemotoConectado
                    ? 'Escaneo activo'
                    : 'Escanear con celular',
                onPressed: _abrirEscaneoRemoto,
                icon: Icon(
                  _escaneoRemotoConectado
                      ? Icons.wifi_tethering
                      : Icons.qr_code_scanner,
                  color: _escaneoRemotoConectado
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                ),
              ),
      compacta
          ? _botonAccionChico(
              icono: Icons.local_offer_outlined,
              tooltip: 'Ver promociones vigentes',
              onPressed: _abrirPromocionesVigentes,
            )
          : IconButton(
              tooltip: 'Ver promociones vigentes',
              onPressed: _abrirPromocionesVigentes,
              icon: Icon(
                Icons.local_offer_outlined,
                color: Colors.grey.shade600,
              ),
            ),
      _selectorPrecioIsvCarrito(compacto: compacta),
    ];
    if (compacta) {
      return Row(mainAxisSize: MainAxisSize.min, children: botones);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: botones,
    );
  }

  Widget _botonAccionChico({
    required IconData icono,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icono, size: 16, color: color ?? Colors.grey.shade600),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        visualDensity: VisualDensity.compact,
        splashRadius: 16,
      ),
    );
  }

  Widget _botonSelectorVista(String vistaActual) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 10),
      child: PopupMenuButton<String>(
        tooltip: 'Vista de la pantalla',
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDFE1E6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.dashboard_customize_outlined,
            size: 19,
            color: Color(0xFF4B4F58),
          ),
        ),
        onSelected: (valor) =>
            ref.read(registrarVentaVistaProvider.notifier).elegir(valor),
        itemBuilder: (context) => [
          _opcionVista(
            registrarVentaVistaClasica,
            'Clásica',
            Icons.view_agenda_outlined,
            vistaActual,
          ),
          _opcionVista(
            registrarVentaVistaDividida,
            'Dividida',
            Icons.vertical_split_outlined,
            vistaActual,
          ),
          _opcionVista(
            registrarVentaVistaDynamics,
            'Tabla grande',
            Icons.table_rows_outlined,
            vistaActual,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _opcionVista(
    String valor,
    String texto,
    IconData icono,
    String vistaActual,
  ) {
    final activo = vistaActual == valor;
    return PopupMenuItem<String>(
      value: valor,
      child: Row(
        children: [
          Icon(
            icono,
            size: 18,
            color: activo ? Marca.primario : const Color(0xFF4B4F58),
          ),
          const SizedBox(width: 10),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
              color: activo ? Marca.primario : const Color(0xFF25272B),
            ),
          ),
          if (activo) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, size: 16, color: Marca.primario),
          ],
        ],
      ),
    );
  }

  Widget _barraFlotanteTotales(CarritoVentaState carrito) {
    final visible = _mostrarBarraFlotante && carrito.items.isNotEmpty;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: 12,
      right: 12,
      bottom: visible ? 12 : -100,
      child: IgnorePointer(
        ignoring: !visible,
        child: Material(
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF1A1A1A),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _guardando ? null : _confirmarVenta,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL A PAGAR',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          formatearMoneda(carrito.totalAPagar),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Marca.primario,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _textoBoton,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
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
          'Registrar Venta',
          style: GoogleFonts.poppins(
            fontSize: esMovil ? 19 : 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        _chipUsuarioVenta(),
        OutlinedButton.icon(
          onPressed: _confirmarLimpiar,
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: Text(
            'Limpiar Venta',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          key: _keyGuardarEnEspera,
          onPressed: _guardarEnEspera,
          icon: const Icon(Icons.pause_circle_outline, size: 18),
          label: Text(
            'Guardar en Espera',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          onPressed: _verEnEspera,
          icon: const Icon(Icons.list_alt_outlined, size: 18),
          label: Text(
            'Ver en Espera',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          onPressed: _verPerdidas,
          icon: const Icon(Icons.find_in_page_outlined, size: 18),
          label: Text('Ver Perdidas', style: GoogleFonts.poppins(fontSize: 13)),
          style: _estiloBotonSecundario(),
        ),
        OutlinedButton.icon(
          onPressed: _verFacturas,
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: Text('Ver Facturas', style: GoogleFonts.poppins(fontSize: 13)),
          style: _estiloBotonSecundario(),
        ),
        Badge(
          label: Text('$_cantidadPendientesImpresion'),
          backgroundColor: const Color(0xFFE0A63C),
          isLabelVisible: _cantidadPendientesImpresion > 0,
          child: OutlinedButton.icon(
            onPressed: _verPendientesImpresion,
            icon: const Icon(Icons.print_disabled_outlined, size: 18),
            label: Text(
              'Pendientes de Impresión',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            style: _estiloBotonSecundario(),
          ),
        ),
      ],
    );
  }

  Widget _chipUsuarioVenta() {
    final override = ref.watch(usuarioVentaOverrideProvider);
    final sesion = ref.watch(authProvider).usuario;
    final actual = override ?? sesion;
    final esOverride = override != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: esOverride ? const Color(0xFFFFF3E0) : const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(12),
        border: esOverride ? Border.all(color: const Color(0xFFE0A63C)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 18,
            color: esOverride
                ? const Color(0xFF9A6A00)
                : const Color(0xFF1A1A1A),
          ),
          const SizedBox(width: 6),
          Text(
            'Vendiendo como: ${actual?.nombreCompleto ?? '-'}',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: esOverride
                  ? const Color(0xFF9A6A00)
                  : const Color(0xFF1A1A1A),
            ),
          ),
          if (esOverride) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: _quitarUsuarioVenta,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.undo, size: 16, color: Color(0xFF9A6A00)),
              ),
            ),
          ],
          const SizedBox(width: 2),
          InkWell(
            onTap: _cambiarUsuarioVenta,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.swap_horiz,
                size: 16,
                color: esOverride
                    ? const Color(0xFF9A6A00)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarUsuarioVenta() async {
    final usuario = await mostrarCambiarUsuarioVentaDialog(context, ref);
    if (usuario == null || !mounted) return;
    ref.read(usuarioVentaOverrideProvider.notifier).cambiar(usuario);
  }

  void _quitarUsuarioVenta() {
    ref.read(usuarioVentaOverrideProvider.notifier).quitar();
  }

  int get _cantidadPendientesImpresion =>
      ref.watch(ventasPendientesImpresionStreamProvider).value?.length ?? 0;

  void _verFacturas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const VerFacturasScreen(),
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

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 12.5),
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

  Widget _seccionDatos({
    required IconData icono,
    required String titulo,
    required List<Widget> campos,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: Marca.primario),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B4F58),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: campos,
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDatosVenta(
    CarritoVentaState carrito,
    bool esMovil, {
    bool disenioAmplio = false,
  }) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    if (!disenioAmplio) {
      return _tarjetaDatosVentaOriginal(carrito, esMovil, formatoFecha);
    }

    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionDatos(
            icono: Icons.person_outline,
            titulo: 'CLIENTE',
            campos: [
              SizedBox(
                width: esMovil ? double.infinity : 360,
                child: Row(
                  children: [
                    Expanded(
                      child: carrito.idCliente != null
                          ? _chipClienteVinculado()
                          : CompositedTransformTarget(
                              link: _clienteLayerLink,
                              child: TapRegion(
                                groupId: 'sugerencias-cliente',
                                onTapOutside: (_) =>
                                    _ocultarSugerenciasCliente(),
                                child: CampoTecladoCompacto(
                                  controller: _nombreClienteController,
                                  numerico: false,
                                  titulo: 'Vacío = Consumidor Final',
                                  child: TextField(
                                    inputFormatters: [mayusculasInputFormatter],
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    controller: _nombreClienteController,
                                    focusNode: _focusNombreCliente,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    decoration: _decoracion('Cliente').copyWith(
                                      hintText: 'Vacío = Consumidor Final',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      ref
                                          .read(carritoVentaProvider.notifier)
                                          .establecerNombreClienteManual(v);
                                      if (_clienteVinculado != null)
                                        setState(
                                          () => _clienteVinculado = null,
                                        );
                                      _actualizarSugerenciasCliente(v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _buscarCliente,
                      icon: const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EAF0),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (carrito.idCliente != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Completar datos del cliente',
                        onPressed: _completarDatosCliente,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE8EAF0),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 200,
                child: CampoTecladoCompacto(
                  controller: _documentoClienteController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _documentoClienteController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('RTN / Documento'),
                    onChanged: (v) {
                      ref
                          .read(carritoVentaProvider.notifier)
                          .establecerDocumentoCliente(v);
                      if (_clienteVinculado != null)
                        setState(() => _clienteVinculado = null);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _seccionDatos(
            icono: Icons.description_outlined,
            titulo: 'DOCUMENTO Y CONDICIÓN',
            campos: [
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
                          .read(carritoVentaProvider.notifier)
                          .establecerFecha(fecha);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDFE1E6)),
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
                width: esMovil ? double.infinity : 190,
                child: DropdownButtonFormField<String>(
                  initialValue: carrito.tipoDocumento,
                  isExpanded: true,
                  decoration: _decoracion('Tipo de documento'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A1A),
                  ),
                  items: tiposDocumento.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(carritoVentaProvider.notifier)
                        .establecerTipoDocumento(v);
                  },
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 150,
                child: DropdownButtonFormField<String>(
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
                  onChanged: carrito.esCotizacion
                      ? null
                      : (v) {
                          if (v == null) return;
                          ref
                              .read(carritoVentaProvider.notifier)
                              .establecerCondicion(v);
                        },
                ),
              ),
              if (!carrito.esCotizacion && carrito.condicion != 'Credito')
                SizedBox(
                  width: esMovil ? double.infinity : 160,
                  child: DropdownButtonFormField<String>(
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
                          .read(carritoVentaProvider.notifier)
                          .establecerMetodoPago(v);
                    },
                  ),
                ),
            ],
          ),
          if (carrito.esCredito && !carrito.esCotizacion) ...[
            const SizedBox(height: 14),
            _seccionDatos(
              icono: Icons.credit_score_outlined,
              titulo: 'DATOS DEL CRÉDITO',
              campos: [
                SizedBox(
                  width: esMovil ? double.infinity : 160,
                  child: InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate:
                            carrito.fechaVencimiento ??
                            DateTime.now().add(const Duration(days: 15)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null)
                        ref
                            .read(carritoVentaProvider.notifier)
                            .establecerFechaVencimiento(fecha);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDFE1E6)),
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
                ),
                SizedBox(
                  width: esMovil ? double.infinity : 220,
                  child: CampoTecladoCompacto(
                    controller: _telefonoCreditoController,
                    numerico: false,
                    child: TextField(
                      controller: _telefonoCreditoController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: _decoracion(
                        'Teléfono para avisos de crédito',
                      ),
                      onChanged: (v) => ref
                          .read(carritoVentaProvider.notifier)
                          .establecerTelefonoCredito(v),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_saldoVencidoCliente != null) ...[
            const SizedBox(height: 14),
            _avisoCreditoVencido(_saldoVencidoCliente!),
          ],
          const SizedBox(height: 14),
          _seccionDatos(
            icono: Icons.tune,
            titulo: 'DESCUENTO Y DATOS FISCALES',
            campos: [
              SizedBox(
                width: esMovil ? double.infinity : 280,
                child: CampoTecladoCompacto(
                  controller: _descuentoGlobalController,
                  numerico: true,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _descuentoGlobalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion(
                      'Descuento global (%) sobre toda la venta',
                    ),
                    onChanged: (v) {
                      final valor = double.tryParse(
                        v.replaceAll(',', '').trim(),
                      );
                      if (valor == null || valor < 0 || valor > 100) return;
                      ref
                          .read(carritoVentaProvider.notifier)
                          .establecerDescuentoGlobal(valor);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 200,
                child: CampoTecladoCompacto(
                  controller: _ocController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !carrito.esCotizacion,
                    controller: _ocController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('No. O/C exenta'),
                    onChanged: (v) =>
                        ref.read(carritoVentaProvider.notifier).establecerOc(v),
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 200,
                child: CampoTecladoCompacto(
                  controller: _regExoneradoController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !carrito.esCotizacion,
                    controller: _regExoneradoController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('No. Reg. exonerado'),
                    onChanged: (v) => ref
                        .read(carritoVentaProvider.notifier)
                        .establecerRegExonerado(v),
                  ),
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 200,
                child: CampoTecladoCompacto(
                  controller: _regSagController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !carrito.esCotizacion,
                    controller: _regSagController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('No. Reg. SAG'),
                    onChanged: (v) => ref
                        .read(carritoVentaProvider.notifier)
                        .establecerRegSag(v),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CampoTecladoCompacto(
                  controller: _observacionesController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _observacionesController,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion(
                      'Observaciones (se imprimen en la factura)',
                    ),
                    onChanged: (v) => ref
                        .read(carritoVentaProvider.notifier)
                        .establecerObservaciones(v),
                  ),
                ),
              ),
              SizedBox(width: double.infinity, child: _chipEnvio()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDatosVentaOriginal(
    CarritoVentaState carrito,
    bool esMovil,
    DateFormat formatoFecha,
  ) {
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
                          .read(carritoVentaProvider.notifier)
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
                key: _keyTipoDocumento,
                width: esMovil ? double.infinity : 190,
                child: DropdownButtonFormField<String>(
                  initialValue: carrito.tipoDocumento,
                  isExpanded: true,
                  decoration: _decoracion('Tipo de documento'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A1A),
                  ),
                  items: tiposDocumento.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(carritoVentaProvider.notifier)
                        .establecerTipoDocumento(v);
                  },
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 340,
                child: Row(
                  key: _keyCliente,
                  children: [
                    Expanded(
                      child: carrito.idCliente != null
                          ? _chipClienteVinculado()
                          : CompositedTransformTarget(
                              link: _clienteLayerLink,
                              child: TapRegion(
                                groupId: 'sugerencias-cliente',
                                onTapOutside: (_) =>
                                    _ocultarSugerenciasCliente(),
                                child: CampoTecladoCompacto(
                                  controller: _nombreClienteController,
                                  numerico: false,
                                  titulo: 'Vacío = Consumidor Final',
                                  child: TextField(
                                    inputFormatters: [mayusculasInputFormatter],
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    controller: _nombreClienteController,
                                    focusNode: _focusNombreCliente,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    decoration: _decoracion('Cliente').copyWith(
                                      hintText: 'Vacío = Consumidor Final',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      ref
                                          .read(carritoVentaProvider.notifier)
                                          .establecerNombreClienteManual(v);
                                      if (_clienteVinculado != null)
                                        setState(
                                          () => _clienteVinculado = null,
                                        );
                                      _actualizarSugerenciasCliente(v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _buscarCliente,
                      icon: const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EAF0),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (carrito.idCliente != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Completar datos del cliente',
                        onPressed: _completarDatosCliente,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE8EAF0),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 180,
                child: CampoTecladoCompacto(
                  controller: _documentoClienteController,
                  numerico: false,
                  child: TextField(
                    inputFormatters: [mayusculasInputFormatter],
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _documentoClienteController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: _decoracion('RTN / Documento'),
                    onChanged: (v) {
                      ref
                          .read(carritoVentaProvider.notifier)
                          .establecerDocumentoCliente(v);
                      if (_clienteVinculado != null)
                        setState(() => _clienteVinculado = null);
                    },
                  ),
                ),
              ),
              SizedBox(
                key: _keyCondicion,
                width: esMovil ? double.infinity : 150,
                child: DropdownButtonFormField<String>(
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
                  onChanged: carrito.esCotizacion
                      ? null
                      : (v) {
                          if (v == null) return;
                          ref
                              .read(carritoVentaProvider.notifier)
                              .establecerCondicion(v);
                        },
                ),
              ),
              if (!carrito.esCotizacion && carrito.condicion != 'Credito')
                SizedBox(
                  key: _keyMetodoPago,
                  width: esMovil ? double.infinity : 160,
                  child: DropdownButtonFormField<String>(
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
                          .read(carritoVentaProvider.notifier)
                          .establecerMetodoPago(v);
                    },
                  ),
                ),
              InkWell(
                key: _keyMasDatos,
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
          if (_saldoVencidoCliente != null) ...[
            const SizedBox(height: 10),
            _avisoCreditoVencido(_saldoVencidoCliente!),
          ],
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
                          'Descuento y campos fiscales de uso poco frecuente',
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
                            if (carrito.esCredito && !carrito.esCotizacion)
                              SizedBox(
                                key: _keyFechaVencimiento,
                                width: esMovil ? double.infinity : 160,
                                child: InkWell(
                                  onTap: () async {
                                    final fecha = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          carrito.fechaVencimiento ??
                                          DateTime.now().add(
                                            const Duration(days: 15),
                                          ),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (fecha != null)
                                      ref
                                          .read(carritoVentaProvider.notifier)
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
                              ),
                            if (carrito.esCredito && !carrito.esCotizacion)
                              SizedBox(
                                key: _keyTelefonoCredito,
                                width: esMovil ? double.infinity : 200,
                                child: CampoTecladoCompacto(
                                  controller: _telefonoCreditoController,
                                  numerico: false,
                                  child: TextField(
                                    controller: _telefonoCreditoController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    decoration: _decoracion(
                                      'Teléfono para avisos de crédito',
                                    ),
                                    onChanged: (v) => ref
                                        .read(carritoVentaProvider.notifier)
                                        .establecerTelefonoCredito(v),
                                  ),
                                ),
                              ),
                            SizedBox(
                              key: _keyDescuentoGlobal,
                              width: esMovil ? double.infinity : 260,
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
                                    'Descuento global (%) sobre toda la venta',
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
                                        .read(carritoVentaProvider.notifier)
                                        .establecerDescuentoGlobal(valor);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: esMovil ? double.infinity : 200,
                              child: CampoTecladoCompacto(
                                controller: _ocController,
                                numerico: false,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  enabled: !carrito.esCotizacion,
                                  controller: _ocController,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion('No. O/C exenta'),
                                  onChanged: (v) => ref
                                      .read(carritoVentaProvider.notifier)
                                      .establecerOc(v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: esMovil ? double.infinity : 200,
                              child: CampoTecladoCompacto(
                                controller: _regExoneradoController,
                                numerico: false,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  enabled: !carrito.esCotizacion,
                                  controller: _regExoneradoController,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion('No. Reg. exonerado'),
                                  onChanged: (v) => ref
                                      .read(carritoVentaProvider.notifier)
                                      .establecerRegExonerado(v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: esMovil ? double.infinity : 200,
                              child: CampoTecladoCompacto(
                                controller: _regSagController,
                                numerico: false,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  enabled: !carrito.esCotizacion,
                                  controller: _regSagController,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion('No. Reg. SAG'),
                                  onChanged: (v) => ref
                                      .read(carritoVentaProvider.notifier)
                                      .establecerRegSag(v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: CampoTecladoCompacto(
                                controller: _observacionesController,
                                numerico: false,
                                child: TextField(
                                  inputFormatters: [mayusculasInputFormatter],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  controller: _observacionesController,
                                  maxLines: 2,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _decoracion(
                                    'Observaciones (se imprimen en la factura)',
                                  ),
                                  onChanged: (v) => ref
                                      .read(carritoVentaProvider.notifier)
                                      .establecerObservaciones(v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: _chipEnvio(),
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

  void _sincronizarControladoresItems(CarritoVentaState carrito) {
    if (carrito.items.length == _conteoItemsControladores) return;
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlPrecio.values) {
      c.dispose();
    }
    for (final c in _ctrlDescuento.values) {
      c.dispose();
    }
    _ctrlCantidad.clear();
    _ctrlPrecio.clear();
    _ctrlDescuento.clear();
    for (final c in _ctrlDescripcion.values) {
      c.dispose();
    }
    _ctrlDescripcion.clear();
    for (final f in _focusInline.values) {
      f.dispose();
    }
    _focusInline.clear();
    _confirmarInline.clear();
    for (final f in _focusDescripcion.values) {
      f.dispose();
    }
    _focusDescripcion.clear();
    _confirmarDescripcion.clear();
    _conteoItemsControladores = carrito.items.length;
  }

  Widget _tarjetaCarritoGrande(
    CarritoVentaState carrito,
    bool esMovil, {
    double? altoMaximoTabla,
  }) {
    final productos = ref.watch(productosStreamProvider).value ?? [];
    final mapaProductos = {for (final p in productos) p.id: p};

    return Container(
      key: _keyTablaProductos,
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
                      'Productos en la venta',
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
                              _esPlataformaMovil
                                  ? 'Agregar'
                                  : 'Agregar Producto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Ver promociones vigentes',
                          onPressed: _abrirPromocionesVigentes,
                          icon: const Icon(
                            Icons.local_offer_outlined,
                            size: 20,
                          ),
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'Productos en la venta',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _selectorPrecioIsvCarrito(compacto: true),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Ver la tabla más grande',
                      onPressed: _expandirTablaProductos,
                      icon: const Icon(Icons.open_in_full, size: 18),
                      color: Colors.grey.shade600,
                    ),
                    IconButton(
                      tooltip: 'Ver promociones vigentes',
                      onPressed: _abrirPromocionesVigentes,
                      icon: const Icon(Icons.local_offer_outlined, size: 18),
                      color: Colors.grey.shade600,
                    ),
                    const Spacer(),
                    if (_esPlataformaMovil) ...[
                      OutlinedButton.icon(
                        onPressed: _escanearConCamara,
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: Text(
                          'Escanear',
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
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (!_esPlataformaMovil) ...[
                      OutlinedButton.icon(
                        onPressed: _abrirEscaneoRemoto,
                        icon: Icon(
                          _escaneoRemotoConectado
                              ? Icons.wifi_tethering
                              : Icons.qr_code_scanner,
                          size: 18,
                          color: _escaneoRemotoConectado
                              ? Colors.green.shade600
                              : null,
                        ),
                        label: Text(
                          _escaneoRemotoConectado
                              ? 'Escaneo activo'
                              : 'Escanear con celular',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _escaneoRemotoConectado
                                ? Colors.green.shade700
                                : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          side: BorderSide(
                            color: _escaneoRemotoConectado
                                ? Colors.green.shade400
                                : const Color(0xFFB6BCC7),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FilledButton.icon(
                      key: _keyAgregarProducto,
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
          if (esMovil) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Precio unitario:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                _selectorPrecioIsvCarrito(),
              ],
            ),
          ],
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Viendo la tabla ampliada…',
                  style: GoogleFonts.poppins(color: Colors.grey.shade400),
                ),
              ),
            )
          else if (_tablaConScrollPropio(esMovil))
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altoMaximoTabla ?? 600),
              child: ListView.separated(
                shrinkWrap: true,
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
            )
          else
            Column(
              children: [
                for (var i = 0; i < carrito.items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                  _filaCarritoTabla(
                    i,
                    carrito.items[i],
                    mapaProductos,
                    carrito.items.length,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _selectorPrecioIsvCarrito({
    bool compacto = false,
    VoidCallback? alCambiarExtra,
  }) {
    if (!_ventaEsFacturable) return const SizedBox.shrink();
    Widget opcion(String texto, bool valor) {
      final activo = _precioCarritoConIsv == valor;
      return InkWell(
        onTap: () {
          _alternarVistaPrecioCarrito(valor);
          alCambiarExtra?.call();
        },
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 8 : 12,
            vertical: compacto ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: activo ? Marca.primario : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: compacto ? 10.5 : 12,
              fontWeight: FontWeight.w600,
              color: activo ? Colors.white : const Color(0xFF666A72),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFB6BCC7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [opcion('Con ISV', true), opcion('Sin ISV', false)],
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
                final carrito = ref.read(carritoVentaProvider);
                final productos = ref.read(productosStreamProvider).value ?? [];
                final mapaProductos = {for (final p in productos) p.id: p};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Productos en la venta',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 14),
                        _selectorPrecioIsvCarrito(
                          compacto: true,
                          alCambiarExtra: () => setDialogState(() {}),
                        ),
                        const SizedBox(width: 10),
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

  Widget _barraTotalesCompacta(
    CarritoVentaState carrito, {
    bool destacarTotal = false,
  }) {
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

    final descuentosYRebajas = carrito.descuentosYRebajas;

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
          if (destacarTotal && descuentosYRebajas > 0) ...[
            total('Descuentos y rebajas', descuentosYRebajas),
            const SizedBox(width: 20),
          ],
          total('ISV', carrito.impuesto),
          const SizedBox(width: 20),
          if (!destacarTotal)
            total('Total a pagar', carrito.totalAPagar, destacado: true),
          const Spacer(),
          if (destacarTotal) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL A PAGAR',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    formatearMoneda(carrito.totalAPagar),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: _guardando ? null : _confirmarVenta,
              style: FilledButton.styleFrom(
                backgroundColor: destacarTotal
                    ? Marca.primario
                    : const Color(0xFF1A1A1A),
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
                      _textoBoton,
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
            _etiquetaColumnaPrecio,
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
            _etiquetaColumnaImporte,
            textAlign: TextAlign.right,
            style: estilo,
          ),
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
    final esMovilNativo =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

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
    String? sufijo,
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
          sufijo: sufijo,
          dosDecimales: dosDecimales,
        ),
      ],
    );
  }

  Widget _campoDescripcion(int index, dynamic item) {
    final ctrl = _ctrlDescripcion.putIfAbsent(
      index,
      () => TextEditingController(text: item.nombreProducto as String),
    );

    Future<void> confirmar() async {
      final nuevoTexto = ctrl.text.trim();
      final nombreActual = item.nombreProducto as String;
      if (nuevoTexto.isEmpty) {
        ctrl.text = nombreActual;
        return;
      }
      if (nuevoTexto == nombreActual) return;
      final negocio = await ref
          .read(negocioRepositoryProvider)
          .obtenerNegocioActual();
      if (negocio.tienePermiso(PermisosEspeciales.ventasEditarDescripcion)) {
        if (!mounted) return;
        final permitido = (await verificarAccesoEspecial(
          context,
          ref,
          PermisosEspeciales.ventasEditarDescripcion,
        )).autorizado;
        if (!permitido) {
          ctrl.text = nombreActual;
          return;
        }
      }
      ref
          .read(carritoVentaProvider.notifier)
          .actualizarDescripcion(index, nuevoTexto);
    }

    _confirmarDescripcion[index] = confirmar;

    final focusNode = _focusDescripcion.putIfAbsent(index, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) _confirmarDescripcion[index]?.call();
      });
      return node;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CampoTecladoCompacto(
          controller: ctrl,
          numerico: false,
          child: TextField(
            inputFormatters: [mayusculasInputFormatter],
            autocorrect: false,
            enableSuggestions: false,
            controller: ctrl,
            focusNode: focusNode,
            maxLines: null,
            minLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
        if (item.reembasado as bool)
          Text(
            'Reembasado',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.grey.shade400,
            ),
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
    final precioSinIsv = item.precioVenta as double;
    final precioPorCuartoMostrado = _mostrarPrecioConIsv
        ? redondearMoneda(precioSinIsv * 1.15)
        : precioSinIsv;
    final precioMostrado = precioPorCuartoMostrado;
    final importe = _importeMostrado(item);

    final ctrlCantidad = _ctrlCantidad.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.cantidad as double),
      ),
    );
    final ctrlPrecio = _ctrlPrecio.putIfAbsent(
      index,
      () => TextEditingController(text: precioMostrado.toStringAsFixed(2)),
    );
    final ctrlDescuento = _ctrlDescuento.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.descuentoPorcentaje as double),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
          Expanded(flex: 4, child: _campoDescripcion(index, item)),
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
                precioMostrado,
                (v) {
                  if (_mostrarPrecioConIsv) {
                    _actualizarPrecio(index, v);
                  } else {
                    _actualizarPrecioSinIsv(index, v);
                  }
                },
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
              formatearMoneda(importe),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _botonPendienteCompra(index, item as ItemVentaModel),
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
    );
  }

  Widget _filaCarritoMovil(
    int index,
    dynamic item,
    Map<String, ProductoModel> mapaProductos,
    int totalItems,
  ) {
    final producto = mapaProductos[item.idProducto as String];
    final precioSinIsv = item.precioVenta as double;
    final precioPorCuartoMostrado = _mostrarPrecioConIsv
        ? redondearMoneda(precioSinIsv * 1.15)
        : precioSinIsv;
    final precioMostrado = precioPorCuartoMostrado;
    final importe = _importeMostrado(item);

    final ctrlCantidad = _ctrlCantidad.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.cantidad as double),
      ),
    );
    final ctrlPrecio = _ctrlPrecio.putIfAbsent(
      index,
      () => TextEditingController(text: precioMostrado.toStringAsFixed(2)),
    );
    final ctrlDescuento = _ctrlDescuento.putIfAbsent(
      index,
      () => TextEditingController(
        text: _formatoCantidad(item.descuentoPorcentaje as double),
      ),
    );

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
                    _campoDescripcion(index, item),
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
              _botonPendienteCompra(index, item as ItemVentaModel),
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
                  _etiquetaColumnaPrecio,
                  ctrlPrecio,
                  precioMostrado,
                  (v) {
                    if (_mostrarPrecioConIsv) {
                      _actualizarPrecio(index, v);
                    } else {
                      _actualizarPrecioSinIsv(index, v);
                    }
                  },
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_etiquetaColumnaImporte: ${formatearMoneda(importe)}',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  Widget _tarjetaTotales(CarritoVentaState carrito, bool esMovil) {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _filaTotalTexto('Subtotal', carrito.subtotal),
              _filaTotalTexto('ISV (15%)', carrito.impuesto),
              if (carrito.descuentoGlobalPorcentaje > 0)
                _filaTotalTextoPorcentaje(
                  'Descuento global',
                  carrito.descuentoGlobalPorcentaje,
                ),
              if (!carrito.esCotizacion &&
                  carrito.condicion != 'Credito' &&
                  carrito.metodoPago == 'Efectivo' &&
                  carrito.pagoCon > 0) ...[
                _filaTotalTexto('Paga con', carrito.pagoCon),
                _filaTotalTexto('Cambio', carrito.cambio),
              ],
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
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: _keyBotonRegistrarVenta,
                  onPressed: _guardando ? null : _confirmarVenta,
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
                          _textoBoton,
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

  Widget _filaTotalTextoPorcentaje(String etiqueta, double porcentaje) {
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
          '${_formatoCantidad(porcentaje)}%',
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
