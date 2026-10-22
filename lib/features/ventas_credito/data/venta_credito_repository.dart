import '../../../core/data/operaciones_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/tabla_sincronizada.dart';
import '../../../core/data/consulta_paginada.dart';
import '../../../core/data/base_repository.dart';
import 'venta_credito_model.dart';
import 'abono_model.dart';
import 'venta_credito_import_service.dart';
import '../../../core/utils/formato_moneda.dart';

class VentaCreditoRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  String _generarNumeroDocumento() {
    final ahora = DateTime.now().millisecondsSinceEpoch.toString();
    return ahora.substring(ahora.length - 8);
  }

  static final TablaSincronizada<VentaCreditoModel> _tabla = TablaSincronizada<VentaCreditoModel>(
    tabla: 'ventas_credito',
    desdeFila: (f) => VentaCreditoModel.fromMap(f['id'] as String, f),
    orden: (a, b) => (b.fechaRegistro ?? DateTime(0)).compareTo(a.fechaRegistro ?? DateTime(0)),
  );

  Stream<List<VentaCreditoModel>> obtenerCreditos() => _tabla.observar();

  Future<VentaCreditoModel?> obtenerPorId(String id) {
    return conRed(() async {
      final filas = await _db.from('ventas_credito').select().eq('id', id).limit(1);
      if (filas.isEmpty) return null;
      return VentaCreditoModel.fromMap(filas.first['id'] as String, filas.first);
    });
  }

  Stream<List<AbonoModel>> obtenerAbonos(String idCredito) {
    return conRedStream(() => _db
        .from('venta_credito_abonos')
        .stream(primaryKey: ['id'])
        .eq('id_venta_credito', idCredito)
        .order('fecha', ascending: false)
        .map((filas) => filas.map((d) => AbonoModel.fromMap(d['id'] as String, d)).toList()));
  }

  Future<List<AbonoModel>> obtenerAbonosUnaVez(String idCredito) {
    return conRed(() async {
      final filas = await _db.from('venta_credito_abonos').select().eq('id_venta_credito', idCredito);
      return filas.map((d) => AbonoModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Future<List<VentaCreditoModel>> obtenerCreditosDeCliente({String? idCliente, String? documentoCliente}) {
    return conRed(() async {
      List<Map<String, dynamic>> filas;
      if (idCliente != null && idCliente.isNotEmpty) {
        filas = await _db.from('ventas_credito').select().eq('id_cliente', idCliente);
      } else if (documentoCliente != null && documentoCliente.trim().isNotEmpty && documentoCliente.trim() != 'N/A') {
        filas = await _db.from('ventas_credito').select().eq('documento_cliente', documentoCliente.trim());
      } else {
        return <VentaCreditoModel>[];
      }
      return filas.map((d) => VentaCreditoModel.fromMap(d['id'] as String, d)).toList();
    });
  }

  Future<void> crearCreditoManual({
    required String documentoCliente,
    required String nombreCliente,
    String? idCliente,
    required String numeroDocumento,
    required double montoTotal,
    required double saldoPendiente,
    required DateTime fechaVencimiento,
    String telefono = '',
  }) {
    return conRedExito('Crédito creado correctamente', () => _db.from('ventas_credito').insert({
          'documento_cliente': documentoCliente.isEmpty ? 'N/A' : documentoCliente,
          'nombre_cliente': nombreCliente,
          'id_cliente': (idCliente == null || idCliente.isEmpty) ? null : idCliente,
          'numero_documento': numeroDocumento.isEmpty ? _generarNumeroDocumento() : numeroDocumento,
          'monto_total': redondearMoneda(montoTotal),
          'saldo_pendiente': redondearMoneda(saldoPendiente),
          'fecha_vencimiento': fechaVencimiento.toIso8601String(),
          'sin_venta_origen': true,
          'telefono': telefono.trim(),
        }));
  }

  Future<void> actualizarTelefono(String id, String telefono) {
    return conRedExito('Teléfono actualizado correctamente', () => _db.from('ventas_credito').update({'telefono': telefono.trim()}).eq('id', id));
  }

  Future<void> registrarAbono({
    required String idCredito,
    required double saldoAnterior,
    required double montoAbonado,
    required double interes,
    required String metodoPago,
    required String numeroRecibo,
    required String usuario,
    required DateTime fecha,
  }) {
    return conRedExito('Abono registrado correctamente', () async {
      if (montoAbonado > saldoAnterior + interes + 0.01) {
        throw Exception('El abono (${formatearMoneda(montoAbonado)}) supera el saldo disponible en este crédito (${formatearMoneda(saldoAnterior + interes)})');
      }
      await OperacionesService.instancia.rpc('registrar_abono_venta_credito', {
        'payload': {
          'idCredito': idCredito,
          'saldoAnterior': saldoAnterior,
          'montoAbonado': montoAbonado,
          'interes': interes,
          'metodoPago': metodoPago,
          'numeroRecibo': numeroRecibo,
          'usuario': usuario,
          'fecha': fecha.toIso8601String(),
        },
      });
    });
  }

  Future<void> eliminarAbono({required String idCredito, required String idAbono, required double montoTotal}) {
    return conRedExito('Abono eliminado correctamente', () => OperacionesService.instancia.rpc('eliminar_abono_venta_credito', {
          'p_id_credito': idCredito,
          'p_id_abono': idAbono,
          'p_monto_total': montoTotal,
        }));
  }

  Future<void> editarAbono({
    required String idCredito,
    required String idAbono,
    required double montoTotal,
    required double montoAbonado,
    required double interes,
    required DateTime fecha,
    required String metodoPago,
    required String numeroRecibo,
  }) {
    return conRedExito('Abono actualizado correctamente', () => OperacionesService.instancia.rpc('editar_abono_venta_credito', {
          'payload': {
            'idCredito': idCredito,
            'idAbono': idAbono,
            'montoTotal': montoTotal,
            'montoAbonado': montoAbonado,
            'interes': interes,
            'fecha': fecha.toIso8601String(),
            'metodoPago': metodoPago,
            'numeroRecibo': numeroRecibo,
          },
        }));
  }

  Future<void> unirFacturas({
    required List<VentaCreditoModel> facturas,
    required String documentoCliente,
    required String nombreCliente,
    required DateTime fechaVencimiento,
  }) {
    return conRedExito('Facturas unidas correctamente', () async {
      try {
        await _db.rpc('unir_facturas_credito', params: {
          'p_ids': facturas.map((f) => f.id).toList(),
          'p_documento': documentoCliente,
          'p_nombre': nombreCliente,
          'p_vencimiento': fechaVencimiento.toIso8601String(),
          'p_numero': _generarNumeroDocumento(),
        });
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }
    });
  }

  Future<void> eliminar(String id) {
    return conRedExito('Crédito eliminado correctamente', () => _db.from('ventas_credito').delete().eq('id', id));
  }

  Future<int> importarCreditos(List<FilaImportacionVentaCredito> filas) {
    return conRedExito('Créditos importados correctamente', () async {
      final validas = filas.where((f) => f.valido).toList();
      if (validas.isEmpty) return 0;
      final filasInsertar = validas.map((fila) => {
            'documento_cliente': fila.documentoCliente.isEmpty ? 'N/A' : fila.documentoCliente,
            'nombre_cliente': fila.nombreCliente,
            'numero_documento': fila.numeroDocumento.isEmpty ? fila.numeroFila.toString() : fila.numeroDocumento,
            'monto_total': fila.montoTotal,
            'saldo_pendiente': fila.saldoPendiente,
            'fecha_registro': fila.fechaRegistro?.toIso8601String(),
            'fecha_vencimiento': fila.fechaVencimiento.toIso8601String(),
            'sin_venta_origen': true,
          }).toList();
      await _db.from('ventas_credito').insert(filasInsertar);
      return validas.length;
    });
  }

  Future<List<AbonoModel>> obtenerAbonosPorRango(DateTime inicio, DateTime finInclusive) {
    return conRed(() async {
      final filas = await traerTodo(
        () => _db
            .from('venta_credito_abonos')
            .select()
            .gte('fecha', inicio.toIso8601String())
            .lte('fecha', finInclusive.toIso8601String())
            .order('fecha')
            .order('id'),
      );
      return filas.map((d) => AbonoModel.fromMap(d['id'] as String, d)).toList();
    });
  }
}
