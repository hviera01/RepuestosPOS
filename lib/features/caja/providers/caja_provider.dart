import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/caja_repository.dart';

final cajaRepositoryProvider = Provider((ref) => CajaRepository());
