import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/marca.dart';

class FondoLoginArte extends StatelessWidget {
  final Animation<double> giro;

  const FondoLoginArte({super.key, required this.giro});

  static Color acento() {
    final hsl = HSLColor.fromColor(Marca.primario);
    if (hsl.saturation < 0.28) return const Color(0xFFF2A93B);
    return hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 0.8)).withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(Marca.primario);
    final profundo = hsl.withLightness((hsl.lightness * 0.38).clamp(0.04, 0.5)).toColor();
    final medio = hsl.withLightness((hsl.lightness * 0.8).clamp(0.08, 0.6)).toColor();
    final luz = acento();
    return LayoutBuilder(
      builder: (context, c) {
        final lado = math.max(c.maxWidth, c.maxHeight);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [medio, profundo, Color.lerp(profundo, Colors.black, 0.55)!],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              Positioned(
                right: -lado * 0.08,
                bottom: -lado * 0.1,
                child: Container(
                  width: lado * 0.95,
                  height: lado * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [luz.withValues(alpha: 0.36), luz.withValues(alpha: 0.10), Colors.transparent], stops: const [0, 0.5, 1]),
                  ),
                ),
              ),
              Positioned(
                left: -lado * 0.18,
                top: -lado * 0.2,
                child: Container(
                  width: lado * 0.75,
                  height: lado * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.13), Colors.transparent]),
                  ),
                ),
              ),
              CustomPaint(painter: _RayasPainter(luz.withValues(alpha: 0.10))),
              Positioned(
                right: -lado * 0.16,
                bottom: -lado * 0.2,
                child: RotationTransition(
                  turns: giro,
                  child: CustomPaint(size: Size.square(lado * 0.92), painter: _DiscoFrenoPainter(luz)),
                ),
              ),
              Positioned(
                left: -lado * 0.07,
                bottom: lado * 0.06,
                child: RotationTransition(
                  turns: ReverseAnimation(giro),
                  child: CustomPaint(size: Size.square(lado * 0.3), painter: _DiscoFrenoPainter(Colors.white, opacidad: 0.55)),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.15,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RayasPainter extends CustomPainter {
  final Color color;

  _RayasPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final paso = 54.0;
    for (var x = -size.height; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * 0.75, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RayasPainter old) => old.color != color;
}

class _DiscoFrenoPainter extends CustomPainter {
  final Color luz;
  final double opacidad;

  _DiscoFrenoPainter(this.luz, {this.opacidad = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final metal = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: 0.30 * opacidad),
        Colors.white.withValues(alpha: 0.07 * opacidad),
        luz.withValues(alpha: 0.24 * opacidad),
        Colors.white.withValues(alpha: 0.26 * opacidad),
        Colors.white.withValues(alpha: 0.06 * opacidad),
        luz.withValues(alpha: 0.20 * opacidad),
        Colors.white.withValues(alpha: 0.30 * opacidad),
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, Paint()..shader = metal);
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.012..color = Colors.white.withValues(alpha: 0.35 * opacidad));
    canvas.drawCircle(c, r * 0.9, Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.006..color = Colors.black.withValues(alpha: 0.30 * opacidad));

    final ranura = Paint()..color = Colors.black.withValues(alpha: 0.42 * opacidad);
    const n = 36;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      final rect = RRect.fromRectAndRadius(Rect.fromLTRB(r * 0.5, -r * 0.022, r * 0.84, r * 0.022), Radius.circular(r * 0.022));
      canvas.drawRRect(rect, ranura);
      canvas.restore();
    }

    for (final f in [0.86, 0.47]) {
      canvas.drawCircle(c, r * f, Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.008..color = Colors.white.withValues(alpha: 0.22 * opacidad));
    }

    canvas.drawCircle(c, r * 0.44, Paint()..color = Colors.black.withValues(alpha: 0.38 * opacidad));
    canvas.drawCircle(c, r * 0.42, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.22 * opacidad), luz.withValues(alpha: 0.10 * opacidad)]).createShader(Rect.fromCircle(center: c, radius: r * 0.42)));
    for (var i = 0; i < 5; i++) {
      final a = 2 * math.pi * i / 5 - math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * (r * 0.27);
      canvas.drawCircle(p, r * 0.045, Paint()..color = Colors.black.withValues(alpha: 0.5 * opacidad));
      canvas.drawCircle(p, r * 0.03, Paint()..color = Colors.white.withValues(alpha: 0.35 * opacidad));
    }
    canvas.drawCircle(c, r * 0.1, Paint()..color = Colors.black.withValues(alpha: 0.5 * opacidad));
    canvas.drawCircle(c, r * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.2 * opacidad));
  }

  @override
  bool shouldRepaint(covariant _DiscoFrenoPainter old) => old.luz != luz || old.opacidad != opacidad;
}
