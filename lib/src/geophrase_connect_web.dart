// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
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
  late html.IFrameElement _iframeElement;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  static const String _apiBase = 'https://api.geophrase.com';

  @override
  void initState() {
    super.initState();

    String url = 'https://connect.geophrase.com?api-key=${widget.apiKey}';
    if (widget.orderId != null) url += '&order-id=${widget.orderId}';
    if (widget.phone != null) url += '&phone=${widget.phone}';

    // 1. Create a unique ID for the iframe
    _viewType = 'geophrase-iframe-${DateTime.now().millisecondsSinceEpoch}';

    // 2. Build the HTML Iframe directly
    _iframeElement = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'geolocation'; // CRITICAL: Lets Next.js ask for GPS directly!

    // 3. Register the iframe with Flutter's Web Engine
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
          (int viewId) => _iframeElement,
    );

    // 4. Listen to standard window.postMessage events
    _messageSubscription = html.window.onMessage.listen(_handleWebMessage);
  }

  void _handleWebMessage(html.MessageEvent event) {
    try {
      // Data might be passed as a Map or a String depending on the browser
      final dynamic rawData = event.data;
      Map<String, dynamic> data;

      if (rawData is String) {
        data = jsonDecode(rawData);
      } else {
        data = Map<String, dynamic>.from(rawData);
      }

      final type = data['type'];

      if (type == 'GEOPHRASE_CLOSE_WIDGET') {
        widget.onClose?.call();
      } else if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
        widget.onClose?.call();
        _handleTokenResolution(data['token']);
      }
      // Note: We ignore GEOPHRASE_REQUEST_LOCATION because Next.js
      // handles the navigator.geolocation API directly on the web!
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
      );

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