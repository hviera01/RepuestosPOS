double _n(dynamic v) => v == null ? 0 : (v as num).toDouble();
int _i(dynamic v) => v == null ? 0 : (v as num).toInt();
Map<String, dynamic> _m(dynamic v) => v == null ? <String, dynamic>{} : Map<String, dynamic>.from(v as Map);
List<Map<String, dynamic>> _l(dynamic v) => v == null ? <Map<String, dynamic>>[] : (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

class LineaTotal {
  final String etiqueta;
  final int cantidad;
  final double total;

  const LineaTotal(this.etiqueta, this.cantidad, this.total);
}

class OperacionDia {
  final DateTime fecha;
  final String tipo;
  final String descripcion;
  final String usuario;
  final double monto;

  const OperacionDia({required this.fecha, required this.tipo, required this.descripcion, required this.usuario, required this.monto});

  factory OperacionDia.fromMap(Map<String, dynamic> m) => OperacionDia(
        fecha: DateTime.parse(m['fecha'] as String),
        tipo: m['tipo'] ?? '',
        descripcion: m['descripcion'] ?? '',
        usuario: m['usuario'] ?? '',
        monto: _n(m['monto']),
      );
}

class ResumenOperaciones {
  final DateTime desde;
  final DateTime hasta;
  final int cantidadVentas;
  final double totalVentas;
  final double subtotalVentas;
  final double impuesto;
  final double unidades;
  final double ticketPromedio;
  final double mayorVenta;
  final double costo;
  final double utilidadBruta;
  final List<LineaTotal> porTipo;
  final double efectivo;
  final double tarjeta;
  final double transferencia;
  final double cheque;
  final double credito;
  final int anuladasCantidad;
  final double anuladasTotal;
  final int cotizacionesCantidad;
  final double cotizacionesTotal;
  final int abonosClientesCantidad;
  final double abonosClientesTotal;
  final double abonosClientesEfectivo;
  final int comprasCantidad;
  final double comprasTotal;
  final double comprasContado;
  final double comprasCredito;
  final int abonosProveedoresCantidad;
  final double abonosProveedoresTotal;
  final double abonosProveedoresEfectivo;
  final int egresosCantidad;
  final double egresosTotal;
  final double egresosEfectivo;
  final List<LineaTotal> egresosPorCategoria;
  final int trasladosCantidad;
  final double trasladosUnidades;
  final double entradasEfectivo;
  final double salidasEfectivo;
  final double netoEfectivo;
  final List<LineaTotal> porUsuario;
  final List<LineaTotal> porHora;
  final List<LineaTotal> topProductos;
  final List<LineaTotal> topClientes;
  final List<OperacionDia> operaciones;

  const ResumenOperaciones({
    required this.desde,
    required this.hasta,
    required this.cantidadVentas,
    required this.totalVentas,
    required this.subtotalVentas,
    required this.impuesto,
    required this.unidades,
    required this.ticketPromedio,
    required this.mayorVenta,
    required this.costo,
    required this.utilidadBruta,
    required this.porTipo,
    required this.efectivo,
    required this.tarjeta,
    required this.transferencia,
    required this.cheque,
    required this.credito,
    required this.anuladasCantidad,
    required this.anuladasTotal,
    required this.cotizacionesCantidad,
    required this.cotizacionesTotal,
    required this.abonosClientesCantidad,
    required this.abonosClientesTotal,
    required this.abonosClientesEfectivo,
    required this.comprasCantidad,
    required this.comprasTotal,
    required this.comprasContado,
    required this.comprasCredito,
    required this.abonosProveedoresCantidad,
    required this.abonosProveedoresTotal,
    required this.abonosProveedoresEfectivo,
    required this.egresosCantidad,
    required this.egresosTotal,
    required this.egresosEfectivo,
    required this.egresosPorCategoria,
    required this.trasladosCantidad,
    required this.trasladosUnidades,
    required this.entradasEfectivo,
    required this.salidasEfectivo,
    required this.netoEfectivo,
    required this.porUsuario,
    required this.porHora,
    required this.topProductos,
    required this.topClientes,
    required this.operaciones,
  });

  factory ResumenOperaciones.fromMap(Map<String, dynamic> r) {
    final v = _m(r['ventas']);
    final met = _m(r['porMetodo']);
    final an = _m(r['anuladas']);
    final co = _m(r['cotizaciones']);
    final ac = _m(r['abonosClientes']);
    final cm = _m(r['compras']);
    final ap = _m(r['abonosProveedores']);
    final eg = _m(r['egresos']);
    final tr = _m(r['traslados']);
    final fl = _m(r['flujoEfectivo']);
    return ResumenOperaciones(
      desde: DateTime.parse(r['desde'] as String),
      hasta: DateTime.parse(r['hasta'] as String),
      cantidadVentas: _i(v['cantidad']),
      totalVentas: _n(v['total']),
      subtotalVentas: _n(v['subtotal']),
      impuesto: _n(v['impuesto']),
      unidades: _n(v['unidades']),
      ticketPromedio: _n(v['ticketPromedio']),
      mayorVenta: _n(v['mayorVenta']),
      costo: _n(v['costo']),
      utilidadBruta: _n(v['utilidadBruta']),
      porTipo: _l(r['porTipo']).map((e) => LineaTotal(e['tipo'] ?? '', _i(e['cantidad']), _n(e['total']))).toList(),
      efectivo: _n(met['efectivo']),
      tarjeta: _n(met['tarjeta']),
      transferencia: _n(met['transferencia']),
      cheque: _n(met['cheque']),
      credito: _n(met['credito']),
      anuladasCantidad: _i(an['cantidad']),
      anuladasTotal: _n(an['total']),
      cotizacionesCantidad: _i(co['cantidad']),
      cotizacionesTotal: _n(co['total']),
      abonosClientesCantidad: _i(ac['cantidad']),
      abonosClientesTotal: _n(ac['total']),
      abonosClientesEfectivo: _n(ac['efectivo']),
      comprasCantidad: _i(cm['cantidad']),
      comprasTotal: _n(cm['total']),
      comprasContado: _n(cm['contado']),
      comprasCredito: _n(cm['credito']),
      abonosProveedoresCantidad: _i(ap['cantidad']),
      abonosProveedoresTotal: _n(ap['total']),
      abonosProveedoresEfectivo: _n(ap['efectivo']),
      egresosCantidad: _i(eg['cantidad']),
      egresosTotal: _n(eg['total']),
      egresosEfectivo: _n(eg['efectivo']),
      egresosPorCategoria: _l(eg['porCategoria']).map((e) => LineaTotal(e['categoria'] ?? '', 0, _n(e['total']))).toList(),
      trasladosCantidad: _i(tr['cantidad']),
      trasladosUnidades: _n(tr['unidades']),
      entradasEfectivo: _n(fl['entradas']),
      salidasEfectivo: _n(fl['salidas']),
      netoEfectivo: _n(fl['neto']),
      porUsuario: _l(r['porUsuario']).map((e) => LineaTotal(e['usuario'] ?? '', _i(e['cantidad']), _n(e['total']))).toList(),
      porHora: _l(r['porHora']).map((e) => LineaTotal('${_i(e['hora']).toString().padLeft(2, '0')}:00', _i(e['cantidad']), _n(e['total']))).toList(),
      topProductos: _l(r['topProductos']).map((e) => LineaTotal(e['nombre'] ?? '', _n(e['cantidad']).round(), _n(e['monto']))).toList(),
      topClientes: _l(r['topClientes']).map((e) => LineaTotal(e['cliente'] ?? '', _i(e['cantidad']), _n(e['total']))).toList(),
      operaciones: _l(r['operaciones']).map(OperacionDia.fromMap).toList(),
    );
  }
}
