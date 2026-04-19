# Geophrase Flutter SDK

![pub package](https://img.shields.io/pub/v/geophrase_flutter)

The official Flutter SDK for Geophrase Connect. A drop-in UI widget that utilizes specialized software logic to parse and optimize unstructured regional addresses.

## 🧠 How It Works

1. You open the Geophrase widget in your app.
2. The user selects their precise location on the map.
3. The SDK resolves the token securely.
4. You receive the final address object in the `onSuccess` callback.

---

## Setup Requirements

Because this SDK requests native GPS coordinates, you **must** declare location permissions in your host application's native configuration files. Failing to do this will cause the operating system to block the widget's location features.

### iOS
Add this key-value pair to your `ios/Runner/Info.plist`:
~~~xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to accurately verify your delivery address.</string>
~~~

### Android
Add this permission to your `android/app/src/main/AndroidManifest.xml` (within the `<manifest>` tag):
~~~xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
~~~

---

## Usage

Integrating the Geophrase widget into your checkout or profile flow is straightforward:

~~~dart
import 'package:flutter/material.dart';
import 'package:geophrase_flutter/geophrase_flutter.dart';

class AddressPickerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Address')),
      body: GeophraseConnect(
        mode: 'client',        // 'client' (default) or 'server'
        theme: 'system',       // 'light', 'dark', or 'system'
        apiKey: 'YOUR_API_KEY', // Required if mode is 'client'
        orderId: 'ORDER_123',  // Optional
        onSuccess: (dynamic result) {
          // Route based on what mode you configured
          if (result is GeophraseAddress) {
            print('Resolved Address: ${result.phrase}');
            print('Metadata: ${result.rawData}');
          } else if (result is GeophraseToken) {
            print('Secure Token: ${result.token}');
            // Pass this token to your backend to resolve
          }
        },
        onError: (GeophraseError error) {
          print('Error: ${error.message}');
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
~~~

---

## ⚙️ Configuration Options

| Parameter | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `mode` | `String` | No | `'client'` (default) or `'server'`. Determines architectural flow. |
| `theme` | `String` | No | `'light'`, `'dark'`, or `'system'`. Controls WebView background. |
| `apiKey` | `String` | **Cond.** | Your API Key. **Required if `mode` is `'client'`.** Omit for server mode. |
| `orderId` | `String` | No | Your internal tracking ID for the order/session. |
| `phone` | `String` | No | Prefills the user's phone number in the widget. |
| `onSuccess` | `function` | **Yes** | Returns `GeophraseAddress` (`client`) or `GeophraseToken` (`server`). |
| `onError` | `function` | No | Callback fired if network or validation errors occur. |
| `onClose` | `function` | No | Callback fired when the user manually closes the widget. |

---

## 📦 Data Structures

### 1. Client Mode Payload (Default)
When `mode='client'`, the SDK resolves the full geographic data directly:
~~~json
{
  "phrase": "blue-tiger-lake",
  "rawData": {
    "addressLine1": "House No 12, GS Road",
    "city": "Guwahati",
    "state": "Assam",
    "postalCode": "781005",
    "latitude": 26.1445,
    "longitude": 91.7362
  }
}
~~~

### 2. Server Mode Payload (Token Exchange Flow)
When `mode='server'`, the SDK safely halts before exposing API logic to the frontend and returns a secure token:
~~~json
{
  "token": "gphr_tok_5f8a9b2c1d4e..."
}
~~~

---

## 🔒 Security Note

**The Client-Side Flow (`mode='client'`):**
The `apiKey` used in the frontend configuration is your Geophrase API Key. Because mobile application code can be reverse-engineered, you **must** actively protect your keys from unauthorized use. In your Geophrase Business Dashboard, generate a uniquely restricted API Key specifically bound to your app's Bundle Identifier (`com.yourapp.bundle`) or Android Package Name.

**The Server-Side Flow (`mode='server'`):**
While we use strict bundle/package restrictions to protect your API keys in client mode, the absolute best practice—if your mobile app communicates with a backend—is to keep your API keys entirely out of the application binary. By using Server Mode, you omit the `apiKey` prop completely. The SDK returns a secure token to the app, which you then safely resolve from your own backend server.

---

## Additional Information

For full documentation and advanced configuration, visit [business.geophrase.com/docs](https://business.geophrase.com/docs). To report issues or request features, please use our [GitHub issue tracker](https://github.com/geophrase/geophrase-flutter/issues).