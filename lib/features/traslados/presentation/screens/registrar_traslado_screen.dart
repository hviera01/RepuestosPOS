import '../../../../core/theme/marca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../data/item_traslado_model.dart';
import '../../data/traslado_export_service.dart';
import '../../data/traslado_model.dart';
import '../../data/traslado_ticket_escpos_service.dart';
import '../widgets/traslado_ticket_escpos_preview.dart';
import '../../providers/traslados_provider.dart';
import '../../../sucursales/data/sucursal_model.dart';
import '../../../sucursales/providers/sucursales_provider.dart';
import '../../../productos/data/producto_model.dart';
import '../../../productos/providers/productos_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../negocio/providers/negocio_provider.dart';
import '../../../compras/presentation/widgets/buscar_producto_compra_dialog.dart';
import '../../../ventas/presentation/widgets/teclado_numerico_dialog.dart';
import '../../../ventas/providers/ventas_provider.dart' show presenciaImpresionRepositoryProvider;
import '../../../../core/widgets/pdf_preview_dialog.dart';
import '../../../../core/widgets/exito_transaccion_overlay.dart';

class RegistrarTrasladoScreen extends ConsumerStatefulWidget {
  const RegistrarTrasladoScreen({super.key});

  @override
  ConsumerState<RegistrarTrasladoScreen> createState() => _RegistrarTrasladoScreenState();
}

class _RegistrarTrasladoScreenState extends ConsumerState<RegistrarTrasladoScreen> {
  final _observacionesController = TextEditingController();
  final _servicioExport = TrasladoExportService();
  final _servicioTicketEscPos = TrasladoTicketEscPosService();
  SucursalModel? _origen;
  SucursalModel? _destino;
  List<ItemTrasladoModel> _items = [];
  final Map<int, TextEditingController> _ctrlCantidad = {};
  final Map<int, TextEditingController> _ctrlUbicacion = {};
  bool _guardando = false;
  String? _error;
  String _estadoDeseado = 'Entregado';
  bool _defaultsSucursalAplicados = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    for (final c in _ctrlUbicacion.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _mostrarError(String mensaje) => setState(() => _error = mensaje);

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), showCloseIcon: true));
  }

  Future<void> _agregarProducto() async {
    final producto = await Navigator.of(context).push<ProductoModel>(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => const BuscarProductoCompraDialog()),
    );
    if (producto == null || !mounted) return;
    if (_items.any((i) => i.idProducto == producto.id)) {
      _mostrarError('Ese producto ya está en el traslado');
      return;
    }
    if (producto.stock <= 0) {
      _mostrarError('No se puede trasladar "${producto.nombre}": no tiene existencia disponible');
      return;
    }
    setState(() {
      _items = [..._items, ItemTrasladoModel(idProducto: producto.id, nombreProducto: producto.nombre, cantidad: 1, ubicacion: producto.descripcion)];
      _error = null;
    });
  }

  void _quitarItem(int index) {
    _ctrlCantidad.remove(index)?.dispose();
    _ctrlUbicacion.remove(index)?.dispose();
    setState(() => _items = [..._items]..removeAt(index));
  }

  void _actualizarCantidad(int index, String texto) {
    final cantidad = double.tryParse(texto.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) return;
    final nuevos = [..._items];
    nuevos[index] = ItemTrasladoModel(idProducto: nuevos[index].idProducto, nombreProducto: nuevos[index].nombreProducto, cantidad: cantidad, ubicacion: nuevos[index].ubicacion);
    setState(() => _items = nuevos);
  }

  void _actualizarUbicacion(int index, String texto) {
    final nuevos = [..._items];
    nuevos[index] = ItemTrasladoModel(idProducto: nuevos[index].idProducto, nombreProducto: nuevos[index].nombreProducto, cantidad: nuevos[index].cantidad, ubicacion: texto.trim());
    setState(() => _items = nuevos);
  }

  Future<void> _guardar() async {
    if (_origen == null || _destino == null) {
      _mostrarError('Elegí la sucursal origen y destino');
      return;
    }
    if (_origen!.id == _destino!.id) {
      _mostrarError('La sucursal origen y destino no pueden ser la misma');
      return;
    }
    if (_items.isEmpty) {
      _mostrarError('Agregá al menos un producto');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(trasladoRepositoryProvider);
      final usuario = ref.read(authProvider).usuario?.nombreCompleto ?? '';
      final traslado = await repo.registrar(
        idSucursalOrigen: _origen!.id,
        nombreSucursalOrigen: _origen!.nombre,
        idSucursalDestino: _destino!.id,
        nombreSucursalDestino: _destino!.nombre,
        observaciones: _observacionesController.text.trim(),
        usuarioCrea: usuario,
        detalle: _items,
        estadoInicial: _estadoDeseado,
        usuarioRecibe: usuario,
      );
      if (!mounted) return;
      mostrarExitoTransaccion(context, mensaje: 'Traslado registrado correctamente');

      final esMovil = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
      final esCelularOWebMovil = (!kIsWeb && Platform.isAndroid) || (kIsWeb && esMovil);
      if (esCelularOWebMovil) {
        await _pedirImpresionEnVivo(traslado.id);
      } else {
        final numero = traslado.numero;
        final deseaImprimir = await _confirmarDialogo(
          'Traslado $numero creado',
          'Traslado $numero creado en estado ${traslado.estado.toUpperCase()}.\n\n¿Desea imprimir el ticket (ORIGINAL y COPIA)?',
        );
        if (deseaImprimir && mounted) await _imprimir(traslado);
      }
      if (!mounted) return;
      _limpiar();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _guardando = false;
      });
    }
  }

  Future<void> _pedirImpresionEnVivo(String trasladoId) async {
    final pcConectada = await ref.read(presenciaImpresionRepositoryProvider).estaConectada();
    if (!mounted) return;
    if (pcConectada) {
      await ref.read(trasladoRepositoryProvider).marcarSolicitudImpresionEnVivo(trasladoId, true);
      _mostrarMensaje('Se envió la orden de impresión a la caja principal');
    } else {
      _mostrarMensaje('No se puede imprimir directo desde acá: no se detectó la caja principal conectada');
    }
  }

  Future<bool> _confirmarDialogo(String titulo, String mensaje) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(mensaje, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No', style: GoogleFonts.poppins())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Marca.primario),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, imprimir', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return confirmar ?? false;
  }

  void _limpiar() {
    setState(() {
      _origen = null;
      _destino = null;
      _items = [];
      _guardando = false;
      _error = null;
      _estadoDeseado = 'Entregado';
      _defaultsSucursalAplicados = false;
    });
    _observacionesController.clear();
    for (final c in _ctrlCantidad.values) {
      c.dispose();
    }
    _ctrlCantidad.clear();
    for (final c in _ctrlUbicacion.values) {
      c.dispose();
    }
    _ctrlUbicacion.clear();
  }

  List<ProductoModel>? _cacheProductosCodigos;
  Map<String, String> _cacheCodigos = const {};

  Map<String, String> _codigosPorProducto() {
    final productos = ref.read(productosStreamProvider).value ?? [];
    if (identical(productos, _cacheProductosCodigos)) return _cacheCodigos;
    _cacheProductosCodigos = productos;
    _cacheCodigos = {for (final p in productos) p.id: p.codigo};
    return _cacheCodigos;
  }

  Future<void> _imprimir(TrasladoModel traslado) async {
    if (ref.read(productosStreamProvider).value == null) {
      try {
        await ref.read(productosStreamProvider.future);
      } catch (_) {}
      if (!mounted) return;
    }
    final negocio = await ref.read(negocioRepositoryProvider).obtenerNegocioActual();
    if (!mounted) return;
    final codigos = _codigosPorProducto();
    final impresora = negocio.impresoraTermicaUrl.isEmpty ? null : Printer(url: negocio.impresoraTermicaUrl, name: negocio.impresoraTermicaNombre);
    await showDialog(
      context: context,
      builder: (context) => PdfPreviewDialog(
        titulo: 'Traslado ${traslado.numero}',
        nombreArchivo: 'traslado_${traslado.numero}.pdf',
        generarPdf: () => _servicioExport.generarPdfTraslado(traslado, negocio, codigosPorProducto: codigos),
        generarPdfConFormato: (formato) => _servicioExport.generarPdfTraslado(traslado, negocio, codigosPorProducto: codigos, formatoImpresora: formato),
        impresora: impresora,
        generarTicketEscPos: () => _servicioTicketEscPos.generarTicket(traslado, negocio, codigosPorProducto: codigos),
        nombreImpresoraWindows: negocio.impresoraTermicaNombre,
        vistaPreviaTicket: () => TrasladoTicketEscPosPreview(traslado: traslado, negocio: negocio, codigosPorProducto: codigos, esCopia: false),
      ),
    );
  }

  Future<void> _verMasGrande() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF2F3F7),
          appBar: AppBar(
            backgroundColor: Marca.primario,
            title: Text('Productos del traslado', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: StatefulBuilder(
            builder: (context, setStateDialogo) => Padding(
              padding: const EdgeInsets.all(20),
              child: _tarjetaProductos(grande: true, alturaAcotada: true, alReconstruir: () => setStateDialogo(() {})),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFE8EAF0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _selectorSucursal({required String label, required SucursalModel? valor, required List<SucursalModel> opciones, required void Function(SucursalModel?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 56,
      decoration: BoxDecoration(color: const Color(0xFFE8EAF0), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SucursalModel>(
          isExpanded: true,
          value: valor,
          hint: Text(label, style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade600)),
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
          items: opciones.map((s) => DropdownMenuItem(value: s, child: Text(s.nombre, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(productosStreamProvider);
    return Container(
      color: const Color(0xFFF2F3F7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esMovil = constraints.maxWidth < 900;
          final altoTabla = (constraints.maxHeight * 0.5).clamp(320.0, 900.0);
          return SingleChildScrollView(
            padding: EdgeInsets.all(esMovil ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar Traslado', style: GoogleFonts.poppins(fontSize: esMovil ? 19 : 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 14),
                _tarjetaDatos(esMovil),
                const SizedBox(height: 14),
                esMovil
                    ? _tarjetaProductos(grande: false, alturaAcotada: false, alReconstruir: () => setState(() {}))
                    : SizedBox(height: altoTabla, child: _tarjetaProductos(grande: false, alturaAcotada: true, alReconstruir: () => setState(() {}))),
                const SizedBox(height: 14),
                _tarjetaFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaDatos(bool esMovil) {
    final sucursalesAsync = ref.watch(sucursalesActivasProvider);
    return _tarjeta(
      child: sucursalesAsync.when(
        data: (sucursales) {
          if (sucursales.length < 2) {
            return Text('Necesitás al menos 2 sucursales activas registradas para hacer un traslado.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600));
          }
          if (!_defaultsSucursalAplicados) {
            _defaultsSucursalAplicados = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _origen == null && _destino == null) {
                setState(() {
                  _origen = sucursales[0];
                  _destino = sucursales[1];
                });
              }
            });
          }
          return Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: esMovil ? double.infinity : 260,
                child: _selectorSucursal(label: 'Sucursal origen', valor: _origen, opciones: sucursales, onChanged: (v) => setState(() => _origen = v)),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey.shade400),
              SizedBox(
                width: esMovil ? double.infinity : 260,
                child: _selectorSucursal(label: 'Sucursal destino', valor: _destino, opciones: sucursales, onChanged: (v) => setState(() => _destino = v)),
              ),
              SizedBox(
                width: esMovil ? double.infinity : 320,
                child: TextField(controller: _observacionesController, style: GoogleFonts.poppins(fontSize: 13), decoration: _decoracion('Observaciones (opcional)')),
              ),
              SizedBox(width: esMovil ? double.infinity : 420, child: _selectorEstadoInicial()),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Marca.primario)),
        error: (e, st) => Text('Error: $e', style: GoogleFonts.poppins(color: Colors.red)),
      ),
    );
  }

  Widget _selectorEstadoInicial() {
    Widget opcion(String valor, String etiqueta) {
      final activo = _estadoDeseado == valor;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _estadoDeseado = valor),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(color: activo ? Marca.primario : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Text(etiqueta, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: activo ? Colors.white : const Color(0xFF666A72))),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Queda registrado como', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Container(
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: const Color(0xFFE8EAF0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB6BCC7))),
          child: Row(
            children: [
              opcion('Pendiente', 'Pendiente'),
              opcion('Enviado', 'Enviado'),
              opcion('Entregado', 'Entregado'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaProductos({required bool grande, required bool alturaAcotada, required VoidCallback alReconstruir}) {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: alturaAcotada ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Productos', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 10),
              Text('(${_items.length})', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
              const Spacer(),
              if (!grande)
                OutlinedButton.icon(
                  onPressed: _verMasGrande,
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: Text('Ver más grande', style: GoogleFonts.poppins(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB6BCC7))),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await _agregarProducto();
                  alReconstruir();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Agregar', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(backgroundColor: Marca.primario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Sin productos todavía', style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade500))),
            )
          else
            _construirListaItems(grande: grande, alturaAcotada: alturaAcotada, alReconstruir: alReconstruir),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
              child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filaItem(int index, {required bool grande, required Map<String, String> codigos, required VoidCallback alReconstruir}) {
    final item = _items[index];
    final ctrl = _ctrlCantidad.putIfAbsent(index, () => TextEditingController(text: item.cantidad.toStringAsFixed(item.cantidad == item.cantidad.roundToDouble() ? 0 : 2)));
    final ctrlUbicacion = _ctrlUbicacion.putIfAbsent(index, () => TextEditingController(text: item.ubicacion));
    final codigo = codigos[item.idProducto] ?? '';
    return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (codigo.isNotEmpty) Text(codigo, style: GoogleFonts.poppins(fontSize: grande ? 12 : 11, color: Colors.grey.shade500)),
                            Text(item.nombreProducto, style: GoogleFonts.poppins(fontSize: grande ? 16 : 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: grande ? 110 : 80,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: grande ? 15 : 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: grande ? 12 : 8),
                            filled: true,
                            fillColor: const Color(0xFFE8EAF0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onTap: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
                              ? null
                              : () async {
                                  final texto = await showDialog<String>(
                                    context: context,
                                    builder: (context) => TecladoNumericoDialog(titulo: 'Cantidad', valorInicial: ctrl.text),
                                  );
                                  if (texto == null || !context.mounted) return;
                                  ctrl.text = texto;
                                  _actualizarCantidad(index, texto);
                                  alReconstruir();
                                },
                          onChanged: (v) {
                            _actualizarCantidad(index, v);
                            alReconstruir();
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Marca.primario),
                        onPressed: () {
                          _quitarItem(index);
                          alReconstruir();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: grande ? 260 : 200,
                    child: TextField(
                      controller: ctrlUbicacion,
                      style: GoogleFonts.poppins(fontSize: grande ? 13 : 12),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ubicación (opcional)',
                        hintStyle: GoogleFonts.poppins(fontSize: grande ? 12.5 : 11.5, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        filled: true,
                        fillColor: const Color(0xFFF2F3F7),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => _actualizarUbicacion(index, v),
                    ),
                  ),
                ],
              ),
            );
  }

  Widget _construirListaItems({required bool grande, required bool alturaAcotada, required VoidCallback alReconstruir}) {
    final codigos = _codigosPorProducto();

    if (alturaAcotada) {
      return Expanded(
        child: ListView.separated(
          itemCount: _items.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) => _filaItem(index, grande: grande, codigos: codigos, alReconstruir: alReconstruir),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _items.length; index++) ...[
          if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
          _filaItem(index, grande: grande, codigos: codigos, alReconstruir: alReconstruir),
        ],
      ],
    );
  }

  Widget _tarjetaFooter() {
    final totalUnidades = _items.fold<double>(0, (s, i) => s + i.cantidad);
    return _tarjeta(
      child: Row(
        children: [
          Text('Total: ${totalUnidades.toStringAsFixed(totalUnidades == totalUnidades.roundToDouble() ? 0 : 2)} unidades', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          const Spacer(),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync_alt, size: 18),
            label: Text(_guardando ? 'Guardando...' : 'Registrar Traslado', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
            style: FilledButton.styleFrom(backgroundColor: Marca.primario, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }
}
