import '../data/custody.dart';
import '../models.dart';

class CloudException implements Exception {
  CloudException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CloudUser {
  const CloudUser(this.uid, this.role, this.email);
  final String uid;
  final String role;
  final String email;
}

/// Everything the app needs from a backend. LocalCloud does nothing,
/// FirebaseCloud talks to Firebase.
abstract class Cloud {
  bool get enabled;
  String? get currentUid;
  Future<CloudUser> signIn({
    required String email,
    required String password,
    required String role,
    required bool register,
  });
  Future<void> signOut();
  Future<void> saveLot(Lot l);
  Future<void> saveCustody(CustodyEntry e);
  Future<void> saveOffer(Offer o, {required bool statusOnly});
  Stream<List<Offer>> watchOffers(String field, String uid);
  Future<List<Recipient>> recipients();
  Future<Recipient?> loadProfile(String uid);
  Future<void> saveProfile(Recipient r);
  Future<List<CustodyEntry>> custodyFor(String lotId);
}

class LocalCloud implements Cloud {
  @override
  bool get enabled => false;
  @override
  String? get currentUid => null;
  @override
  Future<CloudUser> signIn({
    required String email,
    required String password,
    required String role,
    required bool register,
  }) async =>
      throw CloudException('Cloud sync is not set up yet. Use demo mode.');
  @override
  Future<void> signOut() async {}
  @override
  Future<void> saveLot(Lot l) async {}
  @override
  Future<void> saveCustody(CustodyEntry e) async {}
  @override
  Future<void> saveOffer(Offer o, {required bool statusOnly}) async {}
  @override
  Stream<List<Offer>> watchOffers(String field, String uid) => const Stream.empty();
  @override
  Future<List<Recipient>> recipients() async => [];
  @override
  Future<Recipient?> loadProfile(String uid) async => null;
  @override
  Future<void> saveProfile(Recipient r) async {}
  @override
  Future<List<CustodyEntry>> custodyFor(String lotId) async => [];
}
