import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildWebView({
  required Key key,
  required String url,
  required VoidCallback onLoadStart,
  required void Function(int) onProgress,
  required VoidCallback onLoadFinished,
  required VoidCallback onError,
}) {
  return _WebIframeView(
    key: key,
    url: url,
    onLoadStart: onLoadStart,
    onLoadFinished: onLoadFinished,
    onError: onError,
  );
}

class _WebIframeView extends StatefulWidget {
  final String url;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadFinished;
  final VoidCallback onError;

  const _WebIframeView({
    super.key,
    required this.url,
    required this.onLoadStart,
    required this.onLoadFinished,
    required this.onError,
  });

  @override
  State<_WebIframeView> createState() => _WebIframeViewState();
}

class _WebIframeViewState extends State<_WebIframeView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'masterclass-iframe-${widget.key.hashCode}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadStart();
    });

    // Register the iframe as a platform view
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;

      iframe.onLoad.listen((_) {
        widget.onLoadFinished();
      });

      iframe.onError.listen((_) {
        widget.onError();
      });

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
