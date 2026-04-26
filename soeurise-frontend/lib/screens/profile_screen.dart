import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../widgets/user_avatar.dart';
import '../services/profile_service.dart';
import '../services/community_service.dart';
import '../services.dart';
import 'events_screen.dart';
import 'masterclass_screen.dart';
import 'communities_screen.dart';
import 'settings_screen.dart';
import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showEditDialog(BuildContext context) async {
    final profile = ProfileService.instance.profile.value;
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final usernameController = TextEditingController(text: profile.username);
    final bioController = TextEditingController(text: profile.bio);
    File? tempImageFile;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppBorderRadius.xxl),
              topRight: Radius.circular(AppBorderRadius.xxl),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.beigeDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Modifier le profil',
                  style: AppTextStyles.headline3,
                ),
                const SizedBox(height: 24),

                // Editable Avatar
                GestureDetector(
                  onTap: () async {
                    final picked =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        tempImageFile = File(picked.path);
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      tempImageFile != null
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: FileImage(tempImageFile!),
                            )
                          : UserAvatar(
                              imageUrl:
                                  profile.profileImageUrl.isNotEmpty
                                      ? profile.profileImageUrl
                                      : null,
                              username: profile.username.isNotEmpty
                                  ? profile.username
                                  : '??',
                              radius: 40,
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: firstNameController,
                        label: 'Prénom',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassTextField(
                        controller: lastNameController,
                        label: 'Nom',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                GlassTextField(
                  controller: usernameController,
                  label: 'Nom d\'utilisateur',
                ),

                const SizedBox(height: 16),

                GlassTextField(
                  controller: bioController,
                  label: 'Bio (Optionnel)',
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                GlassButton(
                  label: 'Enregistrer',
                  onPressed: () async {
                    final success = await ProfileService.instance.updateProfile(
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      username: usernameController.text.trim(),
                      // bio feature not in backend user yet, could be added later
                    );
                    
                    if (tempImageFile != null) {
                      await ProfileService.instance.updateAvatar(tempImageFile!.path);
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil mis à jour'),
                          backgroundColor: AppColors.successColor,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors de la mise à jour'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar & Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.textPrimary,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight.withAlpha(40),
                      AppColors.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: ValueListenableBuilder<Profile>(
                    valueListenable: ProfileService.instance.profile,
                    builder: (context, profile, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Avatar with animated border
                          FadeSlideIn(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(40),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: profile.profileImageFile != null
                                        ? CircleAvatar(
                                            radius: 46,
                                            backgroundImage: FileImage(
                                                profile.profileImageFile!),
                                          )
                                        : UserAvatar(
                                            imageUrl: profile
                                                    .profileImageUrl.isNotEmpty
                                                ? profile.profileImageUrl
                                                : null,
                                            username: profile
                                                    .username.isNotEmpty
                                                ? profile.username
                                                : 'U',
                                            radius: 46,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Profile Info
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            child: Column(
                              children: [
                                Text(
                                  profile.fullName,
                                  style: AppTextStyles.headline1.copyWith(
                                    fontSize: 24,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${profile.username} • ${profile.accountType}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (profile.bio.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.bio,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Edit Button
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppColors.beigeDark,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Modifier le profil',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ValueListenableBuilder<Profile>(
                valueListenable: ProfileService.instance.profile,
                builder: (context, profile, child) {
                  return FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Vues', profile.masterclassesWatched.toString()),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.beigeDark.withAlpha(100),
                          ),
                          _buildStatItem('Événements', profile.eventsRegistered.toString()),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.beigeDark.withAlpha(100),
                          ),
                          _buildStatItem('Groupes', profile.communitiesJoined.toString()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Mon Activité',
                      style: AppTextStyles.headline3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: _buildActivityItem(
                      context,
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Masterclasses suivies',
                      subtitle: 'Reprendre où vous vous êtes arrêtée',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MasterclassScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 600),
                    child: _buildActivityItem(
                      context,
                      icon: Icons.event_available_rounded,
                      title: 'Événements inscrits',
                      subtitle: 'Vos prochains rendez-vous',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EventsScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 700),
                    child: _buildActivityItem(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Mes communautés',
                      subtitle: 'Groupes que vous avez rejoints',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CommunitiesScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 800),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final logoutDone = await AuthenticationService.instance.logout();
                          if (logoutDone && context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.errorColor,
                        ),
                        label: Text(
                          'Déconnexion',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Bottom nav padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.primary,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headline4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
