// Pure Dart: no Flutter or Isar imports, so it is easy to unit test.

enum LotCategory { food, medicine }

enum Verdict { cleared, flagged, blocked, review }

class ComplianceResult {
  const ComplianceResult(this.verdict, this.reason, {this.ruleSetVersion = ''});
  final Verdict verdict;
  final String reason;
  final String ruleSetVersion;
  bool get canDonate => verdict == Verdict.cleared;
}

/// Rules are loaded from JSON so they can change without a new app release.
class RuleSet {
  const RuleSet({
    required this.version,
    required this.minDaysLeft,
    required this.restrictedKeywords,
  });

  final String version;
  final Map<LotCategory, int> minDaysLeft;
  final List<String> restrictedKeywords;

  factory RuleSet.fromJson(Map<String, dynamic> j) => RuleSet(
        version: j['version'] as String,
        minDaysLeft: {
          for (final e in (j['minDaysLeft'] as Map<String, dynamic>).entries)
            LotCategory.values.byName(e.key): e.value as int,
        },
        restrictedKeywords: [
          for (final k in j['restrictedKeywords'] as List)
            (k as String).toLowerCase(),
        ],
      );
}

/// Order matters: restricted items are blocked before any date logic.
ComplianceResult evaluate({
  required String name,
  required LotCategory category,
  required DateTime? expiry,
  required RuleSet rules,
  DateTime? now,
}) {
  final v = rules.version;
  final lower = name.toLowerCase();

  if (category == LotCategory.medicine &&
      rules.restrictedKeywords.any(lower.contains)) {
    return ComplianceResult(
        Verdict.blocked, 'Restricted prescription lot', ruleSetVersion: v);
  }

  if (expiry == null) {
    return ComplianceResult(Verdict.review, 'No readable expiry date',
        ruleSetVersion: v);
  }

  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final daysLeft = DateTime(expiry.year, expiry.month, expiry.day)
      .difference(today)
      .inDays;

  if (daysLeft < 0) {
    final ago = -daysLeft;
    return ComplianceResult(
        Verdict.blocked, 'Expired $ago day${ago == 1 ? '' : 's'} ago',
        ruleSetVersion: v);
  }

  final min = rules.minDaysLeft[category] ?? 0;
  if (daysLeft < min) {
    return ComplianceResult(
        Verdict.flagged, 'Short-dated: $daysLeft days left, minimum $min',
        ruleSetVersion: v);
  }

  return ComplianceResult(Verdict.cleared, '$daysLeft days left',
      ruleSetVersion: v);
}
