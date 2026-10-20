import '../../../../core/theme/marca.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _urlSitioWeb = 'https://hviera01.github.io/RepuestosPOS/';

class EscanearRemotoDialog extends StatefulWidget {
  final String codigo;
  final Stream<List<Map<String, dynamic>>> eventos;
  final Stream<bool> conectado;

  const EscanearRemotoDialog({super.key, required this.codigo, required this.eventos, required this.conectado});

  @override
  State<EscanearRemotoDialog> createState() => _EscanearRemotoDialogState();
}

class _EscanearRemotoDialogState extends State<EscanearRemotoDialog> {
  StreamSubscription<bool>? _suscripcionConectado;

  @override
  void initState() {
    super.initState();
    _suscripcionConectado = widget.conectado.listen((conectado) {
      if (conectado && mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _suscripcionConectado?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = '$_urlSitioWeb?escanear=${widget.codigo}';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text('Escanear con el celular', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Apuntá la cámara del celular a este código QR (no hace falta ninguna app, se abre directo en el navegador). Esta ventana se cierra sola apenas el celular se conecte.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF2F3F7), borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: url, size: 200, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 14),
            Text('Código: ${widget.codigo}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

class EscaneoActivoDialog extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> eventos;
  final VoidCallback alFinalizar;
  final VoidCallback alEscanearOtro;

  const EscaneoActivoDialog({super.key, required this.eventos, required this.alFinalizar, required this.alEscanearOtro});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering, color: Colors.green.shade600, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Escaneo activo', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: eventos,
              builder: (context, snapshot) {
                final total = snapshot.data?.length ?? 0;
                return Text(
                  'Hay un celular conectado y escaneando ($total código(s) recibido(s)).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: alEscanearOtro,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: Text('Escanear con otro celular', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFB6BCC7)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: alFinalizar,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text('Finalizar escaneo', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Marca.primario,
                  side: BorderSide(color: Marca.primario),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
