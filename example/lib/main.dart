import 'package:flutter/material.dart';
import 'package:geophrase_flutter/geophrase_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geophrase Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const CheckoutScreen(),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  GeophraseAddress? _address;

  void _openGeophrase() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => GeophraseConnect(
          // 'server': widget returns a short-lived token — pass it to your
          //           backend to exchange for the full address. No apiKey needed.
          // 'client': widget resolves and returns the full address directly.
          //           Requires apiKey.
          mode: 'server',

          // apiKey: 'YOUR_API_KEY', // required when mode is 'client'
          theme: 'system',          // optional — 'light' | 'dark' | 'system'
          orderId: 'ORD-98765',     // optional — your internal reference ID
          phone: '9999999999',      // optional — prefills the phone field

          onSuccess: (result) {
            Navigator.of(routeContext).pop();
            if (result is GeophraseAddress) {
              // client mode — full address returned directly
              setState(() => _address = result);
            } else if (result is GeophraseToken) {
              // server mode — POST result.token to your backend to resolve
              debugPrint('Token: ${result.token}');
            }
          },
          onError: (error) => debugPrint('Geophrase error: ${error.message}'),
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_address != null) ...[
              Text(_address!.contactFullName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${_address!.addressLineOne}, ${_address!.addressLineTwo}'),
              Text('${_address!.city}, ${_address!.state} ${_address!.postalCode}'),
              Text(_address!.phrase, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
            ],
            FilledButton(
              onPressed: _openGeophrase,
              child: Text(_address == null ? 'Select delivery address' : 'Change address'),
            ),
          ],
        ),
      ),
    );
  }
}
