import 'package:flutter/material.dart';
import 'logo_danli.dart';

class SplashScreen extends StatefulWidget {
  final Widget siguiente;

  const SplashScreen({super.key, required this.siguiente});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _barra;

  @override
  void initState() {
    super.initState();
    _barra = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
    _irASiguiente();
  }

  Future<void> _irASiguiente() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.siguiente,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _barra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoDanli(tamano: 168, radio: 28),
            const SizedBox(height: 22),
            const Text(
              'Cargando el sistema…',
              style: TextStyle(color: Color(0xFFCFCFCF), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
            ),
            const SizedBox(height: 14),
            Container(
              width: 150,
              height: 3,
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(3)),
              clipBehavior: Clip.hardEdge,
              child: AnimatedBuilder(
                animation: _barra,
                builder: (context, _) => FractionallySizedBox(
                  alignment: Alignment(-2.5 + 5 * _barra.value, 0),
                  widthFactor: 0.4,
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF2A93B), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
