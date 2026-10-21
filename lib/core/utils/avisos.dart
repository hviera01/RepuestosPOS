import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> mensajeroGlobal = GlobalKey<ScaffoldMessengerState>();

void avisarExito(String mensaje) {
  final m = mensajeroGlobal.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E7B4B),
      duration: const Duration(milliseconds: 2200),
      width: 420,
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ],
      ),
    ),
  );
}
