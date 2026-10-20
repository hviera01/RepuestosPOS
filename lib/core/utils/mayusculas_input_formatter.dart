import 'package:flutter/services.dart';

class MayusculasInputFormatter extends TextInputFormatter {
  const MayusculasInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == newValue.text.toUpperCase()) return newValue;
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

const mayusculasInputFormatter = MayusculasInputFormatter();
