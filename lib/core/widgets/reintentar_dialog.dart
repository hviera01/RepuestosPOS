import '../theme/marca.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<T?> ejecutarConReintento<T>(
  BuildContext context,
  Future<T> Function() accion,
) async {
  while (true) {
    try {
      return await accion();
    } catch (e) {
      if (!context.mounted) return null;
      final esTimeout = e is TimeoutException;
      final reintentar = await showDialog<bool>(
        useRootNavigator: false,
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off_outlined, color: Marca.primario),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No se pudo guardar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            esTimeout
                ? 'Parece que falló la conexión a internet. Todavía no se guardó el cambio: podés reintentar sin perder lo que escribiste.'
                : 'Ocurrió un error y no se guardó el cambio. Podés reintentar sin perder lo que escribiste.\n\n${e.toString().replaceAll('Exception: ', '')}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.poppins()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Marca.primario,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Reintentar', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
      if (reintentar != true) return null;
    }
  }
}
