import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import 'masterclass_webview.dart';

class MasterclassPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const MasterclassPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<MasterclassPlayerScreen> createState() =>
      _MasterclassPlayerScreenState();
}

class _MasterclassPlayerScreenState extends State<MasterclassPlayerScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: AppTextStyles.headline3.copyWith(fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          MasterclassWebView(
            url: 'https://soeurise.com', // Override as requested by user
            onLoadStart: () {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onProgress: (progress) {
              // Could add progress bar logic here
            },
            onLoadFinished: () {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
              });
            },
            onError: () {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          if (_hasError)
            Center(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur lors du chargement de la page.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
