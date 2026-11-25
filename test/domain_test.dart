import 'package:flutter_test/flutter_test.dart';
import 'package:equishare/data/custody.dart';
import 'package:equishare/domain/compliance.dart';
import 'package:equishare/domain/date_parser.dart';

void main() {
  final now = DateTime(2026, 11, 22);
  const rules = RuleSet(
    version: 'test',
    minDaysLeft: {LotCategory.food: 1, LotCategory.medicine: 30},
    restrictedKeywords: ['tramadol'],
  );

  group('date parser', () {
    test('day/month/year', () {
      expect(parseExpiryFromText('EXP 25/11/2026')!.date, DateTime(2026, 11, 25));
    });
    test('day month-name 2-digit year', () {
      expect(parseExpiryFromText('BB 18 NOV 26')!.date, DateTime(2026, 11, 18));
    });
    test('month and year only uses the last day', () {
      expect(parseExpiryFromText('Best before 11.2026')!.date, DateTime(2026, 11, 30));
    });
    test('expiry line wins over manufacture date', () {
      final r = parseExpiryFromText('MFG 01/10/2026\nEXP 14/01/2027');
      expect(r!.date, DateTime(2027, 1, 14));
    });
    test('no date returns null', () {
      expect(parseExpiryFromText('hello world'), isNull);
    });
  });

  group('compliance', () {
    ComplianceResult run(String n, LotCategory c, DateTime? e) =>
        evaluate(name: n, category: c, expiry: e, rules: rules, now: now);

    test('clears milk with 3 days left', () {
      expect(run('Whole Milk', LotCategory.food, DateTime(2026, 11, 25)).verdict, Verdict.cleared);
    });
    test('blocks expired yoghurt', () {
      final r = run('Yoghurt', LotCategory.food, DateTime(2026, 11, 18));
      expect(r.verdict, Verdict.blocked);
      expect(r.reason, 'Expired 4 days ago');
    });
    test('blocks restricted medicine', () {
      expect(run('Tramadol 50mg', LotCategory.medicine, DateTime(2027, 3, 2)).verdict, Verdict.blocked);
    });
    test('clears paracetamol with 53 days left', () {
      expect(run('Paracetamol', LotCategory.medicine, DateTime(2027, 1, 14)).verdict, Verdict.cleared);
    });
    test('flags short-dated medicine', () {
      expect(run('Paracetamol', LotCategory.medicine, DateTime(2026, 12, 2)).verdict, Verdict.flagged);
    });
    test('sends unreadable dates to review', () {
      expect(run('Rice', LotCategory.food, null).verdict, Verdict.review);
    });
  });

  group('custody chain', () {
    test('valid chain verifies and tampering is detected', () {
      final a = appendEntry(last: null, lotId: 'L1', event: 'scanned', actorId: 'u1');
      final b = appendEntry(last: a, lotId: 'L1', event: 'cleared', actorId: 'u1');
      expect(verifyChain([a, b]), isTrue);
      final tampered = CustodyEntry(
        lotId: b.lotId, event: 'delivered', actorId: b.actorId,
        timestamp: b.timestamp, prevHash: b.prevHash, hash: b.hash,
      );
      expect(verifyChain([a, tampered]), isFalse);
    });
  });
}
