import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/user_avatar.dart';
import '../widgets/post_card.dart';
import 'followers_list_screen.dart';
import 'private_chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPostsLoading = true;
  bool _isSavedLoading = true;
  List<Post> _userPosts = [];
  List<Post> _savedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPosts();
  }

  bool get _isSelf =>
      widget.userId == ProfileService.instance.profile.value.id;

  Future<void> _loadUser({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }
    final user = await ProfileService.instance.fetchUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _user = user;
        if (!silent) _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isPostsLoading = true;
      _isSavedLoading = _isSelf;
    });

    final posts = await PostService.instance.fetchUserPosts(widget.userId);
    List<Post> saved = [];
    if (_isSelf) {
      saved = await PostService.instance.fetchSavedPosts();
    }

    if (mounted) {
      setState(() {
        _userPosts = posts;
        _savedPosts = saved;
        _isPostsLoading = false;
        _isSavedLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    setState(() {
      _isSaving = true;
    });

    final result = await ProfileService.instance.toggleFollowUser(
      widget.userId,
    );
    if (result != null && mounted) {
      await _loadUser(silent: true);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _toggleBlock() async {
    if (_user == null) return;

    final isBlocking = _user!.isBlocked;
    final actionLabel = isBlocking ? 'Débloquer' : 'Bloquer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel l\'utilisateur'),
        content: Text(
          isBlocking
              ? 'Voulez-vous débloquer cet utilisateur ?'
              : 'Voulez-vous bloquer cet utilisateur ? Il ne pourra plus voir votre contenu ni vous suivre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocking ? AppColors.primary : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    bool success;
    if (isBlocking) {
      success = await ProfileService.instance.unblockUser(widget.userId);
    } else {
      success = await ProfileService.instance.blockUser(widget.userId);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur ${isBlocking ? 'débloqué' : 'bloqué'}')),
      );
      await _loadUser(silent: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue')),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  String get _followButtonLabel {
    if (_user == null) return 'Suivre';
    if (_user!.isFollowing) return 'Suivi';
    if (_user!.followRequestSent) return '✓ Demande envoyée';
    return 'Suivre';
  }

  String get _followButtonSecondaryLabel {
    if (_user?.followRequestSent == true) return 'Annuler';
    if (_user?.isFollowing == true) return 'Ne plus suivre';
    return '';
  }

  Color get _followButtonColor {
    if (_user == null) return AppColors.primary;
    if (_user!.isFollowing || _user!.followRequestSent) return AppColors.surface;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final canShowPosts =
        _user != null && _user!.canViewContent && !_user!.isBlocked;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (_user != null && _user!.id != ProfileService.instance.profile.value.id)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  _toggleBlock();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        _user!.isBlocked ? Icons.check_circle_outline : Icons.block,
                        color: _user!.isBlocked ? AppColors.primary : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _user!.isBlocked ? 'Débloquer' : 'Bloquer',
                        style: TextStyle(
                          color: _user!.isBlocked ? AppColors.textPrimary : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? Center(
                child: Text(
                  'Utilisateur introuvable',
                  style: AppTextStyles.bodyLarge,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      imageUrl: _user!.avatarFullUrl.isNotEmpty
                          ? _user!.avatarFullUrl
                          : null,
                      username: _user!.canViewContent
                          ? _user!.fullName
                          : _user!.username,
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.canViewContent
                          ? (_user!.fullName.trim().isNotEmpty
                              ? _user!.fullName
                              : _user!.username)
                          : _user!.username,
                      style: AppTextStyles.headline4.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '@${_user!.username}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_user!.accountPrivacy == 'private')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Privé',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersListScreen(
                                  userId: _user!.id,
                                ),
                              ),
                            );
                          },
                          child: _buildStat('${_user!.followersCount}', 'Abonnés'),
                        ),
                        _verticalDivider(),
                        _buildStat('${_user!.followingCount}', 'Suivies'),
                      ],
                    ),
                    if (_user!.id !=
                        ProfileService.instance.profile.value.id) ...[
                      const SizedBox(height: 24),
                      if (_user!.followRequestSent)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isSaving ? null : _toggleFollow,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.pill,
                                    ),
                                    side: BorderSide(color: AppColors.primary),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  'Annuler',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: null, // Disabled - showing pending state
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withAlpha(100),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.pill,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Demande envoyée',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaving ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _followButtonColor,
                                foregroundColor:
                                    (_user!.isFollowing || _user!.followRequestSent)
                                        ? AppColors.textPrimary
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.pill,
                                  ),
                                  side:
                                      (_user!.isFollowing || _user!.followRequestSent)
                                          ? BorderSide(color: AppColors.primary)
                                          : BorderSide.none,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 30,
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        _followButtonLabel,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PrivateChatScreen(user: _user!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message_rounded, size: 18),
                              label: Text(
                                'Message',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                                  side: BorderSide(color: AppColors.primary),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              ),
                            ),
                          ],
                        ),
                    ],
                    const SizedBox(height: 24),
                    if (_user!.isBlocked)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.block,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Utilisateur bloqué',
                              style: AppTextStyles.headline4.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vous avez bloqué cet utilisateur. Vous ne pouvez plus voir son contenu.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _toggleBlock,
                              child: const Text('Débloquer'),
                            ),
                          ],
                        ),
                      )
                    else if (!_user!.canViewContent)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Compte privé',
                              style: AppTextStyles.headline4.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seuls les abonnés acceptés peuvent voir les publications hors communautés.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('À propos', style: AppTextStyles.headline4),
                            const SizedBox(height: 12),
                            Text(
                              _user!.accountPrivacy == 'private'
                                  ? 'Compte privé : seuls les abonnés acceptés voient les publications hors groupes.'
                                  : 'Profil public : vous pouvez suivre cette personne pour voir ses publications dans votre fil.',
                              style: AppTextStyles.bodyLarge.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (canShowPosts) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Publications', style: AppTextStyles.headline4),
                      ),
                      const SizedBox(height: 12),
                      if (_isPostsLoading)
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      else if (_userPosts.isEmpty)
                        Text(
                          'Aucune publication pour le moment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Column(
                          children: _userPosts
                              .map((post) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: PostCard(post: post),
                                  ))
                              .toList(),
                        ),
                    ],

                    if (_isSelf && canShowPosts) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Enregistrees', style: AppTextStyles.headline4),
                      ),
                      const SizedBox(height: 12),
                      if (_isSavedLoading)
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      else if (_savedPosts.isEmpty)
                        Text(
                          'Aucune publication enregistree',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Column(
                          children: _savedPosts
                              .map((post) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: PostCard(post: post),
                                  ))
                              .toList(),
                        ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline4.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: 1,
      height: 40,
      color: AppColors.beigeDark.withAlpha(60),
    );
  }
}
