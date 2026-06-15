import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Opens real Paystack checkout in a WebView; returns reference on success.
class PaystackCheckoutScreen extends StatefulWidget {
  const PaystackCheckoutScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.amountLabel,
  });

  final String authorizationUrl;
  final String reference;
  final String amountLabel;

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _completed = false;

  String get _callbackHost {
    try {
      return Uri.parse(ApiConfig.baseUrl).host;
    } catch (_) {
      return '';
    }
  }

  void _finish(String ref) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.pop(context, ref);
  }

  bool _isSuccessRedirect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.path.contains('/paystack/callback')) return true;
    if (url.contains('standard.paystack.co/close')) return true;
    if (url.contains('checkout.paystack.com/close')) return true;
    final host = _callbackHost;
    if (host.isNotEmpty && uri.host == host && (uri.queryParameters.containsKey('reference') || uri.queryParameters.containsKey('trxref'))) {
      return true;
    }
    return false;
  }

  String _refFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters['reference'] ?? uri.queryParameters['trxref'] ?? widget.reference;
  }

  @override
  void initState() {
    super.initState();
    final valid = widget.authorizationUrl.startsWith('https://checkout.paystack.com/') && widget.authorizationUrl.length > 35;
    if (!valid) {
      _error = 'Could not start Paystack. Check that your phone can reach the backend at ${ApiConfig.baseUrl}';
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _loading = true; _error = null; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (err.isForMainFrame != true || _completed) return;
            final desc = err.description.toLowerCase();
            if (desc.contains('404') && widget.authorizationUrl.contains('checkout.paystack.com')) {
              return;
            }
            if (mounted) {
              setState(() => _error = err.description.isNotEmpty ? err.description : 'Failed to load checkout');
            }
          },
          onNavigationRequest: (req) {
            if (_isSuccessRedirect(req.url)) {
              _finish(_refFromUrl(req.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && _isSuccessRedirect(url)) {
              _finish(_refFromUrl(url));
            }
          },
        ),
      );
    if (_error == null) {
      _controller.loadRequest(Uri.parse(widget.authorizationUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C3F7),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paystack Checkout', style: AppTheme.sans(14, color: Colors.white, weight: FontWeight.w600)),
            Text(widget.amountLabel, style: AppTheme.sans(11, color: Colors.white70)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () => _finish(widget.reference),
            child: Text('Done', style: AppTheme.sans(13, color: Colors.white, weight: FontWeight.w600)),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.redDark),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: AppTheme.sans(14, color: AppColors.mid)),
                    const SizedBox(height: 8),
                    Text('If you already paid, tap "I\'ve paid" to verify.', textAlign: TextAlign.center, style: AppTheme.sans(12, color: AppColors.soft)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => _finish(widget.reference), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C3F7)), child: const Text("I've paid — verify")),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator(color: Color(0xFF00C3F7))),
              ],
            ),
    );
  }
}
