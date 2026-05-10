import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants.dart';
import '../models/models.dart';
import '../theme/glass_widgets.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/story_service.dart';
import 'post_creation_screen.dart';
import 'profile_screen.dart';
import 'story_viewer_screen.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';

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

  List<Post> userPosts = [];
  List<Post> feeds = [];
  List<Post> subscriptionFeed = [];
  List<Story> stories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUsername = ProfileService.instance.profile.value.fullName;
    currentUserImage = ProfileService.instance.profile.value.profileImageUrl;
    refreshFeeds();
    // Listen to profile changes to rebuild the post composer
    ProfileService.instance.profile.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        currentUsername = ProfileService.instance.profile.value.fullName;
        currentUserImage =
            ProfileService.instance.profile.value.profileImageUrl;
      });
    }
  }

  Future<void> refreshFeeds() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        PostService.instance.fetchFeed(),
        PostService.instance.fetchSubscriptionFeed(),
        StoryService.instance.fetchStories(),
      ]);
      if (mounted) {
        setState(() {
          feeds = results[0] as List<Post>;
          subscriptionFeed = results[1] as List<Post>;
          stories = results[2] as List<Story>;
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
    ProfileService.instance.profile.removeListener(_onProfileChanged);
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
                  // Search button
                  SearchAnchor(
                    builder: (context, controller) {
                      return IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          controller.openView();
                        },
                      );
                    },
                    suggestionsBuilder: (context, controller) async {
                      final query = controller.text;
                      if (query.length < 2) return [];
                      final users = await ProfileService.instance.searchUsers(
                        query,
                      );
                      return users.map((user) {
                        return ListTile(
                          leading: UserAvatar(
                            imageUrl: user.avatarFullUrl,
                            username: user.username,
                            radius: 20,
                          ),
                          title: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName
                                : user.username,
                          ),
                          subtitle: Text('@${user.username}'),
                          onTap: () {
                            controller.closeView(null);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UserProfileScreen(userId: user.id),
                              ),
                            );
                          },
                        );
                      });
                    },
                    viewBackgroundColor: AppColors.background,
                    viewSurfaceTintColor: Colors.transparent,
                    viewElevation: 0,
                    headerTextStyle: AppTextStyles.bodyLarge,
                    viewHintText: 'Rechercher une soeur...',
                  ),
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
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService.instance.unreadCount,
                    builder: (context, count, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 12,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
        itemCount: posts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStoryStrip(),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostComposer(),
            );
          }
          final postIndex = index - 2;
          return FadeSlideIn(
            delay: Duration(milliseconds: index * 80),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: posts[postIndex]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostComposer() {
    return ValueListenableBuilder<Profile>(
      valueListenable: ProfileService.instance.profile,
      builder: (context, profile, _) {
        final displayName = profile.fullName;
        return GlassCard(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CurrentUserAvatar(radius: 20),
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
                        "Compose un post, ${displayName.split(' ').first}...",
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
      },
    );
  }

  Future<void> _createStory() async {
    final pickedType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Ajouter une photo'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Ajouter une vidéo'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        );
      },
    );

    if (pickedType == null) return;

    final picker = ImagePicker();
    XFile? file;
    if (pickedType == 'image') {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
      );
    } else if (pickedType == 'video') {
      file = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (file == null) return;

    final captionController = TextEditingController();
    final storyCaption = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter une légende'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Écrire une légende pour votre story',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed:
                  () => Navigator.pop(context, captionController.text.trim()),
              child: const Text('Publier'),
            ),
          ],
        );
      },
    );

    if (!mounted || storyCaption == null) return;

    final created = await StoryService.instance.createStory(
      mediaFile: File(file.path),
      mediaType: pickedType,
      caption: storyCaption,
    );

    if (created != null && mounted) {
      await refreshFeeds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story publiée avec succès')),
      );
    }
  }

  Widget _buildStoryStrip() {
    final groupedStories = <String, List<Story>>{};
    final groupedAuthorOrder = <String>[];

    for (final story in stories) {
      final authorId = story.authorId;
      if (!groupedStories.containsKey(authorId)) {
        groupedStories[authorId] = [];
        groupedAuthorOrder.add(authorId);
      }
      groupedStories[authorId]!.add(story);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Stories',
            style: AppTextStyles.headline3.copyWith(fontSize: 18),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: groupedAuthorOrder.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _createStory,
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Ma story', style: AppTextStyles.caption),
                    ],
                  ),
                );
              }

              final authorId = groupedAuthorOrder[index - 1];
              final authorStories = groupedStories[authorId]!;
              final story = authorStories.first;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewerScreen(
                        stories: authorStories,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: UserAvatar(
                        imageUrl: story.profileImageUrl,
                        username: story.username,
                        radius: 30,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 72,
                      child: Text(
                        story.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return ValueListenableBuilder<Profile>(
      valueListenable: ProfileService.instance.profile,
      builder: (context, profile, _) {
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(30),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child:
                                  profile.profileImageFile != null
                                      ? CircleAvatar(
                                        radius: 44,
                                        backgroundImage: FileImage(
                                          profile.profileImageFile!,
                                        ),
                                      )
                                      : UserAvatar(
                                        imageUrl:
                                            profile.profileImageUrlWithCache,
                                        username: profile.username,
                                        radius: 44,
                                      ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              profile.fullName,
                              style: AppTextStyles.headline3,
                            ),
                            Text(
                              '@${profile.username}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStat(
                                  '${userPosts.length}',
                                  'Publications',
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColors.beigeDark.withAlpha(60),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                ),
                                _buildStat(
                                  '${profile.followersCount}',
                                  'Abonnés',
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColors.beigeDark.withAlpha(60),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                ),
                                _buildStat(
                                  '${profile.followingCount}',
                                  'Suivies',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
      },
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
