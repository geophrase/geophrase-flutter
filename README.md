# geophrase_flutter

![pub package](https://img.shields.io/pub/v/geophrase_flutter)

Drop-in address selector for Flutter apps serving Indian customers. Captures perfectly structured addresses and GPS coordinates to reduce Return to Origin (RTO) costs.

📖 **[Full documentation and integration guide](https://geophrase.com/docs)**

*Also building for web or React Native? See [`@geophrase/core`](https://www.npmjs.com/package/@geophrase/core), [`@geophrase/react`](https://www.npmjs.com/package/@geophrase/react), and [`@geophrase/react-native`](https://www.npmjs.com/package/@geophrase/react-native).*

---

## Install

```bash
flutter pub add geophrase_flutter
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to accurately place the delivery pin.</string>
```

### Android

Add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Web

No extra configuration needed — the widget is rendered in a sandboxed iframe with `allow="geolocation"`.

---

## Quick Start

The snippet below uses `mode: 'server'`, so the only credential you need in the app is your public **Key ID** — no secret API key. Switching to client mode is a two-line change — see the inline comment.

> **Do not wrap `GeophraseConnect` in a `Scaffold` with an `AppBar`.** The widget renders its own header (title, back button, account indicator). Push it as a full-screen route and let it fill the screen.

```dart
import 'package:flutter/material.dart';
import 'package:geophrase_flutter/geophrase_flutter.dart';

void openGeophrase(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (routeContext) => GeophraseConnect(
        apiKeyId: 'YOUR_API_KEY_ID', // required in both modes — your public Key ID

        // 'server' (used here): widget returns a requestId. Pass it to your backend to resolve the address. No secret key needed.
        // 'client' (default):   widget resolves and returns the full address directly. Requires apiKey.
        mode: 'server',

        // apiKey: 'YOUR_API_KEY', // secret key, required when mode is 'client'
        theme: 'system',            // 'light' | 'dark' | 'system'
        orderId: 'ORD-98765',       // your internal reference ID
        phone: '9999999999',        // prefills the phone field

        onSuccess: (result) {
          // server mode → GeophraseRequestId. POST the requestId to your backend.
          // client mode → GeophraseAddress. Use directly.
          if (result is GeophraseRequestId) {
            debugPrint('Request ID: ${result.requestId}');
          } else if (result is GeophraseAddress) {
            debugPrint('Resolved: ${result.shortCode}');
          }
          Navigator.of(routeContext).pop();
        },
        onError: (error) => debugPrint('Geophrase error: ${error.message}'),
        onClose: () => Navigator.of(routeContext).pop(),
      ),
    ),
  );
}
```

Wire it up to any trigger — a button in your checkout step, an address picker tap, etc.:

```dart
ElevatedButton(
  onPressed: () => openGeophrase(context),
  child: const Text('Select delivery location'),
);
```

---

## Props

| Parameter | Type | Default | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `apiKeyId` | `String` | — | **Yes** | Your 8-character public [Key ID](https://geophrase.com/docs/api-keys) (shown in the dashboard). Required in **both** modes; identifies your account to the widget. |
| `mode` | `String` | `'client'` | No | `'client'` resolves the address in the app. `'server'` returns a `requestId` for your backend to exchange. |
| `apiKey` | `String` | — | **Conditional** | Your secret [Geophrase API key](https://geophrase.com/docs/api-keys) (the full key string). Required when `mode: 'client'`. |
| `theme` | `String` | `'system'` | No | `'light'`, `'dark'`, or `'system'` (follows OS preference). |
| `orderId` | `String` | — | No | Your internal reference ID for this session. |
| `phone` | `String` | — | No | Pre-fills the phone field with a 10-digit Indian mobile number. |
| `onSuccess` | `Function(dynamic)` | — | **Yes** | Receives a `GeophraseAddress` in client mode, or a `GeophraseRequestId` in server mode. |
| `onError` | `Function(GeophraseError)` | — | No | Fired on API or network errors. |
| `onClose` | `VoidCallback` | — | No | Fired when the user dismisses the widget without selecting an address. |

> Two distinct credentials: `apiKeyId` is your **public** Key ID (safe to ship in the app, required in both modes), while `apiKey` is your **secret** key (client mode only).

---

## Response payloads

### Client mode — `GeophraseAddress`

| Field | Type | Description |
| :--- | :--- | :--- |
| `shortCode` | `String` | Short alphanumeric code identifying the captured address. |
| `shortLink` | `String` | Short URL pointing to the captured address. |
| `qrCode` | `String` | URL to a QR code image encoding the short link. |
| `capturedAt` | `int` | Capture timestamp as milliseconds since the Unix epoch. |
| `orderId` | `String` | Merchant-supplied reference ID; empty string when `orderId` was not passed. |
| `address` | `GeophraseAddressDetails` | Structured address fields (see below). |
| `rawData` | `Map<String, dynamic>` | Unmodified API response. |

`GeophraseAddressDetails`:

| Field | Type |
| :--- | :--- |
| `city` | `String` |
| `state` | `String` |
| `digiPin` | `String` |
| `landmark` | `String` |
| `latitude` | `double` |
| `longitude` | `double` |
| `postalCode` | `int` |
| `addressType` | `String` |
| `addressLineOne` | `String` |
| `addressLineTwo` | `String` |
| `contactFullName` | `String` |
| `verifiedMobileNum` | `String` |

Example:

```json
{
  "short_code": "e6w9th",
  "short_link": "https://gphr.in/e6w9th",
  "qr_code": "https://storage.googleapis.com/geophrase/qr-codes/e6w9th.png",
  "captured_at": 1778485231452,
  "order_id": "ORD-8786",
  "address": {
    "city": "Mumbai",
    "state": "Maharashtra",
    "digi_pin": "172-P83-4648",
    "landmark": "Map: gphr.in/e6w9th",
    "latitude": 23.2510677,
    "longitude": 82.7746059,
    "postal_code": 781012,
    "address_type": "HOUSE",
    "address_line_one": "Flat B, 4th Floor",
    "address_line_two": "ABC Square Tower",
    "contact_full_name": "Ramesh",
    "verified_mobile_num": "9999999999"
  }
}
```

All fields are always present. `order_id` is an empty string when `orderId` was not passed. `landmark` and `address_line_two` may be empty strings. No field is ever `null`.

`rawData` holds the unmodified API response so you can read new fields before the SDK exposes them as typed getters.

### Server mode — `GeophraseRequestId`

```json
{ "requestId": "6cafc00f-30ff-48f8-97c2-61e3da8f0acf" }
```

Pass this `requestId` to your backend, where you can exchange it for the full address object using your Geophrase API key.

---

## Which mode should I use?

**Have a backend? Use `mode: 'server'`.** Your API key stays on your server. Combined with server IP whitelisting in the Geophrase dashboard, only requests from your own backend can use the key — the most secure configuration.

**No backend? Use `mode: 'client'` with strict restrictions.** The SDK automatically sends your app's Bundle Identifier (iOS) or Package Name (Android) with every request. Bind your API key to those in the Geophrase dashboard, and a key lifted from your binary is useless in a different app.

On Flutter Web, bundle/package restrictions don't apply — prefer `mode: 'server'` with origin restrictions set in the Geophrase dashboard.

---

## Additional information

For full documentation, advanced configuration, and dashboard access, visit [geophrase.com/docs](https://geophrase.com/docs). To report issues or request features, use the [GitHub issue tracker](https://github.com/geophrase/geophrase-flutter/issues).
