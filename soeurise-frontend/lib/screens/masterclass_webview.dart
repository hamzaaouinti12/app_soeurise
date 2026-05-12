import 'package:flutter/material.dart';

import 'masterclass_webview_stub.dart'
    if (dart.library.html) 'masterclass_webview_web.dart'
    if (dart.library.io) 'masterclass_webview_mobile.dart';

class MasterclassWebView extends StatelessWidget {
  final String url;
  final VoidCallback onLoadStart;
  final void Function(int) onProgress;
  final VoidCallback onLoadFinished;
  final VoidCallback onError;

  const MasterclassWebView({
    super.key,
    required this.url,
    required this.onLoadStart,
    required this.onProgress,
    required this.onLoadFinished,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return buildWebView(
      key: key ?? UniqueKey(),
      url: url,
      onLoadStart: onLoadStart,
      onProgress: onProgress,
      onLoadFinished: onLoadFinished,
      onError: onError,
    );
  }
}
