import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildWebView({
  required Key key,
  required String url,
  required VoidCallback onLoadStart,
  required void Function(int) onProgress,
  required VoidCallback onLoadFinished,
  required VoidCallback onError,
}) {
  return _MobileWebView(
    key: key,
    url: url,
    onLoadStart: onLoadStart,
    onProgress: onProgress,
    onLoadFinished: onLoadFinished,
    onError: onError,
  );
}

class _MobileWebView extends StatefulWidget {
  final String url;
  final VoidCallback onLoadStart;
  final void Function(int) onProgress;
  final VoidCallback onLoadFinished;
  final VoidCallback onError;

  const _MobileWebView({
    super.key,
    required this.url,
    required this.onLoadStart,
    required this.onProgress,
    required this.onLoadFinished,
    required this.onError,
  });

  @override
  State<_MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<_MobileWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onLoadStart(),
          onProgress: (progress) => widget.onProgress(progress),
          onPageFinished: (_) => widget.onLoadFinished(),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              widget.onError();
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.host.contains('soeurise.com')) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..enableZoom(false)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
