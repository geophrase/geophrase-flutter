# geophrase_flutter

![pub package](https://img.shields.io/pub/v/geophrase_flutter)

Drop-in address selector for Flutter apps serving Indian customers. Captures perfectly structured addresses and GPS coordinates to reduce Return to Origin (RTO) costs.

📖 **[Full documentation and integration guide](https://business.geophrase.com/docs)**

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

The snippet below uses `mode: 'server'` so you can drop it into your app and see the widget **without creating an API key first**. Switching to client mode is a two-line change — see the inline comment.

```dart
import 'package:flutter/material.dart';
import 'package:geophrase_flutter/geophrase_flutter.dart';

class Checkout extends StatelessWidget {
  const Checkout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Delivery Location')),
      body: GeophraseConnect(
        // 'server' (used here): widget returns a token. Pass it to your backend to resolve the address. No apiKey needed.
        // 'client' (default):   widget resolves and returns the full address directly. Requires apiKey.
        mode: 'server',

        // apiKey: 'YOUR_API_KEY', // required when mode is 'client'
        theme: 'system',            // 'light' | 'dark' | 'system'
        orderId: 'ORD-98765',       // your internal reference ID
        phone: '9999999999',        // prefills the phone field

        onSuccess: (result) {
          // server mode → GeophraseToken. POST the token to your backend.
          // client mode → GeophraseAddress. Use directly.
          if (result is GeophraseToken) {
            debugPrint('Token: ${result.token}');
          } else if (result is GeophraseAddress) {
            debugPrint('Resolved: ${result.phrase}');
          }
          Navigator.of(context).pop();
        },
        onError: (error) => debugPrint('Geophrase error: ${error.message}'),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
```

Open it from wherever you'd like (button press, checkout step, etc.):

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const Checkout()),
);
```

---

## Props

| Parameter | Type | Default | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| `mode` | `String` | `'client'` | No | `'client'` resolves the address in the app. `'server'` returns a token for your backend to exchange. |
| `apiKey` | `String` | — | **Conditional** | Your [Geophrase API key](https://business.geophrase.com/docs/api-keys). Required when `mode: 'client'`. |
| `theme` | `String` | `'system'` | No | `'light'`, `'dark'`, or `'system'` (follows OS preference). |
| `orderId` | `String` | — | No | Your internal reference ID for this session. |
| `phone` | `String` | — | No | Pre-fills the phone field with a 10-digit Indian mobile number. |
| `onSuccess` | `Function(dynamic)` | — | **Yes** | Receives a `GeophraseAddress` in client mode, or a `GeophraseToken` in server mode. |
| `onError` | `Function(GeophraseError)` | — | No | Fired on API or network errors. |
| `onClose` | `VoidCallback` | — | No | Fired when the user dismisses the widget without selecting an address. |

---

## Response payloads

### Client mode — `GeophraseAddress`

| Field | Type |
| :--- | :--- |
| `phrase` | `String` |
| `verifiedAccountMobileNum` | `String` |
| `addressType` | `String` |
| `contactFullName` | `String` |
| `contactMobileNum` | `String` |
| `addressLineOne` | `String` |
| `addressLineTwo` | `String` |
| `landmark` | `String` |
| `city` | `String` |
| `state` | `String` |
| `postalCode` | `int` |
| `latitude` | `double` |
| `longitude` | `double` |
| `digiPin` | `String` |
| `qrCode` | `String` |
| `rawData` | `Map<String, dynamic>` |

Example:

```json
{
  "phrase": "eid-hiu-sac",
  "verified_account_mobile_num": "9999999999",
  "address_type": "OFFICE",
  "contact_full_name": "Rohan",
  "contact_mobile_num": "9999999999",
  "address_line_one": "Floor 99",
  "address_line_two": "GTB Building",
  "landmark": "Map: gphr.in/eid-hiu-sac",
  "city": "Delhi",
  "state": "Delhi",
  "postal_code": 110007,
  "latitude": 16.241303391104953,
  "longitude": 99.7836155238037,
  "digi_pin": "202-P85-M87C",
  "qr_code": "https://storage.googleapis.com/geophrase/qr-codes/eid-hiu-sac.png"
}
```

`rawData` holds the unmodified API response so you can read new fields before the SDK exposes them as typed getters.

### Server mode — `GeophraseToken`

```json
{ "token": "d098dc34-8995-4c07-b10c-1abcade94651" }
```

Pass this token to your backend, where you can exchange it for the full address object using your Geophrase API key.

---

## Which mode should I use?

**Have a backend? Use `mode: 'server'`.** Your API key stays on your server. Combined with server IP whitelisting in the Geophrase dashboard, only requests from your own backend can use the key — the most secure configuration.

**No backend? Use `mode: 'client'` with strict restrictions.** The SDK automatically sends your app's Bundle Identifier (iOS) or Package Name (Android) with every request. Bind your API key to those in the Geophrase dashboard, and a key lifted from your binary is useless in a different app.

On Flutter Web, bundle/package restrictions don't apply — prefer `mode: 'server'` with origin restrictions set in the Geophrase dashboard.

---

## Additional information

For full documentation, advanced configuration, and dashboard access, visit [business.geophrase.com/docs](https://business.geophrase.com/docs). To report issues or request features, use the [GitHub issue tracker](https://github.com/geophrase/geophrase-flutter/issues).
