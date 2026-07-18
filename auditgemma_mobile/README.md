# AuditGemma Mobile

The dual-role mobile application for both SME applicants (uploading documents) and roaming Officers (quick triage).

## 📱 Mobile: Install on a Physical Device (Android)

For the live hackathon demo, you'll want this running on a physical Android device rather than a laptop simulator to properly demo the camera-to-cloud upload flow.

### 1. Firebase Setup (`google-services.json`)
Before building, Firebase must be configured for the physical app:
1. Go to your Firebase Console > Project Settings.
2. Under "Your apps", click **Add App** > **Android**.
3. Register the app with the exact package name found in `android/app/build.gradle.kts`:
   - **Android package name:** `com.auditgemma.auditgemma_mobile`
4. Download the `google-services.json` file.
5. Place this file exactly at: `android/app/google-services.json`.

*(Without this file, Firebase Auth and FCM will crash on a physical device).*

### 2. Configure the API Backend URL
The app needs to know where the FastAPI backend lives. By default, it looks at `10.0.2.2:8000` (which only works for Android emulators reading your laptop's localhost). 

For a physical device on the venue's Wi-Fi, you have two choices for the backend:
1. **The Cloud Run URL (Recommended):** If you deployed the backend to Cloud Run.
2. **Your Laptop's Local IP:** If you are running the backend locally on the venue's Wi-Fi network (e.g., `http://192.168.1.50:8000/api/v1`). 

*Note: The choice here mirrors the Ollama tradeoffs mentioned in the backend README. If your Cloud Run backend can't reach Ollama, but your laptop can, you must point the phone to your laptop's local IP.*

### 3. Build and Install
Connect your Android phone via USB. Ensure **Developer Options** and **USB Debugging** are enabled on the phone.

Build the APK, explicitly passing in the backend URL via `--dart-define`:

```bash
# Build the APK (using --debug so you don't need release signing keys setup yet)
flutter build apk --debug --dart-define=API_BASE_URL="https://YOUR-CLOUD-RUN-URL/api/v1"

# Or if using your local laptop IP:
# flutter build apk --debug --dart-define=API_BASE_URL="http://192.168.1.X:8000/api/v1"

# Install it directly to the connected device
flutter install
```

*(Alternatively, you can find the built file at `build/app/outputs/flutter-apk/app-debug.apk` and transfer/sideload it manually).*

> [!WARNING]
> **App Icon Updates (Android Cache)**: If you update the app icon, Android often aggressively caches the old icon on the home screen. **Do not panic** if you rebuild the app for demo day and still see the default Flutter logo. To fix this, you must **fully uninstall** the existing app from the device first, then install the fresh APK.

### Re-checking Network Config at the Venue
If you are using the "Laptop Local IP" approach, **remember that your IP address will change when you connect to the hackathon venue's Wi-Fi.** 
You MUST re-run the `flutter build apk` command with the new IP address on the morning of the demo and re-install the app.
