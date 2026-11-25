import 'dart:convert';
import 'package:crypto/crypto.dart';

const genesisHash = 'GENESIS';

class CustodyEntry {
  const CustodyEntry({
    required this.lotId,
    required this.event,
    required this.actorId,
    required this.timestamp,
    required this.prevHash,
    required this.hash,
  });
  final String lotId;
  final String event; // scanned, cleared, blocked, dispatched, accepted, picked_up, delivered
  final String actorId;
  final String timestamp; // UTC ISO 8601
  final String prevHash;
  final String hash;

  Map<String, dynamic> toJson() => {
        'lotId': lotId,
        'event': event,
        'actorId': actorId,
        'timestamp': timestamp,
        'prevHash': prevHash,
        'hash': hash,
      };

  factory CustodyEntry.fromJson(Map<String, dynamic> j) => CustodyEntry(
        lotId: j['lotId'] as String,
        event: j['event'] as String,
        actorId: j['actorId'] as String,
        timestamp: j['timestamp'] as String,
        prevHash: j['prevHash'] as String,
        hash: j['hash'] as String,
      );
}

String computeHash(String prev, String lotId, String event, String actor, String ts) =>
    sha256.convert(utf8.encode(jsonEncode([prev, lotId, event, actor, ts]))).toString();

/// Creates the next entry in a lot's chain. Pass the last entry, or null for the first.
CustodyEntry appendEntry({
  required CustodyEntry? last,
  required String lotId,
  required String event,
  required String actorId,
  DateTime? now,
}) {
  final ts = (now ?? DateTime.now()).toUtc().toIso8601String();
  final prev = last?.hash ?? genesisHash;
  return CustodyEntry(
    lotId: lotId,
    event: event,
    actorId: actorId,
    timestamp: ts,
    prevHash: prev,
    hash: computeHash(prev, lotId, event, actorId, ts),
  );
}

/// True when no entry has been changed or removed.
bool verifyChain(List<CustodyEntry> chain) {
  var prev = genesisHash;
  for (final e in chain) {
    if (e.prevHash != prev) return false;
    if (e.hash != computeHash(e.prevHash, e.lotId, e.event, e.actorId, e.timestamp)) {
      return false;
    }
    prev = e.hash;
  }
  return true;
}

/// Puts entries in chain order by following the hash links.
/// Entries that do not link in are added at the end, so verification fails for them.
List<CustodyEntry> orderChain(List<CustodyEntry> entries) {
  final es = List<CustodyEntry>.of(entries);
  final out = <CustodyEntry>[];
  var prev = genesisHash;
  while (true) {
    final i = es.indexWhere((e) => e.prevHash == prev);
    if (i < 0) break;
    out.add(es.removeAt(i));
    prev = out.last.hash;
  }
  out.addAll(es);
  return out;
}
