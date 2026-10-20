Future<T> conReintentos<T>(
  Future<T> Function() accion, {
  int intentos = 3,
  Duration esperaEntreIntentos = const Duration(seconds: 2),
}) async {
  for (var intento = 1; intento <= intentos; intento++) {
    try {
      return await accion();
    } catch (_) {
      if (intento == intentos) rethrow;
      await Future.delayed(esperaEntreIntentos);
    }
  }
  throw StateError('conReintentos: no debería llegar acá');
}
