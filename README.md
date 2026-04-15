# Geophrase Flutter SDK

The official Flutter SDK for Geophrase Connect. A drop-in UI widget that utilizes specialized software logic to parse and optimize unstructured regional addresses.

## Features

* **Backend-less Integration:** Resolve complete, structured addresses directly on the client.
* **Native GPS Handling:** Automatically prompts users for location permissions to verify coordinates via the mobile device.
* **Drop-in UI:** An optimized WebView flow that bridges native hardware with the Geophrase widget.

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

## Additional Information

For full documentation and advanced configuration, visit [business.geophrase.com/docs](https://business.geophrase.com/docs). To report issues or request features, please use our [GitHub issue tracker](https://github.com/geophrase/geophrase-flutter/issues).