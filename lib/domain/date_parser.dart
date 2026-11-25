// Turns raw OCR text from a label into an expiry date.
// Assumes day-first dates (25/11/2026) and 2-digit years in the 2000s.

const _months = {
  'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
  'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
};

class ParsedDate {
  const ParsedDate(this.date, this.confidence);
  final DateTime date;

  /// 0 to 1. Below about 0.8, ask the user to confirm the date.
  final double confidence;
}

DateTime? _build(int y, int m, int d) {
  if (y < 100) y += 2000;
  if (m < 1 || m > 12) return null;
  final day = d == 0 ? DateTime(y, m + 1, 0).day : d; // 0 = month only
  final dt = DateTime(y, m, day);
  return (dt.year == y && dt.month == m && dt.day == day) ? dt : null;
}

ParsedDate? _parseLine(String line) {
  final t = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9/.\- ]'), ' ');

  // dd/mm/yyyy, dd-mm-yy, dd.mm.yyyy
  for (final m in RegExp(r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})\b')
      .allMatches(t)) {
    final d = _build(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    if (d != null) return ParsedDate(d, 0.9);
  }
  // dd MON yyyy
  for (final m in RegExp(
          r'\b(\d{1,2})[ \-/.]?([A-Z]{3})[A-Z]*[ \-/.]?(\d{4}|\d{2})\b')
      .allMatches(t)) {
    final mo = _months[m[2]!];
    if (mo == null) continue;
    final d = _build(int.parse(m[3]!), mo, int.parse(m[1]!));
    if (d != null) return ParsedDate(d, 0.85);
  }
  // MON yyyy (month only: use last day of the month)
  for (final m
      in RegExp(r'\b([A-Z]{3})[A-Z]*[ \-/.]?(\d{4}|\d{2})\b').allMatches(t)) {
    final mo = _months[m[1]!];
    if (mo == null) continue;
    final d = _build(int.parse(m[2]!), mo, 0);
    if (d != null) return ParsedDate(d, 0.7);
  }
  // mm/yyyy
  for (final m in RegExp(r'\b(\d{1,2})[/.\-](\d{4}|\d{2})\b').allMatches(t)) {
    final d = _build(int.parse(m[2]!), int.parse(m[1]!), 0);
    if (d != null) return ParsedDate(d, 0.7);
  }
  return null;
}

final _expiryHint = RegExp(r'EXP|BEST BEFORE|USE BY|\bBB\b|\bBBE\b');

/// Picks the expiry date from multi-line OCR text.
/// Lines with an expiry keyword win; otherwise the latest date found is used,
/// because a label often shows a manufacture date as well.
ParsedDate? parseExpiryFromText(String text) {
  final lines = text.split('\n');
  List<ParsedDate> read(Iterable<String> ls) =>
      [for (final l in ls) if (_parseLine(l) != null) _parseLine(l)!];

  final hinted = read(lines.where((l) => _expiryHint.hasMatch(l.toUpperCase())));
  final pool = hinted.isNotEmpty ? hinted : read(lines);
  if (pool.isEmpty) return null;
  pool.sort((a, b) => a.date.compareTo(b.date));
  return pool.last;
}
