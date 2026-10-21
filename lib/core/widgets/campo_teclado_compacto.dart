import 'package:flutter/material.dart';

class CampoTecladoCompacto extends StatelessWidget {
  final TextEditingController controller;
  final Widget child;
  final bool numerico;
  final String? titulo;
  final ValueChanged<String>? onSubmitted;

  const CampoTecladoCompacto({
    super.key,
    required this.controller,
    required this.child,
    this.numerico = false,
    this.titulo,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => child;
}
