# Turn on cloud sync (Firebase), step by step

Without this, the app runs in demo mode on one device. With it, donors and recipients sign in on different phones and exchange offers.

You need a Google account. Everything below is free on the Spark plan.

## 1. Create the project
1. Go to https://console.firebase.google.com and click **Create a project**. Name it `equishare`. You can turn off Google Analytics.

## 2. Turn on sign-in
1. In the left menu, open **Build**, then **Authentication**, then **Get started**.
2. Under **Sign-in method**, choose **Email/Password**, switch it on, and click **Save**.

## 3. Create the database
1. Open **Build**, then **Firestore Database**, then **Create database**.
2. Choose any location near you and start in **production mode**.
3. Open the **Rules** tab. Delete what is there, paste the full contents of `firestore.rules` from this project, and click **Publish**.

## 4. Register the Android app
1. Click the gear icon, then **Project settings**. Under **Your apps**, click the Android icon.
2. For the package name, type exactly `lk.equishare.equishare`. Click **Register app**.
3. Click **Download google-services.json**, then **Next** until done. You do not need to add it to the project. You only need three values from it.
4. Open the downloaded file in Notepad. Find these values:

| In google-services.json | Goes in firebase_options.dart (android section) |
|---|---|
| `current_key` (under `api_key`) | `apiKey` |
| `mobilesdk_app_id` | `appId` |
| `project_number` | `messagingSenderId` |
| `project_id` | `projectId` |

## 5. Register the web app (for the browser version)
1. Back in **Project settings**, click **Add app**, then the web icon `</>`. Name it `equishare-web` and click **Register app**.
2. The page shows a block called `firebaseConfig`. Copy `apiKey`, `appId`, `messagingSenderId` and `projectId` into the **web** section of `firebase_options.dart`. Set `authDomain` to the value shown.
3. In **Authentication**, open **Settings**, then **Authorized domains**, and add `YOUR-USERNAME.github.io`.

## 6. Paste the values into the project
1. On GitHub, open `lib/firebase_options.dart` and click the pencil icon.
2. Replace every `PASTE_...` text with your values. Keep the quote marks.
3. Click **Commit changes**. The GitHub build runs again and publishes a new APK and web link.

These keys are not secrets. Firebase keys identify your project, and the security rules in step 3 are what protect the data.

## 7. Try it with two accounts
1. Open the app and tap **Create account**. Choose **Recipient**, and sign up with one email.
2. In **Profile**, set your name, what you accept, your free capacity and your location. Tap **Save**.
3. On a second device or browser, create a **Donor** account.
4. As the donor, scan lots, clear them, and open matching. The recipient appears in the list. Tap it to send the offer.
5. On the recipient's device, the offer appears in **Offers**. Accept it, then confirm pickup and delivery.
6. The donor's **Custody** tab shows every step, including the ones made on the other phone.

## If something goes wrong
- **Sign-in says the network failed:** the first sign-in needs internet. After that, the app keeps working offline and uploads later.
- **"Permission denied" or nothing appears:** check that the rules from step 3 were published, and that the recipient saved their profile.
- **The login screen still says demo mode:** a value in `firebase_options.dart` still starts with PASTE.
