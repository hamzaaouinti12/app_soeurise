import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../theme/glass_widgets.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';
import 'post_creation_screen.dart';

import '../services/post_service.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  late String currentUsername;
  late String currentUserImage;
  int followers = 1250;
  int following = 450;

  List<Post> userPosts = [];
  List<Post> feeds = [];
  List<Post> subscriptionFeed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Get current user info from ProfileService
    currentUsername = ProfileService.instance.profile.value.fullName;
    currentUserImage = ProfileService.instance.profile.value.profileImageUrl;
    refreshFeeds();
  }

  Future<void> refreshFeeds() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        PostService.instance.fetchFeed(),
        PostService.instance.fetchSubscriptionFeed(),
      ]);
      if (mounted) {
        setState(() {
          feeds = results[0];
          subscriptionFeed = results[1];
          userPosts =
              feeds.where((p) => p.username == currentUsername).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder:
            (context, _) => [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.background.withAlpha(240),
                elevation: 0,
                title: ShaderMask(
                  shaderCallback:
                      (bounds) => AppColors.accentGradient.createShader(bounds),
                  child: const Text(
                    'Soeurise',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                centerTitle: false,
                actions: [
                  // Refresh button
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: refreshFeeds,
                      tooltip: 'Rafraîchir',
                    ),
                  ),
                  // Notification button
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withAlpha(120),
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: const [
                        Tab(text: 'Pour toi'),
                        Tab(text: 'Abonnements'),
                        Tab(text: 'Profil'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedList(feeds, isSubscription: false),
            _buildFeedList(subscriptionFeed, isSubscription: true),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(List<Post> posts, {required bool isSubscription}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSubscription
                  ? Icons.people_outline_rounded
                  : Icons.article_outlined,
              size: 56,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              isSubscription
                  ? "Aucun post de vos abonnements"
                  : "Aucun post disponible",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (isSubscription) ...[
              const SizedBox(height: 8),
              Text(
                "Suivez des personnes pour voir leur contenu ici",
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: refreshFeeds,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: posts.length + 1,
        itemBuilder: (context, index) {
          // Show post composer at index 0
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostComposer(),
            );
          }
          // Show posts after the composer
          return FadeSlideIn(
            delay: Duration(milliseconds: index * 100),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: posts[index - 1]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostComposer() {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: currentUserImage,
              username: currentUsername,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostCreationScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.beige.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  ),
                  child: Text(
                    "Compose un post, ${currentUsername.split(' ').first}...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.lg),
                        topRight: Radius.circular(AppBorderRadius.lg),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(30),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            imageUrl: currentUserImage,
                            username: currentUsername,
                            radius: 44,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(currentUsername, style: AppTextStyles.headline3),
                        Text('@fatima_ahmed', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStat('${userPosts.length}', 'Publications'),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.beigeDark.withAlpha(60),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            _buildStat('$followers', 'Abonnés'),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.beigeDark.withAlpha(60),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            _buildStat('$following', 'Suivies'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GlassButton(
                            label: 'Modifier le profil',
                            icon: Icons.edit_rounded,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Mes Publications',
              style: AppTextStyles.headline3.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),

          ...userPosts.asMap().entries.map((entry) {
            return FadeSlideIn(
              delay: Duration(milliseconds: (entry.key + 1) * 150),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(post: entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: AppTextStyles.headline3.copyWith(
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
