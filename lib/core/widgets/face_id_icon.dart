import 'package:flutter/material.dart';

class FaceIdIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double grosorTrazo;

  const FaceIdIcon({super.key, this.size = 24, required this.color, this.grosorTrazo = 7});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FaceIdIconPainter(color: color, grosorTrazo: grosorTrazo),
    );
  }
}

class _FaceIdIconPainter extends CustomPainter {
  final Color color;
  final double grosorTrazo;

  _FaceIdIconPainter({required this.color, required this.grosorTrazo});

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / 100;
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosorTrazo * escala
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path esquina() {
      return Path()
        ..moveTo(10 * escala, 34 * escala)
        ..lineTo(10 * escala, 20 * escala)
        ..quadraticBezierTo(10 * escala, 10 * escala, 20 * escala, 10 * escala)
        ..lineTo(34 * escala, 10 * escala);
    }

    final centro = Offset(size.width / 2, size.height / 2);
    for (final grados in [0, 90, 180, 270]) {
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(grados * 3.14159265 / 180);
      canvas.translate(-centro.dx, -centro.dy);
      canvas.drawPath(esquina(), trazo);
      canvas.restore();
    }

    canvas.drawLine(Offset(38 * escala, 42 * escala), Offset(38 * escala, 50 * escala), trazo);
    canvas.drawLine(Offset(62 * escala, 42 * escala), Offset(62 * escala, 50 * escala), trazo);

    final nariz = Path()
      ..moveTo(50 * escala, 42 * escala)
      ..lineTo(50 * escala, 60 * escala)
      ..lineTo(56 * escala, 63 * escala);
    canvas.drawPath(nariz, trazo);

    final boca = Path()
      ..moveTo(37 * escala, 70 * escala)
      ..quadraticBezierTo(50 * escala, 81 * escala, 63 * escala, 70 * escala);
    canvas.drawPath(boca, trazo);
  }

  @override
  bool shouldRepaint(covariant _FaceIdIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.grosorTrazo != grosorTrazo;
}
