import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for the Privacy Policy and Support pages. English UI, back
/// button, loading indicator, error handling and (optionally) a forced white
/// background for the Privacy Policy.
class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool forceWhiteBackground;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.forceWhiteBackground = false,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final host = Uri.tryParse(widget.url)?.host;
    _controller = WebViewController()
      // Privacy page needs a little JS to force the white background; otherwise
      // JavaScript is disabled for safety.
      ..setJavaScriptMode(
          widget.forceWhiteBackground ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _error = false;
            });
          }
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          if (widget.forceWhiteBackground) {
            _controller.runJavaScript(
              "document.documentElement.style.backgroundColor='#ffffff';"
              "document.body.style.backgroundColor='#ffffff';",
            );
          }
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            if (mounted) {
              setState(() {
                _error = true;
                _loading = false;
              });
            }
          }
        },
        onNavigationRequest: (request) {
          // Keep navigation on the original site; block unexpected external hops.
          final targetHost = Uri.tryParse(request.url)?.host;
          if (host == null || targetHost == null || targetHost == host) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  void _retry() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _handleBack();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
          bottom: _loading && !_error
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100 : null,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                  ),
                )
              : null,
        ),
        body: _error ? _errorView() : WebViewWidget(controller: _controller),
      ),
    );
  }

  Widget _errorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56, color: Colors.black38),
              const SizedBox(height: 16),
              const Text(
                'Could not load the page.\nPlease check your internet connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
