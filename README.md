# Geophrase Flutter SDK

![pub package](https://img.shields.io/pub/v/geophrase_flutter)

The official Flutter SDK for Geophrase Connect. A drop-in UI widget that utilizes specialized software logic to parse and optimize unstructured regional addresses.

## 🧠 How It Works

1. You open the Geophrase widget in your app.
2. The user selects their precise location on the map.
3. The SDK resolves it into a structured address via Geophrase APIs securely.
4. You receive the final address object in the `onSuccess` callback.

**No backend integration required.**

## Setup Requirements

Because this SDK requests native GPS coordinates, you **must** declare location permissions in your host application's native configuration files. Failing to do this will cause the operating system to block the widget's location features.

### iOS
Add this key-value pair to your `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to accurately verify your delivery address.</string>
```

### Android
Add this permission to your `android/app/src/main/AndroidManifest.xml` (within the `<manifest>` tag):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## Usage

Integrating the Geophrase widget into your checkout or profile flow is straightforward:

```dart
import 'package:flutter/material.dart';
import 'package:geophrase_flutter/geophrase_flutter.dart';

class AddressPickerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Address')),
      body: GeophraseConnect(
        apiKey: 'YOUR_PUBLIC_API_KEY', // Replace with your Geophrase API Key
        orderId: 'ORDER_123',          // Optional: Track specific orders
        onSuccess: (GeophraseAddress address) {
          // Triggered when the address is successfully resolved
          print('Resolved: ${address.phrase}');
          print('Metadata: ${address.rawData}');
        },
        onError: (GeophraseError error) {
          // Triggered on API or Network failures
          print('Error: ${error.message}');
        },
        onClose: () {
          // Triggered when the user exits the widget
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
```

## 📦 Data Structures

### Example Success Response (`onSuccess`)
The SDK returns a `GeophraseAddress` object containing the unique phrase and the raw geographic data.

```json
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
```

### Example Error Response (`onError`)
If a network issue or validation failure occurs, the SDK returns a `GeophraseError` object.

```json
{
  "type": "API_ERROR", 
  "message": "Geophrase API error (401)",
  "status": 401
}
```

## ⚠️ Common Issues

**Location not working or timing out?**
- Ensure location permissions are added to your `Info.plist` and `AndroidManifest.xml`.
- Make sure physical location services are enabled on the test device.
- *Note: For accurate GPS testing, use a real physical device instead of a simulator/emulator.*

**WebView not loading?**
- Check your internet connection.
- Ensure your iOS deployment target is modern enough to support `webview_flutter`.

## Additional Information

For full documentation and advanced configuration, visit [business.geophrase.com/docs](https://business.geophrase.com/docs). To report issues or request features, please use our [GitHub issue tracker](https://github.com/geophrase/geophrase-flutter/issues).