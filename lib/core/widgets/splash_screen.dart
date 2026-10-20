import '../theme/marca.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget siguiente;

  const SplashScreen({super.key, required this.siguiente});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _opacidad;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _opacidad = CurvedAnimation(parent: _controlador, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _escala = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOutBack));
    _controlador.forward();
    _irASiguiente();
  }

  Future<void> _irASiguiente() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
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
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Marca.primario,
      body: Center(
        child: AnimatedBuilder(
          animation: _controlador,
          builder: (context, child) {
            return Opacity(
              opacity: _opacidad.value,
              child: Transform.scale(scale: _escala.value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: Marca.primario,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'REPUESTOS',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
