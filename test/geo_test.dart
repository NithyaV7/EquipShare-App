import 'package:flutter_test/flutter_test.dart';
import 'package:equishare/data/geo.dart';
import 'package:equishare/domain/compliance.dart';
import 'package:equishare/models.dart';

void main() {
  test('distance Colombo to Kandy is about 94 km', () {
    expect(haversineKm(6.9271, 79.8612, 7.2906, 80.6337), closeTo(94, 4));
  });

  test('distance to the same point is zero', () {
    expect(haversineKm(6.9, 79.8, 6.9, 79.8), closeTo(0, 0.001));
  });

  test('offer survives a save and load', () {
    final lot = Lot(
      id: 'l1', name: 'Milk', barcode: '123', category: LotCategory.food,
      expiry: DateTime(2026, 12, 1), kg: 2, verdict: Verdict.cleared, reason: '5 days left',
      donorId: 'd1', createdAt: DateTime(2026, 11, 22), synced: false,
    );
    final o = Offer(
      id: 'o1', lotIds: ['l1'], donorId: 'd1', recipientId: 'r1',
      createdAt: DateTime(2026, 11, 22), snapshot: [lot], synced: false,
    );
    final back = Offer.fromJson(o.toJson());
    expect(back.lotIds, ['l1']);
    expect(back.snapshot.single.name, 'Milk');
    expect(back.synced, isFalse);
    expect(o.toCloud().containsKey('synced'), isFalse);
  });

  test('recipient profile survives a save and load', () {
    final r = seedRecipients().first;
    final back = Recipient.fromJson(r.toJson());
    expect(back.name, r.name);
    expect(back.accepts, r.accepts);
  });
}
