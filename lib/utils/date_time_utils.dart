DateTime parseServerDateTime(String input) {
  final normalized = input.trim();
  if (normalized.isEmpty) {
    return DateTime.now();
  }

  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
  final hasT = normalized.contains('T');
  final iso = hasT ? normalized : normalized.replaceFirst(' ', 'T');
  final parseTarget = hasTimezone ? iso : '${iso}Z';
  return DateTime.parse(parseTarget).toLocal();
}
