class CompatibilidadModel {
  final String marca;
  final String modelo;
  final int? anioDesde;
  final int? anioHasta;

  const CompatibilidadModel({
    required this.marca,
    required this.modelo,
    this.anioDesde,
    this.anioHasta,
  });

  factory CompatibilidadModel.fromMap(Map<String, dynamic> m) {
    return CompatibilidadModel(
      marca: (m['marca'] ?? '') as String,
      modelo: (m['modelo'] ?? '') as String,
      anioDesde: (m['desde'] as num?)?.toInt(),
      anioHasta: (m['hasta'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'marca': marca,
        'modelo': modelo,
        if (anioDesde != null) 'desde': anioDesde,
        if (anioHasta != null) 'hasta': anioHasta,
      };

  CompatibilidadModel copyWith({String? marca, String? modelo, int? anioDesde, int? anioHasta, bool limpiarDesde = false, bool limpiarHasta = false}) {
    return CompatibilidadModel(
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anioDesde: limpiarDesde ? null : (anioDesde ?? this.anioDesde),
      anioHasta: limpiarHasta ? null : (anioHasta ?? this.anioHasta),
    );
  }

  bool cubreAnio(int anio) {
    if (anioDesde != null && anio < anioDesde!) return false;
    if (anioHasta != null && anio > anioHasta!) return false;
    return true;
  }

  String get textoAnios {
    final d = anioDesde;
    final h = anioHasta;
    if (d == null && h == null) return '';
    String dos(int a) => (a % 100).toString().padLeft(2, '0');
    if (d != null && h != null) return d == h ? dos(d) : '${dos(d)}-${dos(h)}';
    if (d != null) return '${dos(d)}-UP';
    return '-${dos(h!)}';
  }

  String get textoCorto {
    final anios = textoAnios;
    return anios.isEmpty ? modelo : '$modelo $anios';
  }

  String get textoCompleto => '$marca $textoCorto'.trim();

  @override
  bool operator ==(Object other) =>
      other is CompatibilidadModel &&
      other.marca == marca &&
      other.modelo == modelo &&
      other.anioDesde == anioDesde &&
      other.anioHasta == anioHasta;

  @override
  int get hashCode => Object.hash(marca, modelo, anioDesde, anioHasta);
}

String generarNombreProducto(String base, List<CompatibilidadModel> lista, {int maximoVisibles = 3}) {
  final limpio = base.trim().toUpperCase();
  if (lista.isEmpty) return limpio;
  final visibles = lista.take(maximoVisibles).toList();
  final partes = <String>[];
  String? marcaAnterior;
  for (final c in visibles) {
    final marca = c.marca.trim().toUpperCase();
    final modelo = c.copyWith(modelo: c.modelo.trim().toUpperCase()).textoCorto;
    if (marca == marcaAnterior || marca.isEmpty) {
      partes.add(modelo);
    } else {
      partes.add('$marca $modelo');
    }
    marcaAnterior = marca;
  }
  final resto = lista.length - visibles.length;
  final sufijo = resto > 0 ? ' +$resto' : '';
  return '$limpio ${partes.join(', ')}$sufijo'.trim();
}

class FiltroVehiculo {
  final String marca;
  final String modelo;
  final int? anio;

  const FiltroVehiculo({this.marca = '', this.modelo = '', this.anio});

  bool get vacio => marca.trim().isEmpty && modelo.trim().isEmpty && anio == null;

  bool aplica(List<CompatibilidadModel> compatibilidad, String Function(String) normalizar) {
    if (vacio) return true;
    final m = normalizar(marca);
    final mo = normalizar(modelo);
    for (final c in compatibilidad) {
      if (m.isNotEmpty && !normalizar(c.marca).contains(m)) continue;
      if (mo.isNotEmpty && !normalizar(c.modelo).contains(mo)) continue;
      if (anio != null && !c.cubreAnio(anio!)) continue;
      return true;
    }
    return false;
  }
}
