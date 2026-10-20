import 'dart:math' as math;
import 'package:flutter/material.dart';

class LogoGenerico extends StatelessWidget {
  final double tamano;
  final Color color;

  const LogoGenerico({super.key, required this.tamano, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _EngranajePainter(color)),
    );
  }
}

class _EngranajePainter extends CustomPainter {
  final Color color;
  _EngranajePainter(this.color);

  static const _dientes = 10;
  static const _cuerpo = 265 / 1024;
  static const _diente = 375 / 1024;
  static const _hueco = 130 / 1024;

  double _radioLimite(double angulo) {
    const paso = 2 * math.pi / _dientes;
    var t = (angulo % paso) / paso;
    if (t < 0) t += 1;
    final d = (t - 0.5).abs() * 2;
    if (d < 0.38) return _diente;
    if (d < 0.6) return _diente + (_cuerpo - _diente) * ((d - 0.38) / 0.22);
    return _cuerpo;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final centro = Offset(s / 2, s / 2);
    final camino = Path();
    const pasos = 720;
    for (var i = 0; i <= pasos; i++) {
      final a = 2 * math.pi * i / pasos - math.pi;
      final r = _radioLimite(a) * s;
      final p = Offset(centro.dx + r * math.cos(a), centro.dy + r * math.sin(a));
      if (i == 0) {
        camino.moveTo(p.dx, p.dy);
      } else {
        camino.lineTo(p.dx, p.dy);
      }
    }
    camino.close();
    camino.addOval(Rect.fromCircle(center: centro, radius: _hueco * s));
    camino.fillType = PathFillType.evenOdd;
    canvas.drawPath(camino, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(covariant _EngranajePainter old) => old.color != color;
}
