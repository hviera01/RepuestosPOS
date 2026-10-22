import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ventas/data/presencia_impresion_repository.dart';

class ImpresionRemotaService {
  final _db = Supabase.instance.client;
  final _presencia = PresenciaImpresionRepository();

  Future<bool> hayPcPrincipal() => _presencia.estaConectada();

  Future<void> enviar(List<int> bytes, String descripcion) async {
    await _db.from('impresiones_remotas').insert({
      'descripcion': descripcion,
      'datos': base64Encode(bytes),
    });
  }

  Stream<List<Map<String, dynamic>>> escuchar() =>
      _db.from('impresiones_remotas').stream(primaryKey: ['id']);

  Future<List<int>?> reclamar(String id) async {
    try {
      final filas = await _db.from('impresiones_remotas').delete().eq('id', id).select('datos');
      if (filas.isEmpty) return null;
      return base64Decode(filas.first['datos'] as String);
    } catch (_) {
      return null;
    }
  }
}

final impresionesRemotasProvider = StreamProvider<List<Map<String, dynamic>>>((ref) => ImpresionRemotaService().escuchar());
