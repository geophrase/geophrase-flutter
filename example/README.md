# Geophrase Flutter Example

A minimal Flutter application demonstrating how to integrate the `geophrase_flutter` SDK.

This example is configured to use `mode: 'server'`, so you only need your public **Key ID** — no secret API key. On completion it returns a secure `requestId` that your backend can exchange for the full address.

## 🚀 How to Run

### 1. Install Dependencies
Make sure you navigate into the `example` directory from the root of the repository before installing the packages:

```bash
cd example
flutter pub get
```

### 2. Add Your Key ID
The widget will not load without it. Create a key in your [Geophrase dashboard](https://geophrase.com/docs/api-keys), copy its 8-character **Key ID**, and replace the placeholder `apiKeyId` in `lib/main.dart`:

```dart
apiKeyId: 'YOUR_API_KEY_ID', // ← replace with your Key ID
```

### 3. Install iOS Pods
If you are testing on iOS, you must install the native CocoaPods:

```bash
cd ios
pod install
cd ..
```

### 4. Start the App
Ensure you have a simulator or a physical device connected, then run:

```bash
flutter run
```

## ⚙️ Testing Client Mode
If you want to test the full address resolution directly in the app:
1. Open `lib/main.dart`.
2. Change `mode: 'server'` to `mode: 'client'`.
3. Uncomment and add your `apiKey: 'YOUR_API_KEY'` (your **secret** key) to the `GeophraseConnect` widget. Your `apiKeyId` stays as-is — it is required in both modes.
4. Hot restart or rebuild the app.
