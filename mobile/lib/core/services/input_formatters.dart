import 'package:flutter/services.dart';

class NumericInputFormatter extends TextInputFormatter {
  final int maxDecimalDigits;

  NumericInputFormatter({this.maxDecimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final dotCount = text.split('.').length - 1;
    if (dotCount > 1) return oldValue;

    final parts = text.split('.');
    if (parts.length == 2 && parts[1].length > maxDecimalDigits) return oldValue;

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    return newValue;
  }
}
