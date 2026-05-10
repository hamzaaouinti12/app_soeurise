import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

/// Liste des followers de l'utilisateur courant ou d'un autre utilisateur.
class FollowersListScreen extends StatefulWidget {
  final String? userId; // null = current user

  const FollowersListScreen({super.key, this.userId});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  List<User> _followers = [];
  bool _loading = true;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_loading) {
        _loadMore();
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = widget.userId == null
        ? await ProfileService.instance.fetchMyFollowers(page: 1, limit: _limit)
        : await ProfileService.instance.fetchUserFollowers(
            widget.userId!,
            page: 1,
            limit: _limit,
          );
    if (mounted) {
      setState(() {
        _followers = list;
        _page = 1;
        _hasMore = list.length == _limit;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    final list = widget.userId == null
        ? await ProfileService.instance.fetchMyFollowers(
            page: _page + 1,
            limit: _limit,
          )
        : await ProfileService.instance.fetchUserFollowers(
            widget.userId!,
            page: _page + 1,
            limit: _limit,
          );
    if (mounted) {
      setState(() {
        _followers.addAll(list);
        _page += 1;
        _hasMore = list.length == _limit;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Abonnés',
          style: AppTextStyles.headline3.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _loading && _followers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _followers.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Aucun abonné pour le moment',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _followers.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _followers.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final user = _followers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                imageUrl: user.avatarFullUrl.isNotEmpty
                                    ? user.avatarFullUrl
                                    : null,
                                username: user.fullName,
                                radius: 24,
                              ),
                              title: Text(
                                user.fullName.trim().isNotEmpty
                                    ? user.fullName
                                    : user.username,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '@${user.username}',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(
                                      userId: user.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
