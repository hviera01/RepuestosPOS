import '../theme/marca.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cliente_fotos_web.dart' if (dart.library.io) 'cliente_fotos_io.dart';

class ImagenProductoNetwork extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? loadingColor;
  final Color iconColor;
  final Color textColor;
  final double iconSize;
  final double textSize;

  const ImagenProductoNetwork({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingColor,
    this.iconColor = const Color(0xFF9CA3AF),
    this.textColor = const Color(0xFF9CA3AF),
    this.iconSize = 20,
    this.textSize = 9,
  });

  static final http.Client _client = crearClienteFotos();

  static void precalentar() {
    _client
        .get(Uri.parse('https://res.cloudinary.com/'))
        .timeout(const Duration(seconds: 20))
        .catchError((_) => http.Response('', 0));
  }

  static final Map<String, Uint8List> _cache = {};

  @override
  State<ImagenProductoNetwork> createState() => _ImagenProductoNetworkState();
}

class _ImagenProductoNetworkState extends State<ImagenProductoNetwork> {
  late Future<Uint8List> _future;
  late String _urlEfectiva;
  Timer? _reintentoAutomatico;
  int _intentosAutomaticos = 0;
  String? _ultimoError;

  @override
  void initState() {
    super.initState();
    _urlEfectiva = _calcularUrlEfectiva();
    _future = _obtenerFuture();
  }

  @override
  void didUpdateWidget(covariant ImagenProductoNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nuevaUrl = _calcularUrlEfectiva();
    if (nuevaUrl != _urlEfectiva) {
      _urlEfectiva = nuevaUrl;
      setState(() => _future = _obtenerFuture());
    }
  }

  String _calcularUrlEfectiva() {
    final ancho = widget.width;
    if (ancho == null) return widget.url;
    const marcador = '/upload/';
    final idx = widget.url.indexOf(marcador);
    if (idx == -1 || !widget.url.contains('res.cloudinary.com')) {
      return widget.url;
    }
    final anchoPixeles = (ancho * 2).clamp(50, 800).round();
    final inicio = idx + marcador.length;
    return '${widget.url.substring(0, inicio)}'
        'w_$anchoPixeles,c_limit,q_auto,f_auto/'
        '${widget.url.substring(inicio)}';
  }

  Future<Uint8List> _obtenerFuture() {
    final cacheado = ImagenProductoNetwork._cache[_urlEfectiva];
    if (cacheado != null) return Future.value(cacheado);
    return _cargarConReintentoDeFondo();
  }

  @override
  void dispose() {
    _reintentoAutomatico?.cancel();
    super.dispose();
  }

  Future<Uint8List> _cargar() async {
    const intentos = 4;
    for (var intento = 1; intento <= intentos; intento++) {
      try {
        final res = await ImagenProductoNetwork._client
            .get(Uri.parse(_urlEfectiva))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
        ImagenProductoNetwork._cache[_urlEfectiva] = res.bodyBytes;
        return res.bodyBytes;
      } catch (e) {
        _ultimoError = _describirError(e);
        if (intento == intentos) rethrow;
        await Future.delayed(Duration(seconds: intento * 2));
      }
    }
    throw Exception('No se pudo cargar la imagen');
  }

  String _describirError(Object e) {
    final tipo = e.runtimeType.toString();
    final detalle = e
        .toString()
        .replaceFirst('$tipo: ', '')
        .replaceFirst('Exception: ', '');
    return detalle.length > 140
        ? '$tipo: ${detalle.substring(0, 140)}…'
        : '$tipo: $detalle';
  }

  Future<Uint8List> _cargarConReintentoDeFondo() {
    final future = _cargar();
    future.then(
      (_) {},
      onError: (_) {
        if (!mounted || _intentosAutomaticos >= 15) return;
        _intentosAutomaticos++;
        _reintentoAutomatico = Timer(const Duration(seconds: 8), () {
          if (mounted) setState(() => _future = _cargarConReintentoDeFondo());
        });
      },
    );
    return future;
  }

  void _reintentar() {
    _reintentoAutomatico?.cancel();
    _intentosAutomaticos = 0;
    setState(() => _future = _cargarConReintentoDeFondo());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: widget.loadingColor ?? Marca.primario,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final mostrarDetalle = (widget.width ?? 200) >= 60;
          return Tooltip(
            message: _ultimoError ?? snapshot.error.toString(),
            child: InkWell(
              onTap: _reintentar,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: widget.iconColor,
                      size: widget.iconSize,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reintentar',
                      style: TextStyle(
                        fontSize: widget.textSize,
                        color: widget.textColor,
                      ),
                    ),
                    if (mostrarDetalle && _ultimoError != null) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          _ultimoError!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (widget.textSize - 1).clamp(7, 20),
                            color: widget.textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}
