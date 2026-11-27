const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { checkEntry } = require('./chain');
const { pushFor } = require('./push');

initializeApp();

// Runs on the server every time a custody entry is created, and records the result.
exports.verifyCustodyEntry = onDocumentCreated('custody/{id}', async (event) => {
  const db = getFirestore();
  const e = event.data.data();
  const result = await checkEntry(event.params.id, e, async (hash) => {
    const d = await db.collection('custody').doc(hash).get();
    return d.exists ? d.data() : null;
  });
  await db.collection('custodyChecks').doc(event.params.id).set({
    lotId: e.lotId,
    ok: result.ok,
    reason: result.reason,
    checkedAt: new Date().toISOString(),
  });
});

// Sends a push message to the other side when an offer is created or its status changes.
exports.notifyOffer = onDocumentWritten('offers/{id}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  const msg = pushFor(before, after);
  if (!msg) return;
  const user = await getFirestore().collection('users').doc(msg.toUid).get();
  const token = user.exists ? user.data().fcmToken : null;
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title: msg.title, body: msg.body },
    data: { offerId: event.params.id },
  });
});
