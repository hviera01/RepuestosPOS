import '../theme/marca.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../providers/actualizacion_provider.dart';
import 'logo_danli.dart';
import '../providers/tabs_provider.dart';
import '../models/tab_item.dart';
import '../services/actualizacion_service.dart';
import '../version_app.dart';
import '../widgets/actualizacion_dialog.dart';
import '../widgets/banner_sin_conexion.dart';
import '../widgets/side_menu.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dispositivos/providers/dispositivos_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/negocio/providers/negocio_provider.dart';
import '../utils/device_id.dart';
import '../../features/productos/providers/productos_provider.dart';
import '../../features/traslados/data/impresion_en_vivo_traslado_service.dart';
import '../../features/traslados/data/traslado_model.dart';
import '../../features/traslados/providers/traslados_provider.dart';
import '../../features/ventas/data/impresion_en_vivo_service.dart';
import '../../features/ventas/data/venta_model.dart';
import '../../features/ventas/providers/ventas_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _menuAbierto = false;
  bool _dialogoActualizacionAbierto = false;

  bool _esPcPrincipal =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  Timer? _latidoTimer;
  Timer? _actualizacionTimer;
  final _servicioImpresionEnVivo = ImpresionEnVivoService();
  final _idsSolicitudEnProceso = <String>{};
  final _servicioImpresionEnVivoTraslado = ImpresionEnVivoTrasladoService();
  final _idsSolicitudTrasladoEnProceso = <String>{};

  bool _manejarEscape(KeyEvent evento) {
    if (evento is! KeyDownEvent || evento.logicalKey != LogicalKeyboardKey.escape) return false;
    final contexto = FocusManager.instance.primaryFocus?.context;
    if (contexto == null) return false;
    final navegador = Navigator.maybeOf(contexto);
    if (navegador == null || !navegador.canPop()) return false;
    navegador.maybePop();
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_manejarEscape);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabsState = ref.read(tabsProvider);
      if (tabsState.tabs.isEmpty) {
        ref
            .read(tabsProvider.notifier)
            .abrirTab(
              TabItem(
                id: 'inicio',
                titulo: 'Inicio',
                icono: Icons.home_outlined,
                contenido: const HomeScreen(),
                cerrable: false,
              ),
            );
      }
    });

    if (_esPcPrincipal) {
      _confirmarPcPrincipal();
      _calentarImpresion();
    }

    final usuario = ref.read(authProvider).usuario;
    ref
        .read(dispositivoRepositoryProvider)
        .reportar(
          versionApp: versionApp,
          usuario: usuario?.nombreCompleto ?? '',
        );

    if (ActualizacionService.aplica) {
      _chequearActualizacion();
      _actualizacionTimer = Timer.periodic(
        const Duration(minutes: 10),
        (_) => _chequearActualizacion(),
      );
    }
  }

  Future<void> _confirmarPcPrincipal() async {
    final negocio = await ref
        .read(negocioRepositoryProvider)
        .obtenerNegocioActual();
    final esEste = await esteEquipoEsPcPrincipal(negocio.pcPrincipalHostname);
    if (!mounted) return;
    if (!esEste) {
      setState(() => _esPcPrincipal = false);
      return;
    }
    final presencia = ref.read(presenciaImpresionRepositoryProvider);
    presencia.enviarLatido();
    _latidoTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => presencia.enviarLatido(),
    );
  }

  Future<void> _calentarImpresion() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await Printing.listPrinters();
    } catch (_) {}
  }

  Future<void> _chequearActualizacion() async {
    if (_dialogoActualizacionAbierto) return;
    final actualizacion = await ActualizacionService.buscarActualizacion();
    if (actualizacion == null || !mounted) return;
    ref
        .read(actualizacionDisponibleProvider.notifier)
        .establecer(actualizacion);
    _dialogoActualizacionAbierto = true;
    await mostrarDialogoActualizacion(context, actualizacion);
    _dialogoActualizacionAbierto = false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_manejarEscape);
    _latidoTimer?.cancel();
    _actualizacionTimer?.cancel();
    super.dispose();
  }

  Future<void> _procesarSolicitudImpresionEnVivo(VentaModel venta) async {
    if (_idsSolicitudEnProceso.contains(venta.id)) return;
    _idsSolicitudEnProceso.add(venta.id);
    try {
      final ventaRepo = ref.read(ventaRepositoryProvider);
      unawaited(ventaRepo.marcarSolicitudImpresionEnVivo(venta.id, false));
      final futureDetalle = ventaRepo.obtenerDetalleVenta(venta.id);
      final futureNegocio = ref
          .read(negocioRepositoryProvider)
          .obtenerNegocioActual();
      final detalle = await futureDetalle;
      final negocio = await futureNegocio;
      final ventaCompleta = venta.copyWith(detalle: detalle);
      final ok = await _servicioImpresionEnVivo.imprimirSilencioso(
        ventaCompleta,
        negocio,
        forzarCopia: ventaCompleta.solicitudImpresionEsCopia,
      );
      if (ok) {
        await ventaRepo.marcarPendienteImpresion(venta.id, false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Venta ${ventaCompleta.numeroDocumento} recibida desde el celular: no se pudo imprimir automáticamente, quedó en Pendientes de Impresión.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      _idsSolicitudEnProceso.remove(venta.id);
    }
  }

  Future<void> _procesarSolicitudImpresionGuiaEnvio(VentaModel venta) async {
    final idProceso = 'guia_${venta.id}';
    if (_idsSolicitudEnProceso.contains(idProceso)) return;
    _idsSolicitudEnProceso.add(idProceso);
    try {
      final ventaRepo = ref.read(ventaRepositoryProvider);
      unawaited(ventaRepo.marcarSolicitudImpresionGuiaEnvio(venta.id, false));
      final negocio = await ref
          .read(negocioRepositoryProvider)
          .obtenerNegocioActual();
      final ok = await _servicioImpresionEnVivo.imprimirGuiaSilencioso(
        venta,
        negocio,
        grande: venta.solicitudImpresionGuiaGrande,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Guía de envío de la venta ${venta.numeroDocumento} (pedida desde otro dispositivo): no se pudo imprimir automáticamente.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      _idsSolicitudEnProceso.remove(idProceso);
    }
  }

  Future<void> _procesarSolicitudImpresionEnVivoTraslado(TrasladoModel traslado) async {
    if (_idsSolicitudTrasladoEnProceso.contains(traslado.id)) return;
    _idsSolicitudTrasladoEnProceso.add(traslado.id);
    try {
      final trasladoRepo = ref.read(trasladoRepositoryProvider);
      unawaited(trasladoRepo.marcarSolicitudImpresionEnVivo(traslado.id, false));
      final futureCompleto = trasladoRepo.obtenerPorId(traslado.id);
      final futureNegocio = ref.read(negocioRepositoryProvider).obtenerNegocioActual();
      if (ref.read(productosStreamProvider).value == null) {
        try {
          await ref.read(productosStreamProvider.future);
        } catch (_) {}
      }
      final productos = ref.read(productosStreamProvider).value ?? [];
      final codigos = {for (final p in productos) p.id: p.codigo};
      final trasladoCompleto = await futureCompleto;
      final negocio = await futureNegocio;
      if (trasladoCompleto == null) return;
      final ok = await _servicioImpresionEnVivoTraslado.imprimirSilencioso(
        trasladoCompleto,
        negocio,
        codigos,
        forzarCopia: traslado.solicitudImpresionEsCopia,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Traslado ${trasladoCompleto.numero} recibido desde el celular: no se pudo imprimir automáticamente.'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      _idsSolicitudTrasladoEnProceso.remove(traslado.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabsState = ref.watch(tabsProvider);
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    if (_esPcPrincipal) {
      ref.listen<AsyncValue<List<VentaModel>>>(
        ventasConSolicitudImpresionEnVivoStreamProvider,
        (previous, next) {
          for (final venta in next.value ?? const <VentaModel>[]) {
            unawaited(_procesarSolicitudImpresionEnVivo(venta));
          }
        },
      );
      ref.listen<AsyncValue<List<TrasladoModel>>>(
        trasladosConSolicitudImpresionEnVivoStreamProvider,
        (previous, next) {
          for (final traslado in next.value ?? const <TrasladoModel>[]) {
            unawaited(_procesarSolicitudImpresionEnVivoTraslado(traslado));
          }
        },
      );
      ref.listen<AsyncValue<List<VentaModel>>>(
        ventasConSolicitudImpresionGuiaEnvioStreamProvider,
        (previous, next) {
          for (final venta in next.value ?? const <VentaModel>[]) {
            unawaited(_procesarSolicitudImpresionGuiaEnvio(venta));
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: Stack(
        children: [
          Column(
            children: [
              const BannerSinConexion(),
              _barraSuperior(usuario),
              _barraPestanas(tabsState),
              Expanded(
                child: tabsState.tabs.isEmpty
                    ? const SizedBox()
                    : IndexedStack(
                        index: tabsState.indiceActivo,
                        children: tabsState.tabs
                            .map((t) => t.contenido)
                            .toList(),
                      ),
              ),
            ],
          ),
          if (_menuAbierto)
            GestureDetector(
              onTap: () => setState(() => _menuAbierto = false),
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            left: _menuAbierto ? 0 : -300,
            top: 0,
            bottom: 0,
            child: SideMenu(
              onCerrar: () => setState(() => _menuAbierto = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraSuperior(dynamic usuario) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Marca.primario),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esAngosto = constraints.maxWidth < 420;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () =>
                            setState(() => _menuAbierto = !_menuAbierto),
                      ),
                      const SizedBox(width: 4),
                      const LogoDanli(tamano: 42, radio: 9),
                      if (!esAngosto && (ref.watch(negocioStreamProvider).value?.nombre ?? '').isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          ref.watch(negocioStreamProvider).value!.nombre,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (usuario != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          usuario.nombreCompleto.isNotEmpty
                              ? usuario.nombreCompleto[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!esAngosto) ...[
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                usuario.nombreCompleto,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                usuario.rol,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Cerrar sesión',
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _barraPestanas(TabsState tabsState) {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: tabsState.tabs.length,
        itemBuilder: (context, index) {
          final tab = tabsState.tabs[index];
          final activo = index == tabsState.indiceActivo;
          return GestureDetector(
            onTap: () => ref.read(tabsProvider.notifier).seleccionarTab(index),
            child: Container(
              margin: const EdgeInsets.only(right: 6, top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: activo ? const Color(0xFFE8EAF0) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: activo
                    ? Border.all(
                        color: Marca.primario.withOpacity(0.25),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icono,
                    size: 16,
                    color: activo
                        ? Marca.primario
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tab.titulo,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: activo
                          ? Marca.primario
                          : Colors.grey.shade600,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (tab.cerrable) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ref.read(tabsProvider.notifier).cerrarTab(tab.id),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
