import 'package:flutter/services.dart';

class TrainingInputLimits {
  static const maxReps = 500;
  static const maxMetersPerRep = 15000;
  static const maxWorkoutMinutes = 360;
  static const maxTotalMetersPerWorkout = 15000;
}

class PositiveIntTextInputFormatter extends TextInputFormatter {
  PositiveIntTextInputFormatter({this.maxValue, this.allowEmpty = true});

  final int? maxValue;
  final bool allowEmpty;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (t.isEmpty) {
      return allowEmpty ? newValue : oldValue;
    }
    if (t.contains('-') || t.contains('+') || t.contains('.') || t.contains(',')) {
      return oldValue;
    }
    final n = int.tryParse(t);
    if (n == null) return oldValue;
    if (n < 0) return oldValue;
    if (maxValue != null && n > maxValue!) {
      final capped = '$maxValue';
      return TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
    }
    return newValue;
  }
}

int clampTrainingReps(int value) => value.clamp(1, TrainingInputLimits.maxReps);

int clampTrainingMetersPerRep(int value) => value.clamp(1, TrainingInputLimits.maxMetersPerRep);

int clampTrainingWorkoutMinutes(int value) =>
    value.clamp(0, TrainingInputLimits.maxWorkoutMinutes);

int parseTrainingReps(String raw) {
  final v = int.tryParse(raw.trim()) ?? 0;
  return clampTrainingReps(v);
}

int parseTrainingMetersPerRep(String raw) {
  final v = int.tryParse(raw.trim()) ?? 0;
  return clampTrainingMetersPerRep(v);
}

class CompetitionTimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) return oldValue;

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buf.write(':');
      if (i == 4) buf.write('.');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class DecimalCommaInputFormatter extends TextInputFormatter {
  DecimalCommaInputFormatter({this.maxDecimalPlaces = 2});

  final int maxDecimalPlaces;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var t = newValue.text.replaceAll(' ', '');
    if (t.isEmpty) return newValue;
    t = t.replaceAll('.', ',');
    if (!RegExp(r'^\d*,?\d*$').hasMatch(t)) return oldValue;
    final parts = t.split(',');
    if (parts.length > 2) return oldValue;
    if (parts.length == 2 && parts[1].length > maxDecimalPlaces) return oldValue;
    return TextEditingValue(
      text: t,
      selection: newValue.selection,
    );
  }
}
