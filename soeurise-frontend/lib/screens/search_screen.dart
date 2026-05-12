import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/search_service.dart';
import '../services/community_service.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';
import 'group_chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _searchService = SearchService.instance;
  SearchResults _results = SearchResults(users: [], posts: [], groups: [], hashtags: []);
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = SearchResults(users: [], posts: [], groups: [], hashtags: []);
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final res = await _searchService.searchAll(query);
    if (mounted) {
      setState(() {
        _results = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Recherche', style: AppTextStyles.headline3.copyWith(fontSize: 18)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            tabs: const [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Publications'),
              Tab(text: 'Hashtags'),
              Tab(text: 'Groupes'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(color: AppColors.primary),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUsers(),
                  _buildPosts(),
                  _buildHashtags(),
                  _buildGroups(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsers() {
    if (_results.users.isEmpty) {
      return _buildEmpty('Aucun utilisateur');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.users.length,
      itemBuilder: (context, i) {
        final user = _results.users[i];
        return ListTile(
          leading: UserAvatar(
            imageUrl: user.avatarFullUrl.isNotEmpty ? user.avatarFullUrl : null,
            username: user.fullName,
            radius: 20,
          ),
          title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
          subtitle: Text('@${user.username}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
            );
          },
        );
      },
    );
  }

  Widget _buildPosts() {
    if (_results.posts.isEmpty) {
      return _buildEmpty('Aucune publication');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.posts.length,
      itemBuilder: (context, i) => PostCard(post: _results.posts[i]),
    );
  }

  Widget _buildHashtags() {
    if (_results.hashtags.isEmpty) {
      return _buildEmpty('Aucun hashtag');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.hashtags.length,
      itemBuilder: (context, i) {
        final tag = _results.hashtags[i];
        return ListTile(
          leading: const Icon(Icons.tag_rounded, color: AppColors.primary),
          title: Text('#${tag.tag}'),
          subtitle: Text('${tag.count} publications'),
          onTap: () {
            _controller.text = '#${tag.tag}';
            _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
            _search(_controller.text);
          },
        );
      },
    );
  }

  Widget _buildGroups() {
    if (_results.groups.isEmpty) {
      return _buildEmpty('Aucun groupe');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.groups.length,
      itemBuilder: (context, i) {
        final group = _results.groups[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(20),
            child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : '?'),
          ),
          title: Text(group.name),
          subtitle: Text(group.description),
          trailing: TextButton(
            onPressed: () async {
              final ok = await CommunityService.instance.joinGroup(group.id);
              if (!context.mounted) return;
              if (ok) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      communityId: group.id,
                      communityName: group.name,
                    ),
                  ),
                );
              }
            },
            child: const Text('Rejoindre'),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String label) {
    return Center(
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
    );
  }
}
