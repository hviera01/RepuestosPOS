import '../../../../core/theme/marca.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/face_id_storage.dart';
import '../../../../core/utils/tablet_utils_stub.dart' if (dart.library.html) '../../../../core/utils/tablet_utils_web.dart' as tactil;
import '../../../../core/utils/webauthn.dart';
import '../../../../core/widgets/face_id_icon.dart';
import '../../providers/auth_provider.dart';
import '../widgets/fondo_login.dart';
import '../../../../core/widgets/logo_danli.dart';

bool get _esWebMovil =>
    kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        (defaultTargetPlatform == TargetPlatform.macOS && tactil.esDispositivoTactil()));

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  late final AnimationController _entrada;
  late final AnimationController _giro;
  final _codigoController = TextEditingController();
  final _claveController = TextEditingController();
  bool _ocultarClave = true;

  String? _credencialFaceId;
  bool _verificandoFaceId = false;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _giro = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    if (_esWebMovil) _cargarCredencialFaceId();
  }

  Future<void> _cargarCredencialFaceId() async {
    final credencial = await credencialFaceIdGuardada();
    if (mounted) setState(() => _credencialFaceId = credencial);
  }

  @override
  void dispose() {
    _entrada.dispose();
    _giro.dispose();
    _codigoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final codigo = _codigoController.text.trim();
    final clave = _claveController.text.trim();
    if (codigo.isEmpty || clave.isEmpty) return;
    await ref.read(authProvider.notifier).login(codigo, clave);
    if (!mounted) return;
    final usuario = ref.read(authProvider).usuario;
    if (usuario == null) return;
  }

  Future<void> _entrarConFaceId() async {
    final credencial = _credencialFaceId;
    if (credencial == null || _verificandoFaceId) return;
    setState(() => _verificandoFaceId = true);
    try {
      final verificado = await webAuthnVerificar(credencial);
      if (!verificado) return;
      final credenciales = await credencialesLoginGuardadas();
      if (credenciales == null) return;
      if (!mounted) return;
      await ref.read(authProvider.notifier).login(credenciales.codigo, credenciales.clave);
    } finally {
      if (mounted) setState(() => _verificandoFaceId = false);
    }
  }

  Future<void> _olvidarFaceId() async {
    await olvidarCredencialesFaceId();
    if (mounted) setState(() => _credencialFaceId = null);
  }

  InputDecoration _decoracion(String etiqueta, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      prefixIcon: Icon(icono, size: 20),
      suffixIcon: sufijo,
      filled: true,
      fillColor: const Color(0xFFF0F2F6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE1E4EA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Marca.primario, width: 1.6)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Widget _formulario(AuthState authState, {required bool conLogo}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (conLogo) ...[
          const Center(child: LogoDanli(tamano: 150, radio: 26, sombra: true)),
          const SizedBox(height: 22),
        ],
        Text(
          'Bienvenido',
          textAlign: conLogo ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23), height: 1.1),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingrese con su código de acceso',
          textAlign: conLogo ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        TextField(
          autocorrect: false,
          enableSuggestions: false,
          controller: _codigoController,
          keyboardType: _esWebMovil ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 14.5),
          textInputAction: TextInputAction.next,
          decoration: _decoracion('Código de acceso', Icons.badge_outlined),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _claveController,
          obscureText: _ocultarClave,
          keyboardType: _esWebMovil ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 14.5),
          onSubmitted: (_) => _iniciarSesion(),
          decoration: _decoracion(
            'Contraseña',
            Icons.lock_outline,
            sufijo: IconButton(
              icon: Icon(_ocultarClave ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
            ),
          ),
        ),
        if (authState.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(authState.error!, style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: authState.cargando ? null : _iniciarSesion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Marca.primario,
              foregroundColor: Marca.sobrePrimario,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: authState.cargando
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Marca.sobrePrimario, strokeWidth: 2.4))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ingresar', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Marca.sobrePrimario)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19, color: Marca.sobrePrimario),
                    ],
                  ),
          ),
        ),
        if (_esWebMovil && _credencialFaceId != null) ...[
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Material(
                  color: const Color(0xFFF0F2F6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _verificandoFaceId ? null : _entrarConFaceId,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _verificandoFaceId
                          ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: Marca.primario))
                          : FaceIdIcon(size: 26, color: Marca.primario),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Entrar con Face ID', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                TextButton(
                  onPressed: _olvidarFaceId,
                  child: Text('¿No es usted? Olvidar Face ID', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final ancho = MediaQuery.of(context).size.width;
    final ancha = ancho >= 960;
    final animacion = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);

    Widget animar(Widget hijo) => FadeTransition(
          opacity: CurvedAnimation(parent: _entrada, curve: Curves.easeOut),
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animacion), child: hijo),
        );

    if (ancha) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FondoLoginArte(giro: _giro),
                  Center(child: animar(const LogoDanli(tamano: 380, radio: 40, sombra: true))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 52, 56, 52),
                    child: animar(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const LogoDanli(tamano: 52, radio: 12),
                              const SizedBox(width: 14),
                              Text('DANLI AUTOPARTS', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 9,
              child: Container(
                color: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: animar(_formulario(authState, conLogo: false)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final anchoTarjeta = ancho < 480 ? ancho - 32 : 440.0;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FondoLoginArte(giro: _giro),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: animar(
                Container(
                  width: anchoTarjeta,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 18))],
                  ),
                  child: _formulario(authState, conLogo: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
