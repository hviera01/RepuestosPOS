String invertirCodigoBarras(String codigo) => codigo.trim().split('').reversed.join();

List<String> variantesCodigoBarras(String codigo) {
  final variantes = <String>[];
  if (codigo.length == 13 && codigo.startsWith('0')) {
    variantes.add(codigo.substring(1));
  } else if (codigo.length == 12) {
    variantes.add('0$codigo');
  }
  final invertido = invertirCodigoBarras(codigo);
  if (invertido != codigo) variantes.add(invertido);
  return variantes;
}
