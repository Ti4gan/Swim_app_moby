int? parseBirthYear(String raw, {int? nowYear}) {
  final y = int.tryParse(raw.trim());
  if (y == null) return null;
  final now = nowYear ?? DateTime.now().year;
  final minYear = now - 100;
  if (y < minYear || y > now) return null;
  return y;
}

String? birthYearError(String raw, {int? nowYear}) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final y = int.tryParse(t);
  if (y == null) return 'Укажите год числом';
  final now = nowYear ?? DateTime.now().year;
  if (y > now) return 'Год не может быть в будущем';
  if (y < now - 100) return 'Укажите реалистичный год рождения';
  return null;
}

String normalizeBelarusPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('375') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('80') && digits.length == 11) {
    return '+375${digits.substring(2)}';
  }
  if (digits.length == 9) {
    return '+375$digits';
  }
  return raw.trim();
}

bool isValidBelarusPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^375(25|29|33|44)\d{7}$').hasMatch(d)) return true;
  if (RegExp(r'^80(25|29|33|44)\d{7}$').hasMatch(d)) return true;
  if (RegExp(r'^(25|29|33|44)\d{7}$').hasMatch(d)) return true;
  return false;
}

String? belarusPhoneError(String raw) {
  if (raw.trim().isEmpty) return null;
  if (isValidBelarusPhone(raw)) return null;
  return 'Формат: +375 29 123 45 67';
}
