const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { checkEntry } = require('./chain');

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
