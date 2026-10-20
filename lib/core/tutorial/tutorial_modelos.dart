import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
export 'package:tutorial_coach_mark/tutorial_coach_mark.dart' show ContentAlign;

enum TutorialAvance {
  tocar,

  manual,
}

class TutorialPaso {
  final GlobalKey key;
  final String titulo;
  final String explicacion;
  final bool? obligatorio;
  final ContentAlign alineacion;
  final TutorialAvance avance;

  const TutorialPaso({
    required this.key,
    required this.titulo,
    required this.explicacion,
    this.obligatorio,
    this.alineacion = ContentAlign.bottom,
    this.avance = TutorialAvance.tocar,
  });
}

class TutorialTema {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<TutorialPaso> Function() pasos;
  final String? bienvenida;
  final VoidCallback? alEmpezar;

  const TutorialTema({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.pasos,
    this.bienvenida,
    this.alEmpezar,
  });
}
