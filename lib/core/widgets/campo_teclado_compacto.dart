import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/negocio/providers/negocio_provider.dart';
import '../../features/ventas/presentation/widgets/teclado_numerico_dialog.dart';
import '../utils/tablet_utils.dart';
import 'teclado_texto_dialog.dart';

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

  Future<void> _abrir(BuildContext context) async {
    final resultado = numerico
        ? await showDialog<String>(
            useRootNavigator: false,
            context: context,
            builder: (_) => TecladoNumericoDialog(
              titulo: titulo ?? 'Valor',
              valorInicial: controller.text,
            ),
          )
        : await showDialog<String>(
            useRootNavigator: false,
            context: context,
            builder: (_) => TecladoTextoDialog(
              titulo: titulo ?? 'Escribir',
              valorInicial: controller.text,
            ),
          );
    if (resultado == null) return;
    controller.text = resultado;
    onSubmitted?.call(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final negocio = ref.watch(negocioStreamProvider).value;
        final activo =
            (negocio?.tecladoCompactoTablet ?? false) &&
            esTabletTactil(context);
        if (!activo) return child;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _abrir(context),
          child: AbsorbPointer(child: child),
        );
      },
    );
  }
}
