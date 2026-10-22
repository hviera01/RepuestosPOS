import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import '../../features/negocio/data/negocio_model.dart';
import '../utils/logo_escpos.dart';
import '../utils/texto_utils.dart';

enum AlineacionTicket { izquierda, centro, derecha }

abstract class LineaTicket {
  const LineaTicket();
}

class LTexto extends LineaTicket {
  final String texto;
  final AlineacionTicket alineacion;
  final bool negrita;
  final bool doble;

  const LTexto(this.texto, {this.alineacion = AlineacionTicket.izquierda, this.negrita = false, this.doble = false});
}

class LPar extends LineaTicket {
  final String izquierda;
  final String derecha;
  final bool negrita;

  const LPar(this.izquierda, this.derecha, {this.negrita = false});
}

class LSeparador extends LineaTicket {
  const LSeparador();
}

class LEspacio extends LineaTicket {
  final int lineas;

  const LEspacio([this.lineas = 1]);
}

class LFirma extends LineaTicket {
  final String etiqueta;

  const LFirma(this.etiqueta);
}

class LineaRenderizada {
  final String texto;
  final bool negrita;
  final bool doble;
  final AlineacionTicket alineacion;
  final bool separador;

  const LineaRenderizada(this.texto, {this.negrita = false, this.doble = false, this.alineacion = AlineacionTicket.izquierda, this.separador = false});
}

class TicketGenerico {
  static int columnasPara(NegocioModel negocio) => negocio.anchoTicketMm == 58 ? 32 : 48;

  static List<String> envolver(String texto, int ancho) {
    final palabras = quitarTildes(texto).trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return [''];
    final lineas = <String>[];
    var actual = '';
    for (var palabra in palabras) {
      while (palabra.length > ancho) {
        if (actual.isNotEmpty) {
          lineas.add(actual);
          actual = '';
        }
        lineas.add(palabra.substring(0, ancho));
        palabra = palabra.substring(ancho);
      }
      if (actual.isEmpty) {
        actual = palabra;
      } else if (actual.length + 1 + palabra.length <= ancho) {
        actual = '$actual $palabra';
      } else {
        lineas.add(actual);
        actual = palabra;
      }
    }
    if (actual.isNotEmpty) lineas.add(actual);
    return lineas;
  }

  static List<LineaTicket> encabezado(NegocioModel negocio, {bool fiscal = false}) {
    return [
      if (negocio.nombre.isNotEmpty) LTexto(negocio.nombre.toUpperCase(), alineacion: AlineacionTicket.centro, negrita: true, doble: true),
      if (negocio.eslogan.isNotEmpty) LTexto(negocio.eslogan, alineacion: AlineacionTicket.centro),
      if (negocio.direccion.isNotEmpty) LTexto('Direccion: ${negocio.direccion}', alineacion: AlineacionTicket.centro),
      if (negocio.rtn.isNotEmpty) LTexto('RTN: ${negocio.rtn}', alineacion: AlineacionTicket.centro),
      if (negocio.telefono.isNotEmpty) LTexto('Tel: ${negocio.telefono}', alineacion: AlineacionTicket.centro),
      if (fiscal && negocio.cai.isNotEmpty) LTexto('CAI: ${negocio.cai}', alineacion: AlineacionTicket.centro),
    ];
  }

  static List<LineaRenderizada> renderizar(List<LineaTicket> lineas, int columnas) {
    final salida = <LineaRenderizada>[];
    for (final l in lineas) {
      if (l is LTexto) {
        final ancho = l.doble ? columnas ~/ 2 : columnas;
        for (final parte in envolver(l.texto, ancho)) {
          salida.add(LineaRenderizada(parte, negrita: l.negrita, doble: l.doble, alineacion: l.alineacion));
        }
      } else if (l is LPar) {
        final izq = quitarTildes(l.izquierda).trim();
        final der = quitarTildes(l.derecha).trim();
        if (izq.length + 1 + der.length <= columnas) {
          final relleno = ' ' * (columnas - izq.length - der.length);
          salida.add(LineaRenderizada('$izq$relleno$der', negrita: l.negrita));
        } else {
          final espacioIzq = columnas - der.length - 1;
          final partes = espacioIzq >= 8 ? envolver(izq, espacioIzq) : envolver(izq, columnas);
          for (var i = 0; i < partes.length; i++) {
            final ultima = i == partes.length - 1;
            if (ultima && espacioIzq >= 8) {
              final relleno = ' ' * (columnas - partes[i].length - der.length);
              salida.add(LineaRenderizada('${partes[i]}$relleno$der', negrita: l.negrita));
            } else {
              salida.add(LineaRenderizada(partes[i], negrita: l.negrita));
            }
          }
          if (espacioIzq < 8) {
            salida.add(LineaRenderizada(der.padLeft(columnas), negrita: l.negrita));
          }
        }
      } else if (l is LSeparador) {
        salida.add(const LineaRenderizada('', separador: true));
      } else if (l is LEspacio) {
        for (var i = 0; i < l.lineas; i++) {
          salida.add(const LineaRenderizada(' '));
        }
      } else if (l is LFirma) {
        salida.add(const LineaRenderizada(' '));
        salida.add(const LineaRenderizada(' '));
        salida.add(const LineaRenderizada(' '));
        final raya = '_' * (columnas * 3 ~/ 4);
        salida.add(LineaRenderizada(raya, alineacion: AlineacionTicket.centro));
        salida.add(LineaRenderizada(quitarTildes(l.etiqueta), alineacion: AlineacionTicket.centro));
      }
    }
    return salida;
  }

  static Future<List<int>> bytes(List<List<LineaTicket>> copias, NegocioModel negocio) async {
    final perfil = await CapabilityProfile.load();
    final papel = negocio.anchoTicketMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final g = Generator(papel, perfil);
    final columnas = columnasPara(negocio);
    final logo = negocio.logoEnTicket ? decodificarLogoEscPos(negocio.logoBnBase64, maxDimension: papel == PaperSize.mm58 ? 130 : 180) : null;
    List<int> salida = [];
    salida += g.reset();
    for (final lineas in copias) {
      if (logo != null) {
        salida += g.imageRaster(logo, align: PosAlign.center);
      }
      for (final r in renderizar(lineas, columnas)) {
        if (r.separador) {
          salida += g.hr();
          continue;
        }
        final alinear = switch (r.alineacion) {
          AlineacionTicket.centro => PosAlign.center,
          AlineacionTicket.derecha => PosAlign.right,
          AlineacionTicket.izquierda => PosAlign.left,
        };
        salida += g.text(
          r.texto,
          styles: PosStyles(
            align: alinear,
            bold: r.negrita,
            height: r.doble ? PosTextSize.size2 : PosTextSize.size1,
            width: r.doble ? PosTextSize.size2 : PosTextSize.size1,
          ),
        );
      }
      salida += g.emptyLines(2);
      salida += g.cut();
    }
    return salida;
  }

  static Widget vistaPrevia(List<LineaTicket> lineas, NegocioModel negocio) {
    final columnas = columnasPara(negocio);
    final ancho = negocio.anchoTicketMm == 58 ? 250.0 : 360.0;
    final renders = renderizar(lineas, columnas);
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD0D3DA))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in renders)
            if (r.separador)
              Text('-' * columnas, style: const TextStyle(fontFamily: 'Courier New', fontSize: 12, height: 1.25), maxLines: 1, overflow: TextOverflow.clip)
            else
              Text(
                r.texto,
                textAlign: switch (r.alineacion) {
                  AlineacionTicket.centro => TextAlign.center,
                  AlineacionTicket.derecha => TextAlign.right,
                  AlineacionTicket.izquierda => TextAlign.left,
                },
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: r.doble ? 20 : 12,
                  fontWeight: r.negrita ? FontWeight.w800 : FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
        ],
      ),
    );
  }
}
