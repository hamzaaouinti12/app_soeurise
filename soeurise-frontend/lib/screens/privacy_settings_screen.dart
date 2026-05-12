import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';
import 'follow_requests_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _saving = false;

  Future<void> _setPrivacy(bool private) async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await ProfileService.instance.updateProfile(
      accountPrivacy: private ? 'private' : 'public',
    );
    if (mounted) {
      setState(() => _saving = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'enregistrer le réglage'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Confidentialité du compte',
          style: AppTextStyles.headline3.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ValueListenableBuilder<Profile>(
        valueListenable: ProfileService.instance.profile,
        builder: (context, profile, _) {
          final isPrivate = profile.isPrivateAccount;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visibilité du profil', style: AppTextStyles.headline4),
                    const SizedBox(height: 8),
                    Text(
                      'Compte public : tout le monde voit vos publications (hors communautés) et peut vous suivre directement.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compte privé : seuls vos abonnés acceptés voient ce contenu. Les autres envoient une demande que vous pouvez accepter ou refuser.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_saving)
                      const LinearProgressIndicator()
                    else
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isPrivate ? 'Compte privé' : 'Compte public',
                          style: AppTextStyles.bodyLarge,
                        ),
                        subtitle: Text(
                          isPrivate ? 'Demandes d’abonnement activées' : 'Visible pour tous dans le fil global',
                          style: AppTextStyles.caption,
                        ),
                        value: isPrivate,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => _setPrivacy(v),
                      ),
                  ],
                ),
              ),
              if (isPrivate) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                    title: Text('Demandes d’abonnement', style: AppTextStyles.bodyLarge),
                    subtitle: Text(
                      'Voir qui souhaite vous suivre',
                      style: AppTextStyles.caption,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FollowRequestsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
