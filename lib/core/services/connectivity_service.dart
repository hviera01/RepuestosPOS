import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final _connectivity = Connectivity();

  Stream<bool> get estadoConexion {
    return _connectivity.onConnectivityChanged.map(_hayConexion);
  }

  Future<bool> tieneConexionAhora() async {
    final resultado = await _connectivity.checkConnectivity();
    return _hayConexion(resultado);
  }

  bool _hayConexion(List<ConnectivityResult> resultados) {
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

final conectividadProvider = StreamProvider<bool>((ref) {
  final servicio = ref.watch(connectivityServiceProvider);
  return servicio.estadoConexion.startWith(true);
});

extension _StartWith on Stream<bool> {
  Stream<bool> startWith(bool valorInicial) async* {
    yield valorInicial;
    yield* this;
  }
}
