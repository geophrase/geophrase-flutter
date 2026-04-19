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
  final String mode;
  final String theme;
  final String? apiKey;
  final String? orderId;
  final String? phone;
  final Function(dynamic) onSuccess;
  final Function(GeophraseError)? onError;
  final VoidCallback? onClose;

  const GeophraseConnect({
    Key? key,
    this.mode = 'client',
    this.theme = 'system',
    this.apiKey,
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

    // 1. Strict Validation
    if (!['client', 'server'].contains(widget.mode)) {
      throw ArgumentError("Geophrase Error: Invalid mode '${widget.mode}'. Expected 'client' or 'server'.");
    }
    if (widget.mode == 'client' && (widget.apiKey == null || widget.apiKey!.isEmpty)) {
      throw ArgumentError("Geophrase Error: 'apiKey' is required when mode is 'client'.");
    }
    if (widget.mode == 'server' && widget.apiKey != null && widget.apiKey!.isNotEmpty) {
      debugPrint("Geophrase Warning: 'apiKey' is ignored when mode is 'server'. Ensure you are not exposing a secure key in your frontend.");
    }

    String safeTheme = widget.theme;
    if (!['light', 'dark', 'system'].contains(widget.theme)) {
      debugPrint("Geophrase Warning: Invalid theme '${widget.theme}'. Falling back to 'system'.");
      safeTheme = 'system';
    }

    // 2. Build Secure URL
    String url = '$_widgetOrigin?platform=mobile';
    if (widget.orderId != null) url += '&order-id=${Uri.encodeComponent(widget.orderId!)}';
    if (widget.phone != null) url += '&phone=${Uri.encodeComponent(widget.phone!)}';
    url += '&theme=${Uri.encodeComponent(safeTheme)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            try {
              if (request.url == 'about:blank') return NavigationDecision.navigate;
              final uri = Uri.parse(request.url);
              if (uri.origin == _widgetOrigin) return NavigationDecision.navigate;
            } catch (_) {}
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
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
        _positionStreamSubscription?.cancel();
        widget.onClose?.call();
      } else if (type == 'GEOPHRASE_REQUEST_LOCATION') {
        _handleLocationRequest();
      } else if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
        _positionStreamSubscription?.cancel();
        widget.onClose?.call();

        if (widget.mode == 'server') {
          widget.onSuccess(GeophraseToken(token: data['token']));
        } else {
          _handleTokenResolution(data['token']);
        }
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
    final activeApiKey = widget.apiKey ?? '';
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String bundleId = packageInfo.packageName;

      Map<String, String> headers = {
        "X-API-Key": activeApiKey,
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
    _controller.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.theme == 'dark' ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                    color: widget.theme == 'dark' ? Colors.white : Colors.black
                ),
              ),
          ],
        ),
      ),
    );
  }
}