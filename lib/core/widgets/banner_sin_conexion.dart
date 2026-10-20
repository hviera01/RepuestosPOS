import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

class BannerSinConexion extends ConsumerWidget {
  const BannerSinConexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conectividad = ref.watch(conectividadProvider);
    final hayConexion = conectividad.asData?.value ?? true;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: hayConexion
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              color: const Color(0xFFB71C1C),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sin conexión a internet — lo que hagas ahora puede no guardarse',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
