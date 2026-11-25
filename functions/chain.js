const crypto = require('crypto');

const GENESIS = 'GENESIS';

// Must match computeHash() in lib/data/custody.dart.
function hashOf(e) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify([e.prevHash, e.lotId, e.event, e.actorId, e.timestamp]), 'utf8')
    .digest('hex');
}

/** Returns { ok, reason } for one custody entry. getById looks up an earlier entry. */
async function checkEntry(docId, e, getById) {
  if (hashOf(e) !== e.hash) return { ok: false, reason: 'hash does not match the entry contents' };
  if (docId !== e.hash) return { ok: false, reason: 'document id is not the hash' };
  if (e.prevHash === GENESIS) return { ok: true, reason: '' };
  const prev = await getById(e.prevHash);
  if (!prev) return { ok: false, reason: 'previous entry not found yet' };
  if (prev.lotId !== e.lotId) return { ok: false, reason: 'previous entry belongs to another lot' };
  return { ok: true, reason: '' };
}

module.exports = { hashOf, checkEntry, GENESIS };
