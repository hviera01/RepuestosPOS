import 'webauthn_stub.dart' if (dart.library.html) 'webauthn_web.dart' as impl;

Future<bool> webAuthnDisponible() => impl.autenticadorPlataformaDisponible();

Future<String?> webAuthnRegistrar({required String usuarioId, required String usuarioNombre}) =>
    impl.registrarCredencial(usuarioId: usuarioId, usuarioNombre: usuarioNombre);

Future<bool> webAuthnVerificar(String credencialIdBase64Url) => impl.verificarCredencial(credencialIdBase64Url);
