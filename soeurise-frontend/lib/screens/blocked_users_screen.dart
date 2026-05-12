import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = true;
  List<User> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ProfileService.instance.fetchBlockedUsers();
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des utilisateurs bloqués')),
        );
      }
    }
  }

  Future<void> _unblockUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Débloquer'),
        content: Text('Voulez-vous débloquer ${user.username} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ProfileService.instance.unblockUser(user.id);
      if (success) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.id == user.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} a été débloqué')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du déblocage')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
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
                    Text('Utilisateurs bloqués', style: AppTextStyles.headline2),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadBlockedUsers,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _blockedUsers.isEmpty
                          ? _buildEmptyState()
                          : _buildUserList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: AppColors.textLight.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur bloqué',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: GlassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  backgroundImage: user.avatarFullUrl.isNotEmpty
                      ? NetworkImage(user.avatarFullUrl)
                      : null,
                  backgroundColor: AppColors.beigeDark.withAlpha(50),
                  child: user.avatarFullUrl.isEmpty
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                title: Text(
                  user.fullName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '@${user.username}',
                  style: AppTextStyles.caption,
                ),
                trailing: TextButton(
                  onPressed: () => _unblockUser(user),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Débloquer'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
