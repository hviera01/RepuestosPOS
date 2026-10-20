import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/busqueda_producto.dart';

FiltroVehiculo filtroDesdeCampos(TextEditingController vehiculo, TextEditingController anio) =>
    FiltroVehiculo(texto: vehiculo.text, anio: parsearAnio(anio.text));

class FiltroVehiculoCampos extends StatelessWidget {
  final TextEditingController vehiculoCtrl;
  final TextEditingController anioCtrl;
  final VoidCallback onBuscar;
  final bool compacto;

  const FiltroVehiculoCampos({
    super.key,
    required this.vehiculoCtrl,
    required this.anioCtrl,
    required this.onBuscar,
    this.compacto = false,
  });

  Widget _campo({
    required TextEditingController ctrl,
    required String hint,
    required IconData icono,
    required double ancho,
    List<TextInputFormatter>? formatters,
    TextInputType? teclado,
  }) {
    return Container(
      width: ancho,
      height: compacto ? 46 : 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB6BCC7)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.poppins(fontSize: 13),
              inputFormatters: formatters,
              keyboardType: teclado,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => onBuscar(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([vehiculoCtrl, anioCtrl]),
      builder: (context, _) {
        final hayAlgo = vehiculoCtrl.text.isNotEmpty || anioCtrl.text.isNotEmpty;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _campo(
              ctrl: vehiculoCtrl,
              hint: 'Vehículo (ej. toyota hilux)',
              icono: Icons.directions_car_outlined,
              ancho: 240,
            ),
            _campo(
              ctrl: anioCtrl,
              hint: 'Año',
              icono: Icons.event_outlined,
              ancho: 100,
              teclado: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            ),
            if (hayAlgo)
              IconButton(
                tooltip: 'Quitar vehículo y año',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  vehiculoCtrl.clear();
                  anioCtrl.clear();
                  onBuscar();
                },
              ),
          ],
        );
      },
    );
  }
}
