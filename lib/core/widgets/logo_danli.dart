import 'package:flutter/material.dart';

class LogoDanli extends StatelessWidget {
  final double tamano;
  final double radio;
  final bool sombra;

  const LogoDanli({super.key, required this.tamano, this.radio = 12, this.sombra = false});

  @override
  Widget build(BuildContext context) {
    final imagen = ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Image.asset(
        'assets/images/logo_danli.jpg',
        width: tamano,
        height: tamano,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
    if (!sombra) return imagen;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 18))],
      ),
      child: imagen,
    );
  }
}
