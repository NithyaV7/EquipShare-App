# EquiShare

Mobile app for redistributing near-expiry food and medicine. Built with Flutter.

This version is a working local demo. It runs fully offline, keeps its data on the device, and includes the real compliance rules, date parser and hash-chained custody log.

## Fastest way to get the app (no installs)

1. Go to github.com, click **New repository**, name it `equishare`, and click **Create repository**.
2. On the new repository page, click **uploading an existing file**.
3. Unzip the zip on your computer. Open the `equishare_app` folder, select everything inside it, and drag it into the GitHub page. Make sure the `.github` folder is included (see the tip below).
4. Click **Commit changes**.
5. Open the **Actions** tab. A run called **Build APK** starts by itself. Wait about 5 to 10 minutes for the green tick.
6. Click the run, scroll to **Artifacts**, and download **equishare-apk**. Unzip it and copy `app-release.apk` to an Android phone. Open it to install (allow "install from unknown sources" when asked).

If the run shows a red cross, open it, copy the error text, and send it to me.

Tip: `.github` is a hidden folder. On Windows, open View, then Show, then Hidden items. On Mac, press Cmd + Shift + . in Finder.

## Open it in your browser (no phone needed)

The same GitHub build also publishes a web version of the app.

1. In your repository, open **Settings**, then **Pages**.
2. Under **Source**, choose **GitHub Actions**. (Do this once.)
3. Open the **Actions** tab. If the latest run already failed at the deploy step, click **Re-run all jobs**. Otherwise, push any small change to start a new run.
4. When the run is green, your link appears in the **deploy** job and on the Settings, Pages screen. It looks like `https://YOUR-USERNAME.github.io/equishare/`.
5. Open the link. On a computer, press F12 and click the phone icon to see it at phone size. On a phone, just open the link.

GitHub Pages needs a **public** repository on the free plan.

## Run it on your own computer instead

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. In the project folder, run these commands:

```
flutter create . --project-name equishare --org lk.equishare
rm test/widget_test.dart
flutter pub get
flutter test
flutter run
```

On Windows PowerShell, use `del test\widget_test.dart` instead of `rm`.

## Try the demo

1. Log in as **Donor**. Open **Scan**, tap **Use sample**, then **Add to batch**. Repeat 4 times to add all four samples.
2. Tap **Review and clear lots**. The milk and paracetamol are cleared. The yoghurt (expired) and tramadol (restricted) are blocked.
3. Tap **Find recipients**, then choose one. The offer is created.
4. Go to **Profile**, log out, and log in as **Recipient**. Accept the offer, then use the **Track** tab to confirm pickup and delivery.
5. Log out and log in as Donor again. Check the **Custody** and **ESG** tabs.

Tap the pill at the top right to simulate going offline. Lots scanned offline show as queued until you go back online.

## What is built

| Feature | Status |
|---|---|
| Camera and gallery scanning with ML Kit (reads the barcode and the printed date, works offline) | Built. Android only |
| Compliance check, date parser, custody hash chain | Built |
| Local offline storage and a real sync queue | Built |
| Sign-in, cloud sync and two-phone offers with Firebase | Built, needs your setup. See FIREBASE_SETUP.md |
| Matching by real distance, with a device location option | Built |
| Recipient profile: what they accept, capacity, location | Built (cloud mode) |
| ESG report as PDF | Built |
| Poppins and Inter fonts | Built. Downloaded once, then cached |

## Still to do

| Missing | Notes |
|---|---|
| Push notifications | Add firebase_messaging and a Cloud Function that sends on a new offer |
| Live camera stream (continuous scan) | The app scans one photo at a time |
| Official compliance rules | `assets/rules_v1.json` is a placeholder |
| Server-side check of the custody hash chain | Add a Cloud Function |
| Real ESG and tax factors | Placeholders for now |
| iOS build | The workflow builds Android and web only |

## Important notes

- `assets/rules_v1.json` holds placeholder compliance thresholds and a short keyword list for restricted medicines. Replace them with rules confirmed against the real regulations before any real use.
- The ESG figures use placeholder factors (2.5 kg CO₂e and Rs. 600 per kg).
- Until you finish FIREBASE_SETUP.md, login is a demo and anyone can choose either role.
- Scanning needs a clear, well-lit photo. Always check the date it reads before adding a lot.
