import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

// 1. Define your strict Types
class GeophraseAddress {
  final String phrase;
  final Map<String, dynamic> rawData;
  GeophraseAddress({required this.phrase, required this.rawData});
}

class GeophraseError {
  final String type;
  final String message;
  final int? status;
  GeophraseError({required this.type, required this.message, this.status});
}

// 2. The Core Widget
class GeophraseConnect extends StatefulWidget {
  final String apiKey;
  final String? orderId;
  final String? phone;
  final Function(GeophraseAddress) onSuccess;
  final Function(GeophraseError)? onError;
  final VoidCallback? onClose;

  const GeophraseConnect({
    Key? key,
    required this.apiKey,
    required this.onSuccess,
    this.orderId,
    this.phone,
    this.onError,
    this.onClose,
  }) : super(key: key);

  @override
  State<GeophraseConnect> createState() => _GeophraseConnectState();
}

class _GeophraseConnectState extends State<GeophraseConnect> {
  late final WebViewController _controller;
  static const String _apiBase = 'https://api.geophrase.com';

  @override
  void initState() {
    super.initState();

    // Build the Target URL
    String url = 'https://connect.geophrase.com?api-key=${widget.apiKey}&platform=mobile';
    if (widget.orderId != null) url += '&order-id=${widget.orderId}';
    if (widget.phone != null) url += '&phone=${widget.phone}';

    // Initialize the WebView Engine
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'GeophraseFlutter',
        onMessageReceived: _handleWebMessage,
      )
      ..loadRequest(Uri.parse(url));
  }

  // 3. The Message Handler
  void _handleWebMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message);
      final type = data['type'];

      if (type == 'GEOPHRASE_CLOSE_WIDGET') {
        widget.onClose?.call();
      } else if (type == 'GEOPHRASE_REQUEST_LOCATION') {
        _handleLocationRequest();
      } else if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
        widget.onClose?.call(); // Hide the modal during resolution
        _handleTokenResolution(data['token']);
      }
    } catch (e) {
      // Ignore random non-JSON messages
      debugPrint('Geophrase non-JSON message ignored.');
    }
  }

  // Helper to send data BACK to the Next.js widget
  void _injectMessageToWeb(Map<String, dynamic> data) {
    final script = "window.postMessage(${jsonEncode(data)}, '*'); true;";
    _controller.runJavaScript(script);
  }

  // 4. Handle GPS Native Permissions and Coordinates
  Future<void> _handleLocationRequest() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
      return;
    }

    // Permissions are granted, fetch the position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _injectMessageToWeb({
        'type': 'GEOPHRASE_LOCATION_RESULT',
        'lat': position.latitude,
        'lng': position.longitude,
      });
    } catch (e) {
      _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
    }
  }

  // 5. Resolve Token with Native Headers
  Future<void> _handleTokenResolution(String token) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String bundleId = packageInfo.packageName;

      Map<String, String> headers = {
        "X-API-Key": widget.apiKey,
        "Content-Type": "application/json"
      };

      if (Platform.isIOS) {
        headers['X-iOS-Bundle-Identifier'] = bundleId;
      } else if (Platform.isAndroid) {
        headers['X-Android-Package'] = bundleId;
      }

      final response = await http.post(
        Uri.parse('$_apiBase/business/resolve/'),
        headers: headers,
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (_) {}

        widget.onError?.call(GeophraseError(
          type: 'API_ERROR',
          status: response.statusCode,
          message: errorData['message'] ?? 'Geophrase API error (${response.statusCode})',
        ));
        return;
      }

      final responseData = jsonDecode(response.body);
      widget.onSuccess(GeophraseAddress(
        phrase: responseData['phrase'] ?? '',
        rawData: responseData,
      ));

    } catch (error) {
      widget.onError?.call(GeophraseError(
        type: 'NETWORK_ERROR',
        message: error.toString(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render the View
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false, // Lets the map stretch to the bottom edge
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}