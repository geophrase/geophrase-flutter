import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'geophrase_types.dart';

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
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  static const String _apiBase = 'https://api.geophrase.com';
  static const String _widgetOrigin = 'https://connect.geophrase.com';

  @override
  void initState() {
    super.initState();

    // 1. Build the Target URL with strict encoding
    String url = '$_widgetOrigin?api-key=${Uri.encodeComponent(widget.apiKey)}&platform=mobile';
    if (widget.orderId != null) url += '&order-id=${Uri.encodeComponent(widget.orderId!)}';
    if (widget.phone != null) url += '&phone=${Uri.encodeComponent(widget.phone!)}';

    // 2. Initialize the WebView Engine with Security and Loading States
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            try {
              final uri = Uri.parse(request.url);
              if (uri.origin == _widgetOrigin) {
                return NavigationDecision.navigate;
              }
            } catch (_) {}
            return NavigationDecision.prevent; // Block hijacked redirects
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'GeophraseFlutter',
        onMessageReceived: _handleWebMessage,
      )
      ..loadRequest(Uri.parse(url));
  }

  void _handleWebMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message);
      final type = data['type'];

      if (type == 'GEOPHRASE_CLOSE_WIDGET') {
        _positionStreamSubscription?.cancel(); // Kill GPS on close
        widget.onClose?.call();
      } else if (type == 'GEOPHRASE_REQUEST_LOCATION') {
        _handleLocationRequest();
      } else if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
        _positionStreamSubscription?.cancel(); // Kill GPS on resolution
        widget.onClose?.call();
        _handleTokenResolution(data['token']);
      }
    } catch (e) {
      debugPrint('Geophrase non-JSON message ignored.');
    }
  }

  void _injectMessageToWeb(Map<String, dynamic> data) {
    final script = "window.postMessage(${jsonEncode(data)}, '*'); true;";
    _controller.runJavaScript(script);
  }

  Future<void> _handleLocationRequest() async {
    bool serviceEnabled;
    LocationPermission permission;

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

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 30),
    );

    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        _injectMessageToWeb({
          'type': 'GEOPHRASE_LOCATION_RESULT',
          'lat': position.latitude,
          'lng': position.longitude,
        });
      },
      onError: (error) {
        _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
      },
    );
  }

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

      // 3. Implemented the 15-second timeout constraint
      final response = await http.post(
        Uri.parse('$_apiBase/business/resolve/'),
        headers: headers,
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 15));

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

    } on TimeoutException {
      widget.onError?.call(GeophraseError(
        type: 'NETWORK_ERROR',
        message: 'Geophrase API request timed out',
      ));
    } catch (error) {
      widget.onError?.call(GeophraseError(
        type: 'NETWORK_ERROR',
        message: error.toString(),
      ));
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}