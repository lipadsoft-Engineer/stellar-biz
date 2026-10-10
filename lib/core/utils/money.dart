int? parseMoneyToMinorUnits(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d+(?:\.\d{0,2})?$').hasMatch(value)) return null;

  final parts = value.split('.');
  final major = int.tryParse(parts.first);
  final minor = int.tryParse(
    parts.length == 1 ? '0' : parts[1].padRight(2, '0'),
  );
  if (major == null || minor == null) return null;
  return major * 100 + minor;
}

String formatMoneyInput(int minorUnits) {
  final major = minorUnits ~/ 100;
  final minor = minorUnits % 100;
  return '$major.${minor.toString().padLeft(2, '0')}';
}

String formatKes(int minorUnits) {
  final major = (minorUnits ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final minor = minorUnits % 100;
  return minor == 0
      ? 'KES $major'
      : 'KES $major.${minor.toString().padLeft(2, '0')}';
}
