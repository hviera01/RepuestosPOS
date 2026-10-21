import 'core/utils/avisos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/marca.dart';
import 'features/negocio/providers/negocio_provider.dart';
import 'features/negocio/data/negocio_model.dart';
import 'features/ventas/providers/carrito_provider.dart';
import 'core/data/almacen_local.dart';
import 'core/data/sesion_servidor.dart';
import 'core/data/operaciones_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'core/widgets/app_shell.dart';
import 'core/widgets/splash_screen.dart';
import 'core/widgets/imagen_producto_network.dart';
import 'features/ventas/presentation/screens/escaneo_remoto_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Ocurrió un error al mostrar esta pantalla:\n${details.exception}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
  GoogleFonts.config.allowRuntimeFetching = false;
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    accessToken: () async => SesionServidor.token,
  );
  await AlmacenLocal.iniciar();
  await Marca.cargarGuardado();
  await OperacionesService.instancia.iniciar();
  ImagenProductoNetwork.precalentar();
  runApp(const ProviderScope(child: RepuestosApp()));
}

class RepuestosApp extends ConsumerWidget {
  const RepuestosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(temaVersionProvider);
    ref.listen<AsyncValue<NegocioModel>>(negocioStreamProvider, (previo, siguiente) {
      final negocio = siguiente.value;
      if (negocio == null) return;
      tipoDocumentoVentaPorDefecto = negocio.tipoDocumentoDefecto;
      if (Marca.aplicarDesdeConfig(negocio.tema)) {
        Marca.guardarLocal(Marca.primario);
        ref.read(temaVersionProvider.notifier).refrescar();
      }
    });
    final codigoEscaneo = Uri.base.queryParameters['escanear'];

    return MaterialApp(
      scaffoldMessengerKey: mensajeroGlobal,
      title: 'Repuestos POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Marca.primario,
        useMaterial3: true,
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: codigoEscaneo != null && codigoEscaneo.isNotEmpty
          ? EscaneoRemotoScreen(codigo: codigoEscaneo)
          : const SplashScreen(siguiente: AuthGate()),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final versionTema = ref.watch(temaVersionProvider);

    if (authState.usuario == null) {
      return KeyedSubtree(key: ValueKey('login$versionTema'), child: const LoginScreen());
    }

    return KeyedSubtree(key: ValueKey('shell$versionTema'), child: const AppShell());
  }
}
