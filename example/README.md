# Geophrase Flutter Example

A minimal Flutter application demonstrating how to integrate the `geophrase_flutter` SDK.

This example is configured to use `mode: 'server'`, meaning you can run it immediately without needing to generate a Geophrase API key. It will return a secure `requestId` upon completion that your backend can exchange for the full address.

## 🚀 How to Run

### 1. Install Dependencies
Make sure you navigate into the `example` directory from the root of the repository before installing the packages:

```bash
cd example
flutter pub get
```

### 2. Install iOS Pods
If you are testing on iOS, you must install the native CocoaPods:

```bash
cd ios
pod install
cd ..
```

### 3. Start the App
Ensure you have a simulator or a physical device connected, then run:

```bash
flutter run
```

## ⚙️ Testing Client Mode
If you want to test the full address resolution directly in the app:
1. Open `lib/main.dart`.
2. Change `mode: 'server'` to `mode: 'client'`.
3. Uncomment and add your `apiKey: 'YOUR_API_KEY'` to the `GeophraseConnect` widget.
4. Hot restart or rebuild the app.
