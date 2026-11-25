import 'package:flutter_test/flutter_test.dart';
import 'package:equishare/data/custody.dart';
import 'package:equishare/models.dart';

void main() {
  test('orderChain restores the right order and verifies', () {
    final a = appendEntry(last: null, lotId: 'L1', event: 'scanned', actorId: 'u1');
    final b = appendEntry(last: a, lotId: 'L1', event: 'cleared', actorId: 'u1');
    final c = appendEntry(last: b, lotId: 'L1', event: 'dispatched', actorId: 'u1');
    final shuffled = [c, a, b];
    final ordered = orderChain(shuffled);
    expect(ordered.map((e) => e.event), ['scanned', 'cleared', 'dispatched']);
    expect(verifyChain(ordered), isTrue);
  });

  test('a missing middle entry fails verification', () {
    final a = appendEntry(last: null, lotId: 'L1', event: 'scanned', actorId: 'u1');
    final b = appendEntry(last: a, lotId: 'L1', event: 'cleared', actorId: 'u1');
    final c = appendEntry(last: b, lotId: 'L1', event: 'dispatched', actorId: 'u1');
    expect(verifyChain(orderChain([a, c])), isFalse);
  });

  test('notification survives a save and load', () {
    final n = AppNote(
        id: '1', role: 'donor', title: 'Offer accepted', body: 'x', time: DateTime(2026, 11, 25));
    final back = AppNote.fromJson(n.toJson());
    expect(back.title, 'Offer accepted');
    expect(back.read, isFalse);
  });
}
