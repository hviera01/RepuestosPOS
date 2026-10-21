import '../../../../core/theme/marca.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/negocio_provider.dart';

const _tamanoMaximoBytes = 1500 * 1024;

class NegocioLogoPicker extends ConsumerStatefulWidget {
  final String logoColorBase64;
  final String logoBnBase64;

  const NegocioLogoPicker({super.key, required this.logoColorBase64, required this.logoBnBase64});

  @override
  ConsumerState<NegocioLogoPicker> createState() => _NegocioLogoPickerState();
}

class _NegocioLogoPickerState extends ConsumerState<NegocioLogoPicker> {
  bool _subiendo = false;

  Future<void> _subir() async {
    final resultado = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (resultado == null || resultado.files.isEmpty) return;
    final bytes = resultado.files.first.bytes;
    if (bytes == null) {
      _mostrarError('No se pudo leer el archivo seleccionado');
      return;
    }
    if (bytes.length > _tamanoMaximoBytes) {
      _mostrarError('La imagen pesa demasiado (máx. 1.5 MB). Elija una más liviana.');
      return;
    }
    setState(() => _subiendo = true);
    try {
      await ref.read(negocioRepositoryProvider).guardarLogo(bytes);
    } catch (e) {
      _mostrarError('No se pudo guardar el logo');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _quitar() async {
    setState(() => _subiendo = true);
    try {
      await ref.read(negocioRepositoryProvider).quitarLogo();
    } catch (e) {
      _mostrarError('No se pudo quitar el logo');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _vista(String titulo, String base64) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB6BCC7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _imagen(base64),
        ),
      ],
    );
  }

  Widget _imagen(String base64) {
    if (base64.isEmpty) return Icon(Icons.image_outlined, size: 34, color: Colors.grey.shade400);
    try {
      return Image.memory(
        base64Decode(base64),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, size: 30, color: Colors.grey.shade400),
      );
    } catch (_) {
      return Icon(Icons.broken_image_outlined, size: 30, color: Colors.grey.shade400);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiene = widget.logoColorBase64.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Logo del negocio', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        Text(
          'Suba solo el logo normal, a color. El sistema lo pasa solo a blanco y negro para los tickets; usted no tiene que subir otro.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _vista('Logo', widget.logoColorBase64),
            if (tiene) _vista('Así sale en el ticket', widget.logoBnBase64),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _subiendo ? null : _subir,
                  icon: _subiendo
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Marca.primario))
                      : const Icon(Icons.upload_outlined, size: 16),
                  label: Text(_subiendo ? 'Guardando...' : (tiene ? 'Cambiar logo' : 'Subir logo'), style: GoogleFonts.poppins(fontSize: 12)),
                ),
                if (tiene)
                  TextButton.icon(
                    onPressed: _subiendo ? null : _quitar,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Quitar logo', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
