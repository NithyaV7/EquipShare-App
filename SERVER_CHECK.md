# Optional: server-side custody check

The app already checks each custody log on the phone, and the **Verify with cloud** button re-checks the cloud copy. This optional step adds a check that runs on Google's servers every time an entry is saved, and records the result in a `custodyChecks` collection.

It needs the **Blaze** (pay as you go) Firebase plan. Small projects like this one normally stay inside the free allowance, but a payment card is required. Skip this step if that is a problem. The app works fully without it.

## Steps
1. Install Node.js 20 from https://nodejs.org.
2. In a terminal, run `npm install -g firebase-tools`, then `firebase login`.
3. In the project folder, run `firebase init functions`. Choose your Firebase project and JavaScript. When asked to overwrite `index.js` or `package.json`, answer **No**.
4. Run `cd functions` and then `npm install`.
5. Run `firebase deploy --only functions`.
6. Publish the updated `firestore.rules` from this project in the Firebase console. It adds read access for `custodyChecks`.
7. In the console, open Firestore. After you scan a lot while signed in, a `custodyChecks` document appears for each custody entry, with `ok: true` or a reason.

## What it checks
- The entry's hash matches its contents. It uses the same SHA-256 rule as the app.
- The document id equals the hash.
- The previous entry exists and belongs to the same lot.

`reason: previous entry not found yet` can appear briefly when entries arrive out of order. It is not an error by itself.

The check logic is in `functions/chain.js`. It was tested against the app's hash format, including a tampered entry and a missing previous entry.
