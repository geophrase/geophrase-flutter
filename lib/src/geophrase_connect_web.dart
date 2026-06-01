// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'geophrase_types.dart';

const String _defaultWidgetOrigin = 'https://connect.geophrase.com';
const String _defaultApiBase = 'https://api.geophrase.com';

class GeophraseConnect extends StatefulWidget {
  final String apiKeyId;
  final String mode;
  final String theme;
  final String? apiKey;
  final String? orderId;
  final String? phone;
  final void Function(dynamic result) onSuccess;
  final void Function(GeophraseError error)? onError;
  final VoidCallback? onClose;
  final GeophraseEndpoints? endpoints;

  const GeophraseConnect({
    super.key,
    required this.apiKeyId,
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
  late String _viewType;
  late web.HTMLIFrameElement _iframeElement;
  StreamSubscription<web.MessageEvent>? _messageSubscription;

  late final String _widgetOrigin;
  late final String _apiBase;

  @override
  void initState() {
    super.initState();

    _widgetOrigin = widget.endpoints?.widgetOrigin ?? _defaultWidgetOrigin;
    _apiBase = widget.endpoints?.apiBase ?? _defaultApiBase;

    // Soft validation — mirrors the JS core behavior of warning rather than
    // throwing on misconfiguration that's not strictly fatal.
    if (!['client', 'server'].contains(widget.mode)) {
      debugPrint("Geophrase Error: Invalid mode '${widget.mode}'. Expected 'client' or 'server'.");
    }
    if (widget.apiKeyId.isEmpty) {
      debugPrint("Geophrase Error: 'apiKeyId' is required.");
    } else if (widget.apiKeyId.length != 8) {
      debugPrint("Geophrase Error: 'apiKeyId' must be an 8-character string.");
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

    _viewType = 'geophrase-iframe-${DateTime.now().microsecondsSinceEpoch}';

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

  String _buildWidgetUrl() {
    final safeTheme = ['light', 'dark', 'system'].contains(widget.theme) ? widget.theme : null;
    final params = <String, String>{'key-id': widget.apiKeyId};
    if (widget.phone != null) params['phone'] = widget.phone!;
    if (safeTheme != null) params['theme'] = safeTheme;
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

  void _handleWebMessage(web.MessageEvent event) {
    if (event.origin != _widgetOrigin) return;

    Map<String, dynamic> data;
    try {
      final dynamic rawData = event.data.dartify();
      if (rawData is String) {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        return;
      }
    } catch (_) {
      return;
    }

    final type = data['type'];

    if (type == 'GEOPHRASE_CLOSE_WIDGET') {
      _safeCall(widget.onClose);
      return;
    }

    if (type == 'GEOPHRASE_RESOLUTION_TOKEN') {
      final requestId = data['requestId']?.toString() ?? '';

      if (widget.mode == 'server') {
        _safeCall(widget.onSuccess, GeophraseRequestId(requestId: requestId));
      } else {
        _handleRequestIdResolution(requestId);
      }
    }
  }

  Future<void> _handleRequestIdResolution(String requestId) async {
    try {
      final payload = <String, dynamic>{'request_id': requestId};
      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        payload['order_id'] = widget.orderId!;
      }

      final response = await http.post(
        Uri.parse('$_apiBase/business/resolve/'),
        headers: {
          'X-API-Key': widget.apiKey ?? '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
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
    _messageSubscription?.cancel();
    _iframeElement.removeAttribute('src');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedDark = widget.theme == 'dark' ||
        (widget.theme != 'light' && systemBrightness == Brightness.dark);
    final bgColor = resolvedDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: HtmlElementView(viewType: _viewType),
    );
  }
}
