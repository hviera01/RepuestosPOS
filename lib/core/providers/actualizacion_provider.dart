import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/actualizacion_service.dart';

class ActualizacionDisponibleNotifier extends Notifier<ActualizacionDisponible?> {
  @override
  ActualizacionDisponible? build() => null;

  void establecer(ActualizacionDisponible? actualizacion) {
    state = actualizacion;
  }
}

final actualizacionDisponibleProvider = NotifierProvider<ActualizacionDisponibleNotifier, ActualizacionDisponible?>(
  ActualizacionDisponibleNotifier.new,
);
