import '../../../../core/theme/marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/producto_model.dart';
import '../../data/lote_costo_model.dart';
import '../../providers/productos_provider.dart';
import '../../../../core/utils/formato_moneda.dart';
import '../../../compras/presentation/screens/detalle_compra_screen.dart';

class LotesProductoVista extends ConsumerStatefulWidget {
  final ProductoModel producto;
  final DateTime? desde;
  final DateTime? hasta;

  const LotesProductoVista({super.key, required this.producto, this.desde, this.hasta});

  @override
  ConsumerState<LotesProductoVista> createState() => _LotesProductoVistaState();
}

class _LotesProductoVistaState extends ConsumerState<LotesProductoVista> {
  final _formatoDia = DateFormat('dd/MM/yyyy');

  String _formatoCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) return cantidad.toInt().toString();
    return cantidad.toStringAsFixed(2);
  }

  void _verDetalleLote(LoteCostoModel lote) {
    if (lote.origen != 'compra' || lote.idCompra == null || lote.idCompra!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este lote no tiene una compra asociada (viene de un ajuste manual o un traslado anulado)')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => DetalleCompraScreen(compraIdInicial: lote.idCompra)),
    );
  }

  Future<void> _moverLote(List<LoteCostoModel> activos, int indice, int delta) async {
    final nuevoIndice = indice + delta;
    if (nuevoIndice < 0 || nuevoIndice >= activos.length) return;
    final reordenados = List<LoteCostoModel>.from(activos);
    final tmp = reordenados[indice];
    reordenados[indice] = reordenados[nuevoIndice];
    reordenados[nuevoIndice] = tmp;
    try {
      await ref.read(loteCostoRepositoryProvider).reordenarLotes(widget.producto.id, reordenados.map((l) => l.id).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo reordenar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(lotesProductoProvider(widget.producto.id));
    return async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Center(child: CircularProgressIndicator(color: Marca.primario)),
      error: (e, st) => Center(child: Text('Error: $e', style: GoogleFonts.poppins(color: Colors.red))),
      data: (data) {
        final desde = widget.desde;
        final hasta = widget.hasta;
        final lotes = data.where((l) {
          if (desde != null && l.fecha.isBefore(DateTime(desde.year, desde.month, desde.day))) return false;
          if (hasta != null && l.fecha.isAfter(DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59))) return false;
          return true;
        }).toList();
        if (lotes.isEmpty) {
          return Center(child: Text('Sin lotes de costo registrados para este producto', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey.shade500)));
        }
        final totalRestante = lotes.fold<double>(0, (s, l) => s + l.cantidadRestante);
        final idPrimerLoteVigente = lotes.firstWhere((l) => l.cantidadRestante > 0, orElse: () => lotes.first).id;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Existencia total: ${_formatoCantidad(totalRestante)} unidades repartidas en ${lotes.where((l) => l.cantidadRestante > 0).length} lote(s). Se vende primero el que está arriba; use las flechas para cambiar el orden.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            Expanded(child: _tablaLotes(lotes, idPrimerLoteVigente)),
          ],
        );
      },
    );
  }

  Widget _tablaLotes(List<LoteCostoModel> lotes, String idPrimerLoteVigente) {
    final estiloHeader = GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade600);
    final activos = lotes.where((l) => l.cantidadRestante > 0).toList();
    const anchoTabla = 750.0;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB6BCC7)), borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: anchoTabla,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFFECEEF3), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(
                  children: [
                    SizedBox(width: 110, child: Text('FECHA', style: estiloHeader)),
                    SizedBox(width: 90, child: Text('ORIGEN', style: estiloHeader)),
                    SizedBox(width: 110, child: Text('CANT. ORIGINAL', textAlign: TextAlign.right, style: estiloHeader)),
                    SizedBox(width: 110, child: Text('CANT. RESTANTE', textAlign: TextAlign.right, style: estiloHeader)),
                    SizedBox(width: 100, child: Text('COSTO UNIT.', textAlign: TextAlign.right, style: estiloHeader)),
                    SizedBox(width: 70, child: Text('ORDEN', textAlign: TextAlign.center, style: estiloHeader)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: lotes.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final l = lotes[index];
                    final agotado = l.cantidadRestante <= 0;
                    final esProximo = l.id == idPrimerLoteVigente && !agotado;
                    final indiceActivo = agotado ? -1 : activos.indexWhere((a) => a.id == l.id);
                    final gris = agotado ? Colors.grey.shade400 : null;
                    return InkWell(
                      onTap: () => _verDetalleLote(l),
                      child: Container(
                        color: esProximo ? Marca.primarioSuave : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 110, child: Text(_formatoDia.format(l.fecha), style: GoogleFonts.poppins(fontSize: 12, color: gris))),
                            SizedBox(width: 90, child: Text(l.origen == 'compra' ? 'Compra' : 'Ajuste', style: GoogleFonts.poppins(fontSize: 12, color: gris))),
                            SizedBox(width: 110, child: Text(_formatoCantidad(l.cantidadOriginal), textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 12, color: gris))),
                            SizedBox(
                              width: 110,
                              child: Text(
                                _formatoCantidad(l.cantidadRestante),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: agotado ? Colors.grey.shade400 : const Color(0xFF1A1A1A)),
                              ),
                            ),
                            SizedBox(width: 100, child: Text(formatearMoneda(l.costoUnitario), textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: gris))),
                            SizedBox(
                              width: 70,
                              child: indiceActivo < 0
                                  ? null
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          tooltip: 'Que salga antes',
                                          icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          color: indiceActivo == 0 ? Colors.grey.shade300 : Marca.primario,
                                          onPressed: indiceActivo == 0 ? null : () => _moverLote(activos, indiceActivo, -1),
                                        ),
                                        IconButton(
                                          tooltip: 'Que salga después',
                                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          color: indiceActivo == activos.length - 1 ? Colors.grey.shade300 : Marca.primario,
                                          onPressed: indiceActivo == activos.length - 1 ? null : () => _moverLote(activos, indiceActivo, 1),
                                        ),
                                      ],
                                    ),
                            ),
                            Expanded(
                              child: esProximo
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text('Se vende primero', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: Marca.primario)),
                                    )
                                  : (agotado ? Padding(padding: const EdgeInsets.only(left: 8), child: Text('Agotado', style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade400))) : const SizedBox()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
