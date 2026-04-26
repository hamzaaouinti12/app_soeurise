import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_client.dart';

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.text, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class CommunityService {
  CommunityService._private();
  static final CommunityService instance = CommunityService._private();

  final _api = ApiClient.instance;
  final ValueNotifier<Set<String>> joined = ValueNotifier(<String>{});
  final Map<String, ValueNotifier<List<ChatMessage>>> _messages = {};

  bool isMember(String communityId) => joined.value.contains(communityId);

  // ─── Backend API calls ───

  /// Fetch public groups from the backend.
  Future<List<Community>> fetchGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      var path = '/community/groups/public?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search)}';
      }
      final res = await _api.get(path);
      if (res.success && res.data != null) {
        final groups = res.data!['groups'] as List? ?? [];
        return groups
            .map((g) => Community.fromJson(g as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Join a group via the backend.
  Future<bool> joinGroup(String groupId) async {
    try {
      final res = await _api.post('/community/groups/$groupId/join', {});
      if (res.success) {
        final s = Set<String>.from(joined.value);
        s.add(groupId);
        joined.value = s;
        _messages.putIfAbsent(
          groupId,
          () => ValueNotifier<List<ChatMessage>>([]),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check membership status for the current user.
  Future<String> getMembershipStatus(String groupId) async {
    try {
      final res = await _api.get('/community/groups/$groupId/membership/me');
      if (res.success && res.data != null) {
        final status = res.data!['status'] as String? ?? 'none';
        if (status == 'active') {
          final s = Set<String>.from(joined.value);
          s.add(groupId);
          joined.value = s;
        }
        return status;
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  // ─── Local chat (no backend endpoint yet) ───

  void joinCommunity(String communityId) {
    final s = Set<String>.from(joined.value);
    s.add(communityId);
    joined.value = s;
    _messages.putIfAbsent(
      communityId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  ValueNotifier<List<ChatMessage>> messagesFor(String communityId) {
    return _messages.putIfAbsent(
      communityId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  void addMessage(String communityId, ChatMessage message) {
    final notifier = messagesFor(communityId);
    final updated = List<ChatMessage>.from(notifier.value)..add(message);
    notifier.value = updated;
  }
}
