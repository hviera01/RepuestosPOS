import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../../features/compras_credito/data/abono_compra_model.dart';
import '../../features/compras_credito/data/compra_credito_model.dart';
import '../../features/negocio/data/negocio_model.dart';
import '../../features/ventas_credito/data/abono_model.dart';
import '../../features/ventas_credito/data/venta_credito_model.dart';
import '../utils/formato_moneda.dart';
import '../widgets/pdf_preview_dialog.dart';
import 'ticket_generico.dart';

class RecibosTickets {
  static final _formatoFecha = DateFormat('dd/MM/yyyy hh:mm a');

  static List<LineaTicket> _comun({
    required NegocioModel negocio,
    required String titulo,
    required String marca,
    required DateTime? fecha,
    required List<LTexto> datos,
    required AbonoLineas abono,
    required String firma,
  }) {
    return [
      ...TicketGenerico.encabezado(negocio),
      const LEspacio(),
      const LSeparador(),
      LTexto(titulo, alineacion: AlineacionTicket.centro, negrita: true),
      LTexto(marca, alineacion: AlineacionTicket.centro, negrita: true),
      const LSeparador(),
      LTexto('Fecha: ${fecha == null ? '-' : _formatoFecha.format(fecha)}'),
      ...datos,
      const LSeparador(),
      LPar('Saldo anterior', formatearMoneda(abono.saldoAnterior)),
      LPar('Monto abonado', formatearMoneda(abono.montoAbonado), negrita: true),
      if (abono.interes > 0) LPar('Interes', formatearMoneda(abono.interes)),
      const LSeparador(),
      LPar('Saldo pendiente', formatearMoneda(abono.saldoPendiente), negrita: true),
      const LEspacio(),
      LTexto('Metodo de pago: ${abono.metodoPago}'),
      if (abono.numeroRecibo.isNotEmpty) LTexto('No. Recibo: ${abono.numeroRecibo}'),
      if (abono.usuario.isNotEmpty) LTexto('Atendido por: ${abono.usuario}'),
      LFirma(firma),
      const LEspacio(),
    ];
  }

  static List<List<LineaTicket>> ventaCopias(VentaCreditoModel credito, AbonoModel abono, NegocioModel negocio) {
    List<LineaTicket> una(String marca) => _comun(
          negocio: negocio,
          titulo: 'RECIBO DE ABONO',
          marca: marca,
          fecha: abono.fecha,
          datos: [
            LTexto('No. Factura: ${credito.numeroDocumento}'),
            LTexto('Cliente: ${credito.nombreCliente}'),
          ],
          abono: AbonoLineas(abono.saldoAnterior, abono.montoAbonado, abono.interes, abono.saldoPendiente, abono.metodoPago, abono.numeroRecibo, abono.usuario),
          firma: 'Firma del cliente',
        );
    return [una('ORIGINAL'), if (negocio.reciboAbonoImprimirCopia) una('COPIA')];
  }

  static List<List<LineaTicket>> compraCopias(CompraCreditoModel compra, AbonoCompraModel abono, NegocioModel negocio) {
    List<LineaTicket> una(String marca) => _comun(
          negocio: negocio,
          titulo: 'RECIBO DE PAGO A PROVEEDOR',
          marca: marca,
          fecha: abono.fecha,
          datos: [
            LTexto('No. Factura: ${compra.noFactura}'),
            LTexto('Proveedor: ${compra.nombreProveedor}'),
          ],
          abono: AbonoLineas(abono.saldoAnterior, abono.montoAbonado, abono.interes, abono.saldoPendiente, abono.metodoPago, abono.numeroRecibo, abono.usuario),
          firma: 'Firma de quien recibe',
        );
    return [una('ORIGINAL'), if (negocio.reciboAbonoImprimirCopia) una('COPIA')];
  }

  static PdfPreviewDialog dialogo({
    required String titulo,
    required String archivo,
    required Future<Uint8List> Function() pdf,
    required List<List<LineaTicket>> copias,
    required NegocioModel negocio,
    Printer? impresora,
  }) {
    return PdfPreviewDialog(
      titulo: titulo,
      nombreArchivo: archivo,
      generarPdf: pdf,
      impresora: impresora,
      generarTicketEscPos: () => TicketGenerico.bytes(copias, negocio),
      nombreImpresoraWindows: negocio.impresoraUsbUsarDriverWindows ? null : negocio.impresoraTermicaNombre,
      vistaPreviaTicket: () => SingleChildScrollView(
        child: Column(
          children: [
            for (final c in copias) ...[
              TicketGenerico.vistaPrevia(c, negocio),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class AbonoLineas {
  final double saldoAnterior;
  final double montoAbonado;
  final double interes;
  final double saldoPendiente;
  final String metodoPago;
  final String numeroRecibo;
  final String usuario;

  const AbonoLineas(this.saldoAnterior, this.montoAbonado, this.interes, this.saldoPendiente, this.metodoPago, this.numeroRecibo, this.usuario);
}
