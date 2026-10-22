import '../../../core/utils/avisos.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import '../../../core/utils/reintentos.dart';
import 'dart:async';
import '../../../core/utils/impresora_local.dart';
import 'negocio_model.dart';

class NegocioRepository with ConRedMixin {
  final _db = Supabase.instance.client;

  static NegocioModel? _cache;
  static DateTime? _cacheFecha;
  static const _vigenciaCache = Duration(minutes: 10);

  String hashClave(String clave) {
    return sha256.convert(utf8.encode(clave)).toString();
  }

  static final TablaSincronizada<NegocioModel> _tabla = TablaSincronizada<NegocioModel>(
    tabla: 'negocio_config',
    desdeFila: (f) => NegocioModel.fromMap(f),
    intervaloRespaldo: const Duration(minutes: 3),
  );

  static final _cambiosLocales = StreamController<void>.broadcast();

  static NegocioModel _conLocal(NegocioModel n) => n.copyWith(
        impresoraTermicaUrl: ImpresoraLocal.termicaUrl,
        impresoraTermicaNombre: ImpresoraLocal.termicaNombre,
        impresoraEtiquetasUrl: ImpresoraLocal.etiquetasUrl,
        impresoraEtiquetasNombre: ImpresoraLocal.etiquetasNombre,
        impresoraRedIp: ImpresoraLocal.redIp,
        impresoraRedPuerto: ImpresoraLocal.redPuerto,
        impresoraBluetoothId: ImpresoraLocal.bluetoothId,
        impresoraBluetoothNombre: ImpresoraLocal.bluetoothNombre,
        impresoraUsbUsarDriverWindows: ImpresoraLocal.usarDriverWindows,
      );

  Stream<NegocioModel> obtenerNegocio() {
    late StreamController<NegocioModel> control;
    NegocioModel? ultimo;
    StreamSubscription<List<NegocioModel>>? s1;
    StreamSubscription<void>? s2;
    control = StreamController<NegocioModel>(
      onListen: () {
        s1 = _tabla.observar().listen((lista) {
          ultimo = lista.isEmpty ? const NegocioModel() : lista.first;
          control.add(_conLocal(ultimo!));
        }, onError: control.addError);
        s2 = _cambiosLocales.stream.listen((_) {
          final u = ultimo;
          if (u != null) control.add(_conLocal(u));
        });
      },
      onCancel: () async {
        await s1?.cancel();
        await s2?.cancel();
      },
    );
    return control.stream;
  }

  Future<void> sincronizarAhora() => _tabla.sincronizar();

  Future<bool> verificarClaveEspecial(String clave) {
    return conRed(() async {
      final r = await _db.rpc('verificar_clave_especial', params: {'p_hash': hashClave(clave)});
      return r == true;
    });
  }

  Future<NegocioModel> obtenerNegocioActual() async {
    final cache = _cache;
    final cacheFecha = _cacheFecha;
    if (cache != null &&
        cacheFecha != null &&
        DateTime.now().difference(cacheFecha) < _vigenciaCache) {
      return _conLocal(cache);
    }
    final local = _tabla.actual;
    if (local.isNotEmpty && _tabla.sincronizadoAlgunaVez) return _conLocal(local.first);
    try {
      final filas = await _db.from('negocio_config').select().limit(1).timeout(const Duration(seconds: 8));
      final negocio = NegocioModel.fromMap(filas.isEmpty ? null : filas.first);
      _cache = negocio;
      _cacheFecha = DateTime.now();
      return _conLocal(negocio);
    } catch (_) {
      return _conLocal(cache ?? const NegocioModel());
    }
  }

  Future<NegocioModel> obtenerNegocioParaSeguridad() async {
    final cache = _cache;
    final cacheFecha = _cacheFecha;
    if (cache != null &&
        cacheFecha != null &&
        DateTime.now().difference(cacheFecha) < _vigenciaCache) {
      return cache;
    }
    return conReintentos(() async {
      final filas = await _db.from('negocio_config').select().limit(1).timeout(const Duration(seconds: 8));
      final negocio = NegocioModel.fromMap(filas.isEmpty ? null : filas.first);
      _cache = negocio;
      _cacheFecha = DateTime.now();
      return _conLocal(negocio);
    });
  }

  void _invalidarCache() {
    _cache = null;
    _cacheFecha = null;
  }

  Future<void> _guardar(Map<String, dynamic> datos, {String? exito}) {
    return conRed(() async {
      final fila = await _db.from('negocio_config').upsert({'id': 1, ...datos}).select().single();
      _tabla.aplicarLocal(fila);
      _invalidarCache();
      if (exito != null) avisarExito(exito);
    });
  }

  Future<void> actualizarDatosGenerales({
    required String nombre,
    required String correo,
    required String rtn,
    required String cai,
    required String direccion,
    required String telefono,
    required String eslogan,
    required String rangoPrefijo,
    required String rangoDesde,
    required String rangoHasta,
    required DateTime? fechaLimiteEmision,
  }) {
    return _guardar({
      'nombre': nombre,
      'correo': correo,
      'rtn': rtn,
      'cai': cai,
      'direccion': direccion,
      'telefono': telefono,
      'eslogan': eslogan,
      'rango_prefijo': rangoPrefijo,
      'rango_desde': rangoDesde,
      'rango_hasta': rangoHasta,
      'fecha_limite_emision': fechaLimiteEmision?.toIso8601String(),
    }, exito: 'Datos del negocio guardados correctamente');
  }

  Future<void> actualizarTema(Map<String, dynamic> tema) {
    return _guardar({'tema': tema});
  }

  Future<void> establecerTipoDocumentoDefecto(String tipo) {
    return _guardar({'tipo_documento_defecto': tipo});
  }

  Future<void> guardarLogo(Uint8List bytes) {
    return _guardar({
      'logo_color_base64': base64Encode(bytes),
      'logo_bn_base64': '',
    }, exito: 'Logo guardado correctamente');
  }

  Future<void> quitarLogo() {
    return _guardar({'logo_color_base64': '', 'logo_bn_base64': ''}, exito: 'Logo quitado');
  }

  Future<void> establecerLogoEnTicket(bool valor) {
    return _guardar({'logo_en_ticket': valor});
  }

  Future<void> establecerLogoEnPdf(bool valor) {
    return _guardar({'logo_en_pdf': valor});
  }

  Future<void> guardarLogoColor(Uint8List bytes) {
    return _guardar({'logo_color_base64': base64Encode(bytes)}, exito: 'Logo guardado correctamente');
  }

  Future<void> guardarLogoBn(Uint8List bytes) {
    return _guardar({'logo_bn_base64': base64Encode(bytes)}, exito: 'Logo guardado correctamente');
  }

  Future<void> actualizarPermisos(Map<String, bool> permisos) {
    return _guardar({'permisos': permisos}, exito: 'Permisos guardados correctamente');
  }

  Future<void> establecerClave(String clave) {
    return conRedExito('Clave especial guardada correctamente', () async {
      await _db.rpc('establecer_clave_especial', params: {'p_hash': hashClave(clave)});
      _invalidarCache();
      await _tabla.sincronizar();
    });
  }

  Future<void> quitarClave() {
    return conRed(() async {
      await _db.rpc('establecer_clave_especial', params: {'p_hash': ''});
      _invalidarCache();
      await _tabla.sincronizar();
    });
  }

  Future<void> actualizarImpresoraTermica(String url, String nombre) async {
    ImpresoraLocal.termica(url, nombre);
    _cambiosLocales.add(null);
  }

  Future<void> actualizarImpresoraEtiquetas(String url, String nombre) async {
    ImpresoraLocal.etiquetas(url, nombre);
    _cambiosLocales.add(null);
  }

  Future<void> establecerReciboAbonoImprimirCopia(bool valor) {
    return _guardar({'recibo_abono_imprimir_copia': valor});
  }

  Future<void> establecerFacturaImprimirCopia(bool valor) {
    return _guardar({'factura_imprimir_copia': valor});
  }

  Future<void> establecerFacturaPreciosConIsv(bool valor) {
    return _guardar({'factura_precios_con_isv': valor});
  }

  Future<void> establecerModoImpresion(String modo) {
    return _guardar({'modo_impresion': modo});
  }

  Future<void> establecerImprimirFacturas(bool valor) {
    return _guardar({'imprimir_facturas': valor});
  }

  Future<void> actualizarImpresoraRed(String ip, int puerto) async {
    ImpresoraLocal.red(ip, puerto);
    _cambiosLocales.add(null);
  }

  Future<void> actualizarImpresoraBluetooth(String id, String nombre) async {
    ImpresoraLocal.bluetooth(id, nombre);
    _cambiosLocales.add(null);
  }

  Future<void> establecerAnchoTicketMm(int mm) {
    return _guardar({'ancho_ticket_mm': mm});
  }

  Future<void> establecerImpresoraUsbUsarDriverWindows(bool valor) async {
    ImpresoraLocal.driverWindows(valor);
    _cambiosLocales.add(null);
  }

  Future<void> establecerPcPrincipalHostname(String hostname) {
    return _guardar({'pc_principal_hostname': hostname});
  }
}
