import '../theme/marca.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/actualizacion_service.dart';

Future<void> mostrarDialogoActualizacionRespaldo(BuildContext context, String motivoFallo) {
  return showDialog(
    useRootNavigator: false,
    context: context,
    builder: (context) => _ActualizacionRespaldoDialog(motivoFallo: motivoFallo),
  );
}

class _ActualizacionRespaldoDialog extends StatelessWidget {
  final String motivoFallo;
  const _ActualizacionRespaldoDialog({required this.motivoFallo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('No se pudo revisar automáticamente', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Marca.primario)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudo conectar para revisar si hay una versión nueva. Puede que este equipo tenga un problema de red o de certificado de seguridad puntual.',
              style: GoogleFonts.poppins(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Tocá "Actualizar" para abrir la descarga directamente en el navegador -si ya estás al día, no pasa nada, simplemente reinstala la misma versión-.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Text(motivoFallo, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade400)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: GoogleFonts.poppins(color: Colors.grey.shade700))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Marca.primario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () {
            ActualizacionService.abrirDescargaDirecta();
            Navigator.pop(context);
          },
          child: Text('Actualizar', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}
