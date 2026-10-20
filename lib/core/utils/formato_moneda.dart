import 'package:intl/intl.dart';

String formatearMoneda(double valor) {
  final formato = NumberFormat('#,##0.00', 'en_US');
  return 'L.${formato.format(redondearMoneda(valor))}';
}

double redondearMoneda(double valor) {
  return double.parse(valor.toStringAsFixed(2));
}