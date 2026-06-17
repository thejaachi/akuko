import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:akuko/features/subscriptions/data/services/paystack_service.dart';

/// Hosted Paystack checkout rendered in a WebView. Loads the server-issued
/// `authorizationUrl` and watches for navigation to the callback sentinel
/// ([PaystackService.callbackUrlPrefix]) to know the hosted flow finished.
///
/// It pops with:
///   * `true`  -> reached the callback (payment attempt finished; the caller
///                must still VERIFY server-side — never trust this as success).
///   * `false` -> the user backed out before completing.
///
/// The page deliberately knows nothing about payment success; confirmation is
/// done server-side via `verifyTransaction`.
class PaystackCheckoutPage extends StatefulWidget {
  const PaystackCheckoutPage({required this.authorizationUrl, super.key});

  final String authorizationUrl;

  @override
  State<PaystackCheckoutPage> createState() => _PaystackCheckoutPageState();
}

class _PaystackCheckoutPageState extends State<PaystackCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_isCallback(url)) {
              _complete();
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (_isCallback(request.url)) {
              _complete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  bool _isCallback(String url) =>
      url.startsWith(PaystackService.callbackUrlPrefix);

  void _complete() {
    if (_completed) return;
    _completed = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // A system back / dismiss pops with `null`, which the caller treats as an
    // aborted checkout — equivalent to the explicit `false` from the close
    // button. We therefore don't need to intercept pops.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
