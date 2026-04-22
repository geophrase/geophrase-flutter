import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'geophrase_types.dart';

const String _defaultWidgetOrigin = 'https://connect.geophrase.com';
const String _defaultApiBase = 'https://api.geophrase.com';

class GeophraseConnect extends StatefulWidget {
  /// `'client'` (default) resolves the address in-app; `'server'` returns a
  /// token for your backend to exchange.
  final String mode;

  /// `'light'`, `'dark'`, or `'system'`.
  final String theme;

  /// Required when [mode] is `'client'`. Omit in server mode.
  final String? apiKey;

  /// Your internal reference ID; echoed back in the Geophrase dashboard.
  final String? orderId;

  /// Prefill the phone field to skip one step of OTP entry.
  final String? phone;

  /// Client mode receives a [GeophraseAddress]; server mode receives a [GeophraseToken].
  final void Function(dynamic result) onSuccess;

  final void Function(GeophraseError error)? onError;
  final VoidCallback? onClose;

  /// Undocumented override for staging/QA environments.
  final GeophraseEndpoints? endpoints;

  const GeophraseConnect({
    super.key,
    this.mode = 'client',
    this.theme = 'system',
    this.apiKey,
    required this.onSuccess,
    this.orderId,
    this.phone,
    this.onError,
    this.onClose,
    this.endpoints,
  });

  @override
  State<GeophraseConnect> createState() => _GeophraseConnectState();
}

class _GeophraseConnectState extends State<GeophraseConnect> {
  late final WebViewController _controller;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _hasGotFix = false;
  bool _isLoading = true;

  late final String _widgetOrigin;
  late final String _apiBase;

  @override
  void initState() {
    super.initState();

    _widgetOrigin = widget.endpoints?.widgetOrigin ?? _defaultWidgetOrigin;
    _apiBase = widget.endpoints?.apiBase ?? _defaultApiBase;

    // Soft validation — mirrors the React Native SDK. Avoid throwing so a
    // misconfigured prop can't crash the merchant's app.
    if (!['client', 'server'].contains(widget.mode)) {
      debugPrint("Geophrase Error: Invalid mode '${widget.mode}'. Expected 'client' or 'server'.");
    }
    if (widget.mode == 'client' && (widget.apiKey == null || widget.apiKey!.isEmpty)) {
      debugPrint("Geophrase Error: 'apiKey' is required when mode is 'client'.");
    }
    if (widget.mode == 'server' && widget.apiKey != null && widget.apiKey!.isNotEmpty) {
      debugPrint("Geophrase Warning: 'apiKey' is ignored when mode is 'server'. Ensure you are not exposing a secret key in your frontend.");
    }
    if (!['light', 'dark', 'system'].contains(widget.theme)) {
      debugPrint("Geophrase Warning: Invalid theme '${widget.theme}'. Falling back to default.");
    }

    final url = _buildWidgetUrl();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url == 'about:blank' || !request.url.startsWith('http')) {
              return NavigationDecision.navigate;
            }
            try {
              if (Uri.parse(request.url).origin == _widgetOrigin) {
                return NavigationDecision.navigate;
              }
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

  String _buildWidgetUrl() {
    final safeTheme = ['light', 'dark', 'system'].contains(widget.theme) ? widget.theme : 'system';
    final params = <String, String>{'platform': 'mobile', 'theme': safeTheme};
    if (widget.orderId != null) params['order-id'] = widget.orderId!;
    if (widget.phone != null) params['phone'] = widget.phone!;
    return Uri.parse(_widgetOrigin).replace(queryParameters: params).toString();
  }

  void _safeCall(Function? fn, [dynamic payload]) {
    if (fn == null) return;
    try {
      if (payload == null) {
        (fn as VoidCallback)();
      } else {
        fn(payload);
      }
    } catch (e, s) {
      debugPrint('Geophrase: merchant callback threw an error: $e\n$s');
    }
  }

  void _handleWebMessage(JavaScriptMessage message) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = data['type'];

    if (type == 'GEOPHRASE_CLOSE_WIDGET') {
      _stopLocationWatch();
      _safeCall(widget.onClose);
      return;
    }

    if (type == 'GEOPHRASE_REQUEST_LOCATION') {
      _handleLocationRequest();
      return;
    }

    if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
      _stopLocationWatch();

      if (widget.mode == 'server') {
        _safeCall(widget.onSuccess, GeophraseToken(token: data['token']?.toString() ?? ''));
      } else {
        _handleTokenResolution(data['token']?.toString() ?? '');
      }
    }
  }

  void _injectMessageToWeb(Map<String, dynamic> data) {
    final script = "window.postMessage(${jsonEncode(data)}, '*'); true;";
    _controller.runJavaScript(script);
  }

  void _stopLocationWatch() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _sendFix(Position position) {
    _hasGotFix = true;
    _injectMessageToWeb({
      'type': 'GEOPHRASE_LOCATION_RESULT',
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  // Progressive location strategy, mirroring what browsers and Google Maps
  // do on the web:
  //   1. `getCurrentPosition` with low accuracy → fast network fix (~1s).
  //   2. `getPositionStream` with high accuracy → refines the fix over time.
  //
  // DENIED is only signalled if *nothing* produces a fix.
  Future<void> _handleLocationRequest() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
      return;
    }

    _stopLocationWatch();
    _hasGotFix = false;

    // Fast initial fix (network-based, very quick). Silent on failure —
    // the high-accuracy watch may still succeed.
    unawaited(
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      ).then((pos) {
        if (mounted) _sendFix(pos);
      }).catchError((_) {}),
    );

    // Progressive high-accuracy updates.
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 30),
      ),
    ).listen(
      _sendFix,
      onError: (_) {
        if (!_hasGotFix) {
          _injectMessageToWeb({'type': 'GEOPHRASE_LOCATION_DENIED'});
        }
        _stopLocationWatch();
      },
    );
  }

  Future<void> _handleTokenResolution(String token) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final bundleId = packageInfo.packageName;

      final headers = <String, String>{
        'X-API-Key': widget.apiKey ?? '',
        'Content-Type': 'application/json',
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
          errorData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        _safeCall(widget.onError, GeophraseError(
          type: 'API_ERROR',
          status: response.statusCode,
          message: errorData['message']?.toString() ?? 'Geophrase API error (${response.statusCode})',
        ));
        return;
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      _safeCall(widget.onSuccess, GeophraseAddress.fromJson(responseData));
    } on TimeoutException {
      _safeCall(widget.onError, GeophraseError(
        type: 'NETWORK_ERROR',
        message: 'Geophrase API request timed out',
      ));
    } catch (error) {
      _safeCall(widget.onError, GeophraseError(
        type: 'NETWORK_ERROR',
        message: error.toString(),
      ));
    }
  }

  @override
  void dispose() {
    _stopLocationWatch();
    _controller.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve theme against OS preference so the native background matches the
    // widget's first paint (prevents a white flash on dark-OS when theme is
    // 'system' or unspecified).
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedDark = widget.theme == 'dark' ||
        (widget.theme != 'light' && systemBrightness == Brightness.dark);
    final bgColor = resolvedDark ? const Color(0xFF121212) : Colors.white;
    final spinnerColor = resolvedDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: bgColor,
                child: Center(child: CircularProgressIndicator(color: spinnerColor)),
              ),
          ],
        ),
      ),
    );
  }
}
