import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/custody.dart';
import '../models.dart';
import 'cloud.dart';

class FirebaseCloud implements Cloud {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  static const _t = Duration(seconds: 15);

  @override
  bool get enabled => true;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  Future<String> _role(String uid) async {
    try {
      final d = await _db.collection('users').doc(uid).get();
      return (d.data()?['role'] as String?) ?? 'donor';
    } catch (_) {
      return 'donor';
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'That email already has an account. Try signing in.';
      case 'weak-password':
        return 'Choose a password with at least 6 characters.';
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'network-request-failed':
        return 'No internet connection. Sign-in needs internet the first time.';
      default:
        return e.message ?? e.code;
    }
  }

  @override
  Future<CloudUser> signIn({
    required String email,
    required String password,
    required String role,
    required bool register,
  }) async {
    try {
      final c = register
          ? await _auth.createUserWithEmailAndPassword(email: email, password: password)
          : await _auth.signInWithEmailAndPassword(email: email, password: password);
      final u = c.user!;
      if (register) {
        await _db.collection('users').doc(u.uid).set({'role': role, 'email': email});
        return CloudUser(u.uid, role, email);
      }
      return CloudUser(u.uid, await _role(u.uid), email);
    } on FirebaseAuthException catch (e) {
      throw CloudException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> saveLot(Lot l) => _db.collection('lots').doc(l.id).set(l.toJson()).timeout(_t);

  @override
  Future<void> saveCustody(CustodyEntry e) =>
      _db.collection('custody').doc(e.hash).set(e.toJson()).timeout(_t);

  @override
  Future<void> saveOffer(Offer o, {required bool statusOnly}) {
    final ref = _db.collection('offers').doc(o.id);
    final f = statusOnly ? ref.update({'status': o.status}) : ref.set(o.toCloud());
    return f.timeout(_t);
  }

  @override
  Stream<List<Offer>> watchOffers(String field, String uid) => _db
      .collection('offers')
      .where(field, isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) Offer.fromJson(d.data())]);

  @override
  Future<List<Recipient>> recipients() async {
    final s = await _db.collection('recipients').get().timeout(_t);
    return [for (final d in s.docs) Recipient.fromJson({...d.data(), 'id': d.id})];
  }

  @override
  Future<Recipient?> loadProfile(String uid) async {
    final d = await _db.collection('recipients').doc(uid).get().timeout(_t);
    final data = d.data();
    return data == null ? null : Recipient.fromJson({...data, 'id': uid});
  }

  @override
  Future<void> saveProfile(Recipient r) =>
      _db.collection('recipients').doc(r.id).set(r.toJson()).timeout(_t);

  @override
  Future<List<CustodyEntry>> custodyFor(String lotId) async {
    final s = await _db
        .collection('custody')
        .where('lotId', isEqualTo: lotId)
        .get()
        .timeout(_t);
    return [for (final d in s.docs) CustodyEntry.fromJson(d.data())];
  }
}
