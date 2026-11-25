import 'domain/compliance.dart';

class Lot {
  Lot({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.expiry,
    required this.kg,
    required this.verdict,
    required this.reason,
    required this.donorId,
    required this.createdAt,
    required this.synced,
    this.status = 'scanned', // scanned, offered, accepted, picked_up, delivered, discarded
    this.recipientId,
  });

  final String id;
  final String name;
  final String barcode;
  final LotCategory category;
  final DateTime? expiry;
  final double kg;
  final Verdict verdict;
  final String reason;
  final String donorId;
  final DateTime createdAt;
  bool synced;
  String status;
  String? recipientId;

  bool get cleared => verdict == Verdict.cleared;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'category': category.name,
        'expiry': expiry?.toIso8601String(),
        'kg': kg,
        'verdict': verdict.name,
        'reason': reason,
        'donorId': donorId,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
        'status': status,
        'recipientId': recipientId,
      };

  factory Lot.fromJson(Map<String, dynamic> j) => Lot(
        id: j['id'] as String,
        name: j['name'] as String,
        barcode: j['barcode'] as String,
        category: LotCategory.values.byName(j['category'] as String),
        expiry: j['expiry'] == null ? null : DateTime.parse(j['expiry'] as String),
        kg: (j['kg'] as num).toDouble(),
        verdict: Verdict.values.byName(j['verdict'] as String),
        reason: j['reason'] as String,
        donorId: j['donorId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        synced: j['synced'] as bool,
        status: j['status'] as String,
        recipientId: j['recipientId'] as String?,
      );
}

class Recipient {
  Recipient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lat,
    required this.lng,
    required this.accepts,
    required this.freePct,
  });

  final String id;
  String name;
  String emoji;
  double lat;
  double lng;
  Set<LotCategory> accepts;
  int freePct;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'lat': lat,
        'lng': lng,
        'accepts': [for (final c in accepts) c.name],
        'freePct': freePct,
      };

  factory Recipient.fromJson(Map<String, dynamic> j) => Recipient(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '🏠',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accepts: {for (final c in j['accepts'] as List) LotCategory.values.byName(c as String)},
        freePct: (j['freePct'] as num).toInt(),
      );
}

/// Demo recipients near Colombo, used when cloud sync is off.
List<Recipient> seedRecipients() => [
      Recipient(id: 'r1', name: 'Green Hope Kitchen', emoji: '🍲', lat: 6.9344, lng: 79.8428, accepts: {LotCategory.food}, freePct: 70),
      Recipient(id: 'r2', name: 'Northside Free Clinic', emoji: '🏥', lat: 6.9500, lng: 79.8700, accepts: {LotCategory.medicine}, freePct: 45),
      Recipient(id: 'r3', name: 'Eastside Food Bank', emoji: '📦', lat: 6.9100, lng: 79.8900, accepts: {LotCategory.food}, freePct: 30),
      Recipient(id: 'r4', name: 'Sunrise Shelter', emoji: '🏠', lat: 6.8800, lng: 79.9050, accepts: {LotCategory.food, LotCategory.medicine}, freePct: 55),
    ];

class Offer {
  Offer({
    required this.id,
    required this.lotIds,
    required this.donorId,
    required this.recipientId,
    required this.createdAt,
    this.status = 'pending', // pending, accepted, picked_up, delivered, declined
    this.snapshot = const [],
    this.synced = true,
  });

  final String id;
  final List<String> lotIds;
  final String donorId;
  final String recipientId;
  final DateTime createdAt;
  final List<Lot> snapshot; // copy of the lots, so the recipient can see them
  String status;
  bool synced;

  int get step => switch (status) {
        'accepted' => 1,
        'picked_up' => 2,
        'delivered' => 3,
        _ => 0,
      };

  Map<String, dynamic> toCloud() => {
        'id': id,
        'lotIds': lotIds,
        'donorId': donorId,
        'recipientId': recipientId,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'lots': [for (final l in snapshot) l.toJson()],
      };

  Map<String, dynamic> toJson() => {...toCloud(), 'synced': synced};

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'] as String,
        lotIds: [for (final e in j['lotIds'] as List) e as String],
        donorId: j['donorId'] as String,
        recipientId: j['recipientId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: j['status'] as String,
        snapshot: [
          for (final e in (j['lots'] as List? ?? const []))
            Lot.fromJson(Map<String, dynamic>.from(e as Map))
        ],
        synced: j['synced'] as bool? ?? true,
      );
}
