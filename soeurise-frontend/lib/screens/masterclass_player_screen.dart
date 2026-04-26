import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';

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

class _MasterclassPlayerScreenState extends State<MasterclassPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _launched = false;
  late AnimationController _pulseController;

  Future<void> _openInBrowser() async {
    final url = widget.videoUrl;
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _launched = true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _openInBrowser());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.headline3.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated play icon
                        FadeSlideIn(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + _pulseController.value * 0.05,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withAlpha(60),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Lecture de la masterclass',
                            style: AppTextStyles.headline2,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 12),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: GlassCard(
                            child: Text(
                              _launched
                                  ? '✅ La masterclass a été ouverte dans votre navigateur.'
                                  : '⏳ Ouverture dans le navigateur...\nSi cela ne fonctionne pas, appuyez ci-dessous.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 400),
                          child: GlassButton(
                            label: 'Ouvrir dans le navigateur',
                            icon: Icons.open_in_browser_rounded,
                            onPressed: _openInBrowser,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
