import '../models/models.dart';
import 'api_client.dart';

class SearchResults {
  final List<User> users;
  final List<Post> posts;
  final List<Community> groups;
  final List<HashtagResult> hashtags;

  SearchResults({
    required this.users,
    required this.posts,
    required this.groups,
    required this.hashtags,
  });
}

class SearchService {
  SearchService._internal();
  static final SearchService instance = SearchService._internal();

  final _api = ApiClient.instance;

  Future<SearchResults> searchAll(String query, {int limit = 10}) async {
    if (query.trim().length < 2) {
      return SearchResults(users: [], posts: [], groups: [], hashtags: []);
    }
    try {
      final res = await _api.get('/search?q=$query&limit=$limit');
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final usersRaw = data['users'] as List? ?? [];
        final postsRaw = data['posts'] as List? ?? [];
        final groupsRaw = data['groups'] as List? ?? [];
        final tagsRaw = data['hashtags'] as List? ?? [];

        return SearchResults(
          users: usersRaw.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),
          posts: postsRaw.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
          groups: groupsRaw.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList(),
          hashtags: tagsRaw.map((e) => HashtagResult.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
      return SearchResults(users: [], posts: [], groups: [], hashtags: []);
    } catch (_) {
      return SearchResults(users: [], posts: [], groups: [], hashtags: []);
    }
  }
}
