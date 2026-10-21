import '../../../core/utils/logo_bn.dart';
import '../../../core/utils/avisos.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/data/tabla_sincronizada.dart';
import '../../../core/utils/reintentos.dart';
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

  Stream<NegocioModel> obtenerNegocio() {
    return _tabla.observar().map((lista) => lista.isEmpty ? const NegocioModel() : lista.first);
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
      return cache;
    }
    final local = _tabla.actual;
    if (local.isNotEmpty && _tabla.sincronizadoAlgunaVez) return local.first;
    try {
      final filas = await _db.from('negocio_config').select().limit(1).timeout(const Duration(seconds: 8));
      final negocio = NegocioModel.fromMap(filas.isEmpty ? null : filas.first);
      _cache = negocio;
      _cacheFecha = DateTime.now();
      return negocio;
    } catch (_) {
      return cache ?? const NegocioModel();
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
      return negocio;
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

  Future<void> guardarLogo(Uint8List bytes) async {
    final bn = await convertirLogoABlancoYNegro(bytes);
    return _guardar({
      'logo_color_base64': base64Encode(bytes),
      'logo_bn_base64': bn == null ? base64Encode(bytes) : base64Encode(bn),
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

  Future<void> actualizarImpresoraTermica(String url, String nombre) {
    return _guardar({'impresora_termica_url': url, 'impresora_termica_nombre': nombre});
  }

  Future<void> actualizarImpresoraEtiquetas(String url, String nombre) {
    return _guardar({'impresora_etiquetas_url': url, 'impresora_etiquetas_nombre': nombre});
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

  Future<void> actualizarImpresoraRed(String ip, int puerto) {
    return _guardar({'impresora_red_ip': ip, 'impresora_red_puerto': puerto});
  }

  Future<void> actualizarImpresoraBluetooth(String id, String nombre) {
    return _guardar({'impresora_bluetooth_id': id, 'impresora_bluetooth_nombre': nombre});
  }

  Future<void> establecerAnchoTicketMm(int mm) {
    return _guardar({'ancho_ticket_mm': mm});
  }

  Future<void> establecerImpresoraUsbUsarDriverWindows(bool valor) {
    return _guardar({'impresora_usb_usar_driver_windows': valor});
  }

  Future<void> establecerPcPrincipalHostname(String hostname) {
    return _guardar({'pc_principal_hostname': hostname});
  }
}
