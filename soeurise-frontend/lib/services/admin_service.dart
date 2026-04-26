import '../models/models.dart';
import 'api_client.dart';

class AdminService {
  static final AdminService instance = AdminService._internal();
  AdminService._internal();

  /// Fetch dashboard stats
  Future<Map<String, int>> fetchStats() async {
    try {
      final response = await ApiClient.instance.get('/admin/stats');
      if (response.success && response.data != null) {
        final d = response.data as Map<String, dynamic>;
        return {
          'users': d['totalUsers'] ?? 0,
          'posts': d['totalPosts'] ?? 0,
          'events': d['totalEvents'] ?? 0,
          'masterclasses': d['totalMasterclasses'] ?? 0,
          'comments': d['totalComments'] ?? 0,
        };
      }
      return {};
    } catch (e) {
      print('Error fetching stats: $e');
      return {};
    }
  }

  /// Fetch paginated user list
  Future<List<User>> fetchUsers({int page = 1, int limit = 20, String? search}) async {
    try {
      String query = '?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        query += '&search=$search';
      }
      final response = await ApiClient.instance.get('/admin/users$query');
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>? ?? [];
        return users.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await ApiClient.instance.delete('/admin/users/$userId');
      return response.success;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final response = await ApiClient.instance.patch(
        '/admin/users/$userId/role',
        {'role': role},
      );
      return response.success;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      final response = await ApiClient.instance.patch(
        '/admin/users/$userId/status',
        {'isActive': isActive},
      );
      return response.success;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  /// Fetch paginated posts
  Future<List<Post>> fetchPosts({int page = 1, int limit = 20}) async {
    try {
      final response = await ApiClient.instance.get('/admin/posts?page=$page&limit=$limit');
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final posts = data['posts'] as List<dynamic>? ?? [];
        return posts.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      final response = await ApiClient.instance.delete('/admin/posts/$postId');
      return response.success;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }
}
