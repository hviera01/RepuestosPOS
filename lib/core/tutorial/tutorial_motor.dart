import '../theme/marca.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tutorial_modelos.dart';

final _azulMarca = Marca.primario;

void iniciarRecorridoTutorial(
  BuildContext context,
  List<TutorialPaso> pasos, {
  required VoidCallback onFinish,
}) {
  late OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => _TutorialOverlay(
      pasos: pasos,
      onFinish: () {
        entrada.remove();
        onFinish();
      },
      onSalir: () => entrada.remove(),
    ),
  );
  Overlay.of(context).insert(entrada);
}

class _TutorialOverlay extends StatefulWidget {
  final List<TutorialPaso> pasos;
  final VoidCallback onFinish;
  final VoidCallback onSalir;
  const _TutorialOverlay({
    required this.pasos,
    required this.onFinish,
    required this.onSalir,
  });

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  int _indice = 0;
  Rect? _rect;
  Size? _tamano;
  Timer? _sondeo;
  bool _avanzandoPorToque = false;
  bool _terminado = false;
  bool _rutaTapada = false;
  bool _esperandoQueVuelva = false;

  TutorialPaso get _paso => widget.pasos[_indice];

  @override
  void initState() {
    super.initState();
    _sondeo = Timer.periodic(const Duration(milliseconds: 100), (_) => _actualizarRect());
    WidgetsBinding.instance.addPostFrameCallback((_) => _irA(0, direccion: 1, primeraVez: true));
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    super.dispose();
  }

  void _actualizarRect() {
    if (_terminado || _indice >= widget.pasos.length) return;
    final ctx = _paso.key.currentContext;
    if (ctx == null) return;
    final ruta = ModalRoute.of(ctx);
    final tapadaAhora = ruta != null && !ruta.isCurrent;
    if (tapadaAhora != _rutaTapada) {
      if (_rutaTapada && !tapadaAhora && _esperandoQueVuelva) {
        _esperandoQueVuelva = false;
        setState(() => _rutaTapada = false);
        _siguiente();
        return;
      }
      setState(() => _rutaTapada = tapadaAhora);
    }
    if (tapadaAhora) return;
    final caja = ctx.findRenderObject();
    if (caja is! RenderBox || !caja.attached) return;
    final ancestro = context.findRenderObject();
    if (ancestro is! RenderBox) return;
    final nuevo = caja.localToGlobal(Offset.zero, ancestor: ancestro) & caja.size;
    if (nuevo != _rect || ancestro.size != _tamano) {
      setState(() {
        _rect = nuevo;
        _tamano = ancestro.size;
      });
    }
  }

  Future<void> _asegurarVisible(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  Future<void> _irA(int desde, {required int direccion, bool primeraVez = false}) async {
    var i = desde;
    while (i >= 0 && i < widget.pasos.length) {
      final ctx = widget.pasos[i].key.currentContext;
      if (ctx != null) {
        setState(() {
          _indice = i;
          _rect = null;
          _rutaTapada = false;
          _esperandoQueVuelva = false;
        });
        await _asegurarVisible(widget.pasos[i].key);
        if (!mounted) return;
        _actualizarRect();
        return;
      }
      i += direccion;
    }
    if (primeraVez) {
      _salir();
      return;
    }
    if (direccion > 0) _terminar();
  }

  void _siguiente() => _irA(_indice + 1, direccion: 1);
  void _atras() => _irA(_indice - 1, direccion: -1);

  void _terminar() {
    if (_terminado) return;
    _terminado = true;
    widget.onFinish();
  }

  void _salir() {
    if (_terminado) return;
    _terminado = true;
    widget.onSalir();
  }

  Offset? _bajadaEn;

  void _alBajarDedo(Offset posicion) {
    _bajadaEn = posicion;
  }

  void _alSoltarDedo(Offset posicion) {
    final bajada = _bajadaEn;
    _bajadaEn = null;
    if (bajada == null || (posicion - bajada).distance > 18) return;
    if (_avanzandoPorToque || _paso.avance == TutorialAvance.manual) return;
    _avanzandoPorToque = true;
    Future.delayed(const Duration(milliseconds: 450), () {
      _avanzandoPorToque = false;
      if (!mounted || _terminado) return;
      final ctx = _paso.key.currentContext;
      final ruta = ctx == null ? null : ModalRoute.of(ctx);
      if (ruta != null && !ruta.isCurrent) {
        _esperandoQueVuelva = true;
        setState(() => _rutaTapada = true);
        return;
      }
      _siguiente();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rutaTapada) return const SizedBox.shrink();
    final rect = _rect;
    final tamano = _tamano ?? MediaQuery.of(context).size;
    return Stack(
      children: [
        IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(painter: _PintorFoco(rect: rect)),
          ),
        ),
        if (rect != null && _paso.avance == TutorialAvance.tocar)
          Positioned.fromRect(
            rect: rect.inflate(8),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => _alBajarDedo(e.position),
              onPointerUp: (e) => _alSoltarDedo(e.position),
              child: const SizedBox.expand(),
            ),
          ),
        if (rect != null) _tarjeta(context, rect, tamano),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, Rect rect, Size tamano) {
    const margen = 14.0;
    const separacion = 12.0;
    final espacioAbajo = tamano.height - rect.bottom;
    final espacioArriba = rect.top;
    var abajo = _paso.alineacion != ContentAlign.top;
    if (abajo && espacioAbajo < 140 && espacioArriba > espacioAbajo) abajo = false;
    if (!abajo && espacioArriba < 140 && espacioAbajo > espacioArriba) abajo = true;

    return Positioned(
      left: margen,
      right: margen,
      top: abajo ? rect.bottom + separacion : null,
      bottom: abajo ? null : (tamano.height - rect.top) + separacion,
      child: _TarjetaExplicacion(
        paso: _paso,
        indice: _indice,
        total: widget.pasos.length,
        onAtras: _indice > 0 ? _atras : null,
        onSiguiente: _siguiente,
        onSalir: _salir,
      ),
    );
  }
}

class _PintorFoco extends CustomPainter {
  final Rect? rect;
  const _PintorFoco({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final pantallaCompleta = Path()..addRect(Offset.zero & size);
    final fondo = Paint()..color = _azulMarca.withValues(alpha: 0.85);
    final target = rect;
    if (target == null) {
      canvas.drawPath(pantallaCompleta, fondo);
      return;
    }
    final inflado = target.inflate(8);
    final rrect = RRect.fromRectAndRadius(inflado, const Radius.circular(12));
    final hueco = Path()..addRRect(rrect);
    final combinado = Path.combine(PathOperation.difference, pantallaCompleta, hueco);
    canvas.drawPath(combinado, fondo);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorFoco oldDelegate) => oldDelegate.rect != rect;
}

class _TarjetaExplicacion extends StatelessWidget {
  final TutorialPaso paso;
  final int indice;
  final int total;
  final VoidCallback? onAtras;
  final VoidCallback onSiguiente;
  final VoidCallback onSalir;

  const _TarjetaExplicacion({
    required this.paso,
    required this.indice,
    required this.total,
    required this.onAtras,
    required this.onSiguiente,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    paso.titulo,
                    style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: _azulMarca),
                  ),
                ),
                Text(
                  '${indice + 1}/$total',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (paso.obligatorio != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paso.obligatorio! ? const Color(0xFFFCE4E4) : const Color(0xFFE1F5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paso.obligatorio! ? 'Este campo es obligatorio' : 'Este campo lo podés dejar vacío',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: paso.obligatorio! ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(paso.explicacion, style: GoogleFonts.poppins(fontSize: 13, height: 1.4)),
            if (paso.avance == TutorialAvance.tocar) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Podés tocar lo resaltado para hacerlo de verdad y seguir solo.',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: onSalir,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                  child: Text('Salir del tutorial', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ),
                const Spacer(),
                if (onAtras != null)
                  TextButton(
                    onPressed: onAtras,
                    child: Text('Atrás', style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _azulMarca,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onSiguiente,
                  child: Text(
                    indice + 1 >= total ? 'Terminar' : 'Siguiente',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
