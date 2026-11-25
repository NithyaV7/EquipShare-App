import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'cloud/cloud.dart';
import 'data/custody.dart';
import 'data/geo.dart';
import 'data/store.dart';
import 'domain/compliance.dart';
import 'models.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Use inside build(): the widget rebuilds when the state changes.
  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Use inside button handlers.
  static AppState read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class AppState extends ChangeNotifier {
  AppState(this.rules, this.cloud);
  final RuleSet rules;
  final Cloud cloud;

  String? role; // 'donor' or 'recipient'
  String? uid; // null in demo mode
  String? email;
  bool offline = false;
  double lat = 6.9271; // demo location in Colombo until the user shares theirs
  double lng = 79.8612;
  bool deviceLoc = false;
  List<Lot> lots = [];
  List<Offer> offers = [];
  List<CustodyEntry> custody = [];
  List<Recipient> recipients = []; // cloud directory (cached)
  Recipient? profile; // the signed-in recipient's own profile
  Set<String> pushed = {}; // custody hashes already uploaded

  final List<Recipient> _seeds = seedRecipients();
  StreamSubscription<List<Offer>>? _sub;
  bool _syncing = false;

  bool get cloudMode => cloud.enabled && uid != null;
  String get userId => uid ?? (role == 'recipient' ? 'r1' : 'donor1');
  String get userName {
    if (role == 'recipient' && profile != null) return profile!.name;
    if (uid != null) return (email ?? 'You').split('@').first;
    return role == 'recipient' ? 'Green Hope Kitchen' : 'Greenleaf Grocers';
  }

  // ---------- saving and loading ----------
  void load() {
    final s = Store.read();
    if (s == null) return;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      role = m['role'] as String?;
      uid = m['uid'] as String?;
      email = m['email'] as String?;
      offline = m['offline'] as bool? ?? false;
      lat = (m['lat'] as num?)?.toDouble() ?? lat;
      lng = (m['lng'] as num?)?.toDouble() ?? lng;
      deviceLoc = m['deviceLoc'] as bool? ?? false;
      lots = [for (final e in m['lots'] as List) Lot.fromJson(Map<String, dynamic>.from(e as Map))];
      offers = [for (final e in m['offers'] as List) Offer.fromJson(Map<String, dynamic>.from(e as Map))];
      custody = [
        for (final e in m['custody'] as List) CustodyEntry.fromJson(Map<String, dynamic>.from(e as Map))
      ];
      recipients = [
        for (final e in (m['recipients'] as List? ?? const []))
          Recipient.fromJson(Map<String, dynamic>.from(e as Map))
      ];
      profile = m['profile'] == null
          ? null
          : Recipient.fromJson(Map<String, dynamic>.from(m['profile'] as Map));
      pushed = {for (final e in (m['pushed'] as List? ?? const [])) e as String};
    } catch (_) {
      // Corrupt data: start fresh.
    }
    // A saved cloud session is only valid if Firebase still has that user.
    if (uid != null && cloud.currentUid != uid) {
      role = null;
      uid = null;
      email = null;
    }
  }

  /// Call once after load(): starts live updates and uploads anything queued.
  void start() {
    _listen();
    unawaited(syncNow());
    if (cloudMode && role == 'donor') unawaited(refreshRecipients());
  }

  void _save() {
    unawaited(Store.write(jsonEncode({
      'role': role,
      'uid': uid,
      'email': email,
      'offline': offline,
      'lat': lat,
      'lng': lng,
      'deviceLoc': deviceLoc,
      'lots': [for (final l in lots) l.toJson()],
      'offers': [for (final o in offers) o.toJson()],
      'custody': [for (final e in custody) e.toJson()],
      'recipients': [for (final r in recipients) r.toJson()],
      'profile': profile?.toJson(),
      'pushed': pushed.toList(),
    })));
  }

  void _changed() {
    notifyListeners();
    _save();
    unawaited(syncNow());
  }

  // ---------- session ----------
  void signInDemo(String r) {
    role = r;
    uid = null;
    email = null;
    profile = null;
    _changed();
  }

  /// Returns an error message, or null on success.
  Future<String?> signInCloud({
    required String email,
    required String password,
    required String chosenRole,
    required bool register,
  }) async {
    try {
      final u = await cloud.signIn(
          email: email, password: password, role: chosenRole, register: register);
      role = u.role;
      uid = u.uid;
      this.email = u.email;
      if (u.role == 'recipient') {
        profile = await cloud.loadProfile(u.uid);
        if (profile == null) {
          profile = Recipient(
            id: u.uid,
            name: u.email.split('@').first,
            emoji: '🏠',
            lat: lat,
            lng: lng,
            accepts: {LotCategory.food, LotCategory.medicine},
            freePct: 100,
          );
          await cloud.saveProfile(profile!);
        }
      }
      _changed();
      _listen();
      if (u.role == 'donor') unawaited(refreshRecipients());
      return null;
    } on CloudException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not sign in: $e';
    }
  }

  void signOut() {
    _sub?.cancel();
    _sub = null;
    if (uid != null) {
      // Shared phones: do not leave one user's data visible to the next user.
      unawaited(cloud.signOut());
      lots = [];
      offers = [];
      custody = [];
      recipients = [];
      pushed = {};
    }
    role = null;
    uid = null;
    email = null;
    profile = null;
    _changed();
  }

  void resetDemo() {
    lots = [];
    offers = [];
    custody = [];
    _changed();
  }

  // ---------- location and directory ----------
  Future<bool> useMyLocation() async {
    final p = await deviceLocation();
    if (p == null) return false;
    lat = p.lat;
    lng = p.lng;
    deviceLoc = true;
    _changed();
    return true;
  }

  double distanceKm(Recipient r) => haversineKm(lat, lng, r.lat, r.lng);

  List<Recipient> get directory => cloudMode ? recipients : _seeds;

  Future<void> refreshRecipients() async {
    try {
      recipients = await cloud.recipients();
      _changed();
    } catch (_) {}
  }

  Future<void> saveProfile(Recipient p) async {
    profile = p;
    _changed();
    try {
      await cloud.saveProfile(p);
    } catch (_) {}
  }

  // ---------- offline and sync ----------
  int get queuedCount => lots.where((l) => !l.synced).length;

  void setOffline(bool v) {
    offline = v;
    _changed(); // going online uploads the queue
  }

  Future<void> syncNow() async {
    if (offline || _syncing) return;
    _syncing = true;
    try {
      final online = cloudMode;
      for (final l in lots.where((l) => !l.synced).toList()) {
        try {
          if (online) await cloud.saveLot(l);
          l.synced = true;
        } catch (_) {
          break;
        }
      }
      if (online) {
        for (final e in custody.where((e) => !pushed.contains(e.hash)).toList()) {
          try {
            await cloud.saveCustody(e);
            pushed.add(e.hash);
          } catch (_) {
            break;
          }
        }
        for (final o in offers.where((o) => !o.synced).toList()) {
          try {
            await cloud.saveOffer(o, statusOnly: role == 'recipient');
            o.synced = true;
          } catch (_) {
            break;
          }
        }
      } else {
        for (final o in offers) {
          o.synced = true;
        }
      }
    } finally {
      _syncing = false;
    }
    notifyListeners();
    _save();
  }

  void _listen() {
    _sub?.cancel();
    _sub = null;
    if (!cloudMode) return;
    final field = role == 'recipient' ? 'recipientId' : 'donorId';
    _sub = cloud.watchOffers(field, uid!).listen(_mergeOffers, onError: (_) {});
  }

  void _mergeOffers(List<Offer> remote) {
    var changed = false;
    for (final r in remote) {
      final i = offers.indexWhere((o) => o.id == r.id);
      if (i < 0) {
        offers.add(r);
        changed = true;
        continue;
      }
      final o = offers[i];
      if (o.synced && o.status != r.status) {
        o.status = r.status;
        changed = true;
      }
      if (role == 'donor' && _applyToLots(o)) changed = true;
    }
    if (changed) _changed();
    if (role == 'donor') {
      for (final r in remote) {
        if (r.status != 'pending') unawaited(_pullCustody(r.lotIds));
      }
    }
  }

  bool _applyToLots(Offer o) {
    var ch = false;
    final target = o.status == 'declined' ? 'scanned' : (o.status == 'pending' ? 'offered' : o.status);
    for (final l in lots.where((l) => o.lotIds.contains(l.id) && l.donorId == userId)) {
      if (l.status != target) {
        l.status = target;
        if (o.status == 'declined') l.recipientId = null;
        l.synced = false;
        ch = true;
      }
    }
    return ch;
  }

  Future<void> _pullCustody(List<String> ids) async {
    final before = custody.length;
    for (final id in ids) {
      try {
        _mergeCustody(await cloud.custodyFor(id));
      } catch (_) {}
    }
    if (custody.length != before) {
      notifyListeners();
      _save();
    }
  }

  void _mergeCustody(List<CustodyEntry> es) {
    final have = {for (final e in custody) e.hash};
    for (final e in es) {
      if (have.add(e.hash)) custody.add(e);
      pushed.add(e.hash);
    }
  }

  Future<void> _ensureChain(String lotId) async {
    if (!cloudMode || offline) return;
    try {
      _mergeCustody(await cloud.custodyFor(lotId));
    } catch (_) {}
  }

  // ---------- custody ----------
  /// Follows the hash links so the order is always right.
  List<CustodyEntry> chainFor(String lotId) {
    final es = custody.where((e) => e.lotId == lotId).toList();
    final out = <CustodyEntry>[];
    var prev = genesisHash;
    while (true) {
      final i = es.indexWhere((e) => e.prevHash == prev);
      if (i < 0) break;
      out.add(es.removeAt(i));
      prev = out.last.hash;
    }
    out.addAll(es); // anything that did not link, so verification fails
    return out;
  }

  void _log(String lotId, String event) {
    final chain = chainFor(lotId);
    custody.add(appendEntry(
      last: chain.isEmpty ? null : chain.last,
      lotId: lotId,
      event: event,
      actorId: userId,
    ));
  }

  // ---------- donor: scanning and compliance ----------
  List<Lot> get batch =>
      lots.where((l) => l.status == 'scanned' && l.donorId == userId).toList();

  Lot addLot({
    required String name,
    required String barcode,
    required LotCategory category,
    required DateTime? expiry,
    required double kg,
  }) {
    final r = evaluate(name: name, category: category, expiry: expiry, rules: rules);
    final lot = Lot(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      barcode: barcode,
      category: category,
      expiry: expiry,
      kg: kg,
      verdict: r.verdict,
      reason: r.reason,
      donorId: userId,
      createdAt: DateTime.now(),
      synced: false,
    );
    lots.add(lot);
    _log(lot.id, 'scanned');
    _log(lot.id, lot.cleared ? 'cleared' : 'blocked');
    _changed();
    return lot;
  }

  void discard(Lot l) {
    l.status = 'discarded';
    l.synced = false;
    _log(l.id, 'discarded');
    _changed();
  }

  // ---------- donor: matching and dispatch ----------
  List<Recipient> matches(int radiusKm) {
    final cats = {for (final l in batch.where((l) => l.cleared)) l.category};
    final list = directory
        .where((r) =>
            distanceKm(r) <= radiusKm && r.freePct > 0 && r.accepts.any(cats.contains))
        .toList();
    list.sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    return list;
  }

  Offer? dispatch(Recipient r) {
    final send = batch.where((l) => l.cleared && r.accepts.contains(l.category)).toList();
    if (send.isEmpty) return null;
    for (final l in send) {
      l.status = 'offered';
      l.recipientId = r.id;
      l.synced = false;
      _log(l.id, 'dispatched');
    }
    final o = Offer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      lotIds: [for (final l in send) l.id],
      donorId: userId,
      recipientId: r.id,
      createdAt: DateTime.now(),
      snapshot: [for (final l in send) Lot.fromJson(l.toJson())],
      synced: false,
    );
    offers.add(o);
    _changed();
    return o;
  }

  // ---------- recipient ----------
  List<Offer> get myOffers => (uid == null ? offers : offers.where((o) => o.recipientId == uid))
      .toList()
      .reversed
      .toList();

  List<Lot> lotsOf(Offer o) {
    final local = lots.where((l) => o.lotIds.contains(l.id)).toList();
    return local.length == o.lotIds.length ? local : o.snapshot;
  }

  Future<void> respond(Offer o, bool accept) async {
    o.status = accept ? 'accepted' : 'declined';
    o.synced = false;
    for (final l in lotsOf(o)) {
      await _ensureChain(l.id);
      if (accept) {
        l.status = 'accepted';
        _log(l.id, 'accepted');
      } else {
        l.status = 'scanned';
        l.recipientId = null;
        _log(l.id, 'declined');
      }
    }
    _changed();
  }

  Future<void> advance(Offer o) async {
    final next = o.status == 'accepted' ? 'picked_up' : 'delivered';
    o.status = next;
    o.synced = false;
    for (final l in lotsOf(o)) {
      await _ensureChain(l.id);
      l.status = next;
      _log(l.id, next);
    }
    _changed();
  }

  // ---------- ESG (estimates use placeholder factors) ----------
  static const co2PerKg = 2.5;
  static const rupeesPerKg = 600.0;

  List<Lot> get deliveredLots => lots.where((l) => l.status == 'delivered').toList();
  double get deliveredKg => deliveredLots.fold(0.0, (a, l) => a + l.kg);
}
