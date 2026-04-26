import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../services/profile_service.dart';
import 'login_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      Text('Paramètres', style: AppTextStyles.headline2),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General section
                      FadeSlideIn(
                        child: _sectionTitle('Général'),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: GlassCard(
                          child: Column(
                            children: [
                              _toggleTile(
                                Icons.notifications_rounded,
                                'Notifications',
                                _notificationsEnabled,
                                (v) => setState(
                                    () => _notificationsEnabled = v),
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _toggleTile(
                                Icons.dark_mode_rounded,
                                'Mode sombre',
                                _darkMode,
                                (v) => setState(() => _darkMode = v),
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _navTile(
                                Icons.language_rounded,
                                'Langue',
                                subtitle: 'Français',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Privacy section
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: _sectionTitle('Confidentialité'),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: GlassCard(
                          child: Column(
                            children: [
                              _navTile(
                                Icons.lock_rounded,
                                'Mot de passe',
                                onTap: () {},
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _navTile(
                                Icons.shield_rounded,
                                'Confidentialité du profil',
                                onTap: () {},
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _navTile(
                                Icons.block_rounded,
                                'Utilisateurs bloqués',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // About section
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 350),
                        child: _sectionTitle('À propos'),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: GlassCard(
                          child: Column(
                            children: [
                              _navTile(
                                Icons.info_rounded,
                                'À propos de Soeurise',
                                onTap: () {},
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _navTile(
                                Icons.description_rounded,
                                'Conditions d\'utilisation',
                                onTap: () {},
                              ),
                              Divider(
                                color: AppColors.beigeDark.withAlpha(40),
                                height: 1,
                              ),
                              _navTile(
                                Icons.privacy_tip_rounded,
                                'Politique de confidentialité',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Logout
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: GlassCard(
                          child: _navTile(
                            Icons.logout_rounded,
                            'Déconnexion',
                            isDestructive: true,
                            onTap: () => _handleLogout(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Version
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 550),
                        child: Center(
                          child: Text(
                            'Soeurise v1.0.0',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _toggleTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _navTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.errorColor.withAlpha(15)
              : AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.errorColor : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.errorColor : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.caption)
          : null,
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text('Déconnexion', style: AppTextStyles.headline3),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ProfileService.instance.logout();
      if (!context.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
