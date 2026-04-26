import 'package:flutter/material.dart';

/// Stub implementation – should never be called at runtime.
Widget buildWebView({
  required Key key,
  required String url,
  required VoidCallback onLoadStart,
  required void Function(int) onProgress,
  required VoidCallback onLoadFinished,
  required VoidCallback onError,
}) {
  return const Center(child: Text('WebView non supporté sur cette plateforme'));
}
