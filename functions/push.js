// Decides who should get a push message when an offer is created or changes.
// Returns { toUid, title, body } or null.
function pushFor(before, after) {
  if (!after) return null;
  if (!before) {
    if (after.status !== 'pending') return null;
    const n = (after.lotIds || []).length;
    return { toUid: after.recipientId, title: 'New offer', body: `${n} lot(s) are waiting for you.` };
  }
  if (before.status === after.status) return null;
  const titles = {
    accepted: 'Offer accepted',
    declined: 'Offer declined',
    picked_up: 'Lots picked up',
    delivered: 'Lots delivered',
  };
  const title = titles[after.status];
  if (!title) return null;
  return { toUid: after.donorId, title, body: 'A recipient updated your offer.' };
}

module.exports = { pushFor };
