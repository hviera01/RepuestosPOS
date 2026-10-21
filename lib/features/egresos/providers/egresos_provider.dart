import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/egreso_repository.dart';

final egresoRepositoryProvider = Provider((ref) => EgresoRepository());

final egresoCategoriaRepositoryProvider = Provider((ref) => EgresoCategoriaRepository());

final egresoCategoriasProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(egresoCategoriaRepositoryProvider).obtenerActivas();
});
