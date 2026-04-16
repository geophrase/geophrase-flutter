// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
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
  late String _viewType;
  late web.HTMLIFrameElement _iframeElement;
  StreamSubscription<web.MessageEvent>? _messageSubscription;
  static const String _apiBase = 'https://api.geophrase.com';
  static const String _widgetOrigin = 'https://connect.geophrase.com';

  @override
  void initState() {
    super.initState();

    String url = '$_widgetOrigin?api-key=${Uri.encodeComponent(widget.apiKey)}';
    if (widget.orderId != null) url += '&order-id=${Uri.encodeComponent(widget.orderId!)}';
    if (widget.phone != null) url += '&phone=${Uri.encodeComponent(widget.phone!)}';

    _viewType = 'geophrase-iframe-${DateTime.now().millisecondsSinceEpoch}';

    _iframeElement = web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'geolocation';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
          (int viewId) => _iframeElement,
    );

    _messageSubscription = web.window.onMessage.listen(_handleWebMessage);
  }

  void _handleWebMessage(web.MessageEvent event) {
    if (event.origin != _widgetOrigin) return;

    try {
      final dynamic rawData = event.data.dartify();
      Map<String, dynamic> data;

      if (rawData is String) {
        data = jsonDecode(rawData);
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        return;
      }

      final type = data['type'];

      if (type == 'GEOPHRASE_CLOSE_WIDGET') {
        widget.onClose?.call();
      } else if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
        widget.onClose?.call();
        _handleTokenResolution(data['token']);
      }
    } catch (e) {
      // Ignore random browser extension messages
    }
  }

  Future<void> _handleTokenResolution(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/business/resolve/'),
        headers: {
          "X-API-Key": widget.apiKey,
          "Content-Type": "application/json",
        },
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
          message: errorData['message'] ?? 'API error (${response.statusCode})',
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
    _messageSubscription?.cancel();

    // STRICT FIX: Kill the iframe session completely on teardown
    // Prevents ghost OTP triggers if the DOM node isn't immediately garbage collected
    _iframeElement.removeAttribute('src');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: HtmlElementView(viewType: _viewType),
    );
  }
}