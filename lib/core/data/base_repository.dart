import 'dart:async';
import 'dart:io';
import 'package:postgrest/postgrest.dart';

class SinConexionException implements Exception {
  final String mensaje;
  const SinConexionException([this.mensaje = 'Sin conexión a internet']);

  @override
  String toString() => mensaje;
}

bool esErrorDeRed(Object e) {
  if (e is SinConexionException) return true;
  if (e is SocketException || e is TimeoutException) return true;
  if (e is PostgrestException && (e.code == null || e.code!.isEmpty)) return true;
  final texto = e.toString().toLowerCase();
  return texto.contains('socketexception') ||
      texto.contains('failed host lookup') ||
      texto.contains('network is unreachable') ||
      texto.contains('connection failed') ||
      texto.contains('connection closed') ||
      texto.contains('connection reset') ||
      texto.contains('clientexception') ||
      texto.contains('xmlhttprequest') ||
      texto.contains('sin conexión');
}

Object traducirError(Object e) {
  if (e is SinConexionException) return e;
  if (esErrorDeRed(e)) return const SinConexionException();
  return e;
}

mixin ConRedMixin {
  Future<T> conRed<T>(Future<T> Function() operacion) async {
    try {
      return await operacion();
    } catch (e) {
      throw traducirError(e);
    }
  }

  Stream<T> conRedStream<T>(Stream<T> Function() operacion) {
    late StreamController<T> controller;
    StreamSubscription<T>? suscripcion;
    controller = StreamController<T>(
      onListen: () {
        suscripcion = operacion().listen(
          controller.add,
          onError: (Object e, StackTrace st) => controller.addError(traducirError(e), st),
          onDone: controller.close,
        );
      },
      onCancel: () => suscripcion?.cancel(),
    );
    return controller.stream;
  }
}
