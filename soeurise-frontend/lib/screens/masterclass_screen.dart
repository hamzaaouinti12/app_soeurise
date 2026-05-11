import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import 'masterclass_webview.dart';

/// Master Class Module - Intégration complète du site Soeurise
/// Affiche le contenu éducatif via WebView avec accès au menu complet
class MasterclassScreen extends StatefulWidget {
  const MasterclassScreen({super.key});

  @override
  State<MasterclassScreen> createState() => _MasterclassScreenState();
}

class _MasterclassScreenState extends State<MasterclassScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;

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
          'Masterclass',
          style: AppTextStyles.headline3,
        ),
        actions: [
          IconButton(
            onPressed: _reloadWebView,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView du site Soeurise
          MasterclassWebView(
            url: 'https://soeurise.com',
            onLoadStart: () {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _hasError = false;
                _loadingProgress = 0;
              });
            },
            onProgress: (progress) {
              if (!mounted) return;
              setState(() {
                _loadingProgress = progress;
              });
            },
            onLoadFinished: () {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _loadingProgress = 100;
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
          // Indicateur de chargement
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement du contenu...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_loadingProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_loadingProgress.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Écran d'erreur
          if (_hasError)
            Center(
              child: GlassCard(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: AppTextStyles.headline4,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Impossible de charger le contenu Masterclass.\nVérifiez votre connexion internet.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _reloadWebView,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
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

  /// Recharge la WebView
  void _reloadWebView() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
  }
}

