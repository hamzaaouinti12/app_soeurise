import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'profile_service.dart';
class ChatMessage {
  final String id;
  final String senderId;
  final String sender;
  final String senderAvatar;
  final String text;
  final String type;
  final String mediaUrl;
  final String mediaMime;
  final int? audioDurationMs;
  final DateTime timestamp;
  final List<String> seenBy;
  final int seenCount;
  final ChatMessage? replyTo;
  final bool isEdited;
  final DateTime? editedAt;
  final List<Map<String, dynamic>> reactions;

  ChatMessage({
    this.id = '',
    this.senderId = '',
    required this.sender,
    this.senderAvatar = '',
    required this.text,
    this.type = 'text',
    this.mediaUrl = '',
    this.mediaMime = '',
    this.audioDurationMs,
    this.seenBy = const [],
    this.seenCount = 0,
    this.replyTo,
    this.isEdited = false,
    this.editedAt,
    this.reactions = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'sender': sender,
        'senderAvatar': senderAvatar,
        'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
        'mediaMime': mediaMime,
        'audioDurationMs': audioDurationMs,
        'seenBy': seenBy,
        'seenCount': seenCount,
        'replyTo': replyTo?.toJson(),
        'isEdited': isEdited,
        'editedAt': editedAt?.toIso8601String(),
        'reactions': reactions,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final dynamic ts = json['timestamp'] ?? json['createdAt'];
    DateTime parsedDate;
    if (ts is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawMedia = json['mediaUrl']?.toString() ?? '';

    return ChatMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'Inconnu',
      senderAvatar: json['senderAvatar']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      mediaUrl: rawMedia.isNotEmpty ? ApiConfig.uploadsUrl(rawMedia) : '',
      mediaMime: json['mediaMime']?.toString() ?? '',
      audioDurationMs: json['audioDurationMs'] is int
          ? json['audioDurationMs'] as int
          : int.tryParse(json['audioDurationMs']?.toString() ?? ''),
      seenBy: (json['seenBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      seenCount: json['seenCount'] as int? ?? 0,
      replyTo: (json['replyTo'] != null && json['replyTo'] is Map<String, dynamic>)
          ? ChatMessage.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      isEdited: json['isEdited'] == true,
      editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt']) : null,
      reactions: (json['reactions'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      timestamp: parsedDate,
    );
  }
}

class CommunityService {
  CommunityService._private();
  static final CommunityService instance = CommunityService._private();

  final _api = ApiClient.instance;
  final ValueNotifier<Set<String>> joined = ValueNotifier(<String>{});
  final Map<String, ValueNotifier<List<ChatMessage>>> _messages = {};

  bool isMember(String communityId) => joined.value.contains(communityId);

  String get currentUserId => ProfileService.instance.profile.value.id;
  String get _currentUserId => currentUserId;

  // ─── Local State Persistence ───

  Future<void> loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUserId;
    if (uid.isEmpty) return;

    final joinedList = prefs.getStringList('joined_$uid') ?? [];
    joined.value = joinedList.toSet();

    _messages.clear();
    for (final groupId in joinedList) {
      final msgsJson = prefs.getStringList('msgs_${uid}_$groupId') ?? [];
      final msgs = msgsJson.map((e) => ChatMessage.fromJson(jsonDecode(e))).toList();
      _messages[groupId] = ValueNotifier(msgs);
    }
  }

  Future<void> saveJoinedState() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _currentUserId;
    if (uid.isEmpty) return;
    await prefs.setStringList('joined_$uid', joined.value.toList());
  }

  void clear() {
    joined.value = <String>{};
    _messages.clear();
  }

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
        
        final s = Set<String>.from(joined.value);
        bool changed = false;
        
        final parsedGroups = groups.map((g) {
          final isMember = g['isMember'] == true;
          final id = g['id']?.toString() ?? g['_id']?.toString() ?? '';
          if (isMember && !s.contains(id) && id.isNotEmpty) {
            s.add(id);
            changed = true;
          }
          return Community.fromJson(g as Map<String, dynamic>);
        }).toList();
        
        if (changed) {
          joined.value = s;
          saveJoinedState();
        }
        
        return parsedGroups;
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
        saveJoinedState();
        _messages.putIfAbsent(
          groupId,
          () => ValueNotifier<List<ChatMessage>>([]),
        );
        return true;
      } else if (res.errorMessage.toLowerCase().contains('déjà membre') || res.errorMessage.toLowerCase().contains('déjà un membre')) {
        final s = Set<String>.from(joined.value);
        s.add(groupId);
        joined.value = s;
        saveJoinedState();
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

  /// Create a new community group.
  Future<Community?> createGroup({
    required String name,
    required String description,
    bool isPublic = true,
  }) async {
    try {
      final res = await _api.post('/community/groups', {
        'name': name,
        'description': description,
        'isPublic': isPublic,
      });
      if (res.success && res.data != null) {
        final raw = res.data!['group'] ?? res.data!['community'] ?? res.data;
        if (raw is Map<String, dynamic>) {
          return Community.fromJson(raw);
        }
      }
      return null;
    } catch (_) {
      return null;
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
          if (!s.contains(groupId)) {
            s.add(groupId);
            joined.value = s;
            saveJoinedState();
          }
        }
        return status;
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  // ─── Chat Messages ───

  ValueNotifier<List<ChatMessage>> messagesFor(String communityId) {
    return _messages.putIfAbsent(
      communityId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  /// Fetch messages from the backend
  Future<void> fetchMessages(String communityId) async {
    try {
      final res = await _api.get('/community/groups/$communityId/messages?limit=50');
      if (res.success && res.data != null) {
        final msgsList = res.data!['messages'] as List? ?? [];
        final parsed = msgsList.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
        
        final notifier = messagesFor(communityId);
        notifier.value = parsed;
        _saveMessages(communityId, parsed);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  /// Mark all unread messages as read in a group
  Future<void> markMessagesRead(String communityId) async {
    try {
      await _api.post('/community/groups/$communityId/messages/read');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Send a message to the backend
  Future<bool> sendMessage(String communityId, String text, {String? replyToId}) async {
    try {
      final payload = <String, dynamic>{
        'text': text,
      };
      if (replyToId != null) payload['replyTo'] = replyToId;

      final res = await _api.post('/community/groups/$communityId/messages', payload);
      if (res.success && res.data != null) {
        final newMsg = ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
        final notifier = messagesFor(communityId);
        final exists = notifier.value.any((m) => 
          (m.id.isNotEmpty && m.id == newMsg.id) ||
          (m.senderId == newMsg.senderId && m.text == newMsg.text && (m.timestamp.difference(newMsg.timestamp).inSeconds.abs() < 5))
        );
        if (!exists) {
          final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
          notifier.value = updated;
          _saveMessages(communityId, updated);
        }
        return true;
      }
      debugPrint('Failed to send message: ${res.errorMessage}');
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Send a media message to the backend
  Future<bool> sendMediaMessage(
    String communityId,
    String mediaFilePath, {
    String? text,
    int? audioDurationMs,
    String? replyToId,
  }) async {
    try {
      final fields = <String, String>{};
      if (text != null && text.trim().isNotEmpty) {
        fields['text'] = text.trim();
      }
      if (audioDurationMs != null) {
        fields['audioDurationMs'] = audioDurationMs.toString();
      }
      if (replyToId != null) {
        fields['replyTo'] = replyToId;
      }

      final res = await _api.multipartRequest(
        'POST',
        '/community/groups/$communityId/messages',
        fields: fields,
        fileField: 'media',
        filePath: mediaFilePath,
      );
      if (res.success && res.data != null) {
        final newMsg = ChatMessage.fromJson(
          res.data!['message'] as Map<String, dynamic>,
        );
        final notifier = messagesFor(communityId);
        if (!notifier.value.any((m) => m.id == newMsg.id && m.id.isNotEmpty)) {
          final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
          notifier.value = updated;
        }
        return true;
      }
      debugPrint('Failed to send media: ${res.errorMessage}');
      return false;
    } catch (e) {
      debugPrint('Error sending media: $e');
      return false;
    }
  }

  /// Add a message received from socket
  void addMessageFromSocket(String communityId, Map<String, dynamic> data) {
    final newMsg = ChatMessage.fromJson(data);
    final notifier = messagesFor(communityId);
    
    // Check if message already exists (to avoid duplicates from own sent messages)
    if (notifier.value.any((m) {
      if (m.id.isNotEmpty && newMsg.id.isNotEmpty) {
        return m.id == newMsg.id;
      }
      return m.senderId == newMsg.senderId &&
          m.text == newMsg.text &&
          m.mediaUrl == newMsg.mediaUrl &&
          (m.timestamp.difference(newMsg.timestamp).inSeconds.abs() < 5);
    })) {
      return;
    }
    
    final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
    notifier.value = updated;
    _saveMessages(communityId, updated);
  }

  Future<void> _saveMessages(String communityId, List<ChatMessage> msgs) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('current_user_id') ?? 'unknown';
    
    // Keep only last 50 messages for local storage to save space
    final toSave = msgs.length > 50 ? msgs.sublist(msgs.length - 50) : msgs;
    final jsonList = toSave.map((m) => jsonEncode(m.toJson())).toList();
    
    await prefs.setStringList('msgs_${uid}_$communityId', jsonList);
  }

  /// Remove a message by id (called after socket event group_message_deleted)
  void removeMessageFromSocket(String communityId, String messageId) {
    final notifier = messagesFor(communityId);
    notifier.value = notifier.value.where((m) => m.id != messageId).toList();
  }

  /// Update a message from socket (called after group_message_edited or group_message_reacted)
  void updateMessageFromSocket(String communityId, Map<String, dynamic> data) {
    final updatedMsg = ChatMessage.fromJson(data);
    final notifier = messagesFor(communityId);
    final idx = notifier.value.indexWhere((m) => m.id == updatedMsg.id);
    if (idx != -1) {
      final updatedList = List<ChatMessage>.from(notifier.value);
      updatedList[idx] = updatedMsg;
      notifier.value = updatedList;
    }
  }

  // ─── Group Management API ───

  /// Fetch all active members of a group with their roles.
  Future<List<GroupMember>> fetchGroupMembers(String groupId) async {
    try {
      final res = await _api.get('/community/groups/$groupId/members');
      if (res.success && res.data != null) {
        final list = res.data!['members'] as List? ?? [];
        return list
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('fetchGroupMembers error: $e');
      return [];
    }
  }

  /// Get the current user's role in a group. Returns 'none' if not a member.
  Future<String> getMyRole(String groupId) async {
    try {
      final res = await _api.get('/community/groups/$groupId/membership/me');
      if (res.success && res.data != null) {
        return res.data!['roleInGroup'] as String? ?? 'none';
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  /// Update group info (admin only).
  Future<bool> updateGroupInfo(
    String groupId, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (isPublic != null) body['isPublic'] = isPublic;

      final res = await _api.patch('/community/groups/$groupId', body);
      return res.success;
    } catch (e) {
      debugPrint('updateGroupInfo error: $e');
      return false;
    }
  }

  /// Update a member's role (admin only). memberId = GroupMember document id.
  Future<bool> updateMemberRole(
    String groupId,
    String memberId,
    String roleInGroup,
  ) async {
    try {
      final res = await _api.patch(
        '/community/groups/$groupId/members/$memberId',
        {'roleInGroup': roleInGroup},
      );
      return res.success;
    } catch (e) {
      debugPrint('updateMemberRole error: $e');
      return false;
    }
  }

  /// Remove a member from the group (admin only). memberId = GroupMember document id.
  Future<bool> kickMember(String groupId, String memberId) async {
    try {
      final res = await _api.delete(
        '/community/groups/$groupId/members/$memberId',
      );
      return res.success;
    } catch (e) {
      debugPrint('kickMember error: $e');
      return false;
    }
  }

  /// Delete a group message (admin only).
  Future<bool> deleteGroupMessage(String groupId, String messageId) async {
    try {
      final res = await _api.delete(
        '/community/groups/$groupId/messages/$messageId',
      );
      if (res.success) {
        removeMessageFromSocket(groupId, messageId);
      }
      return res.success;
    } catch (e) {
      debugPrint('deleteGroupMessage error: $e');
      return false;
    }
  }

  Future<ChatMessage?> editGroupMessage(String groupId, String messageId, String newText) async {
    try {
      final res = await _api.post(
        '/community/groups/$groupId/messages/$messageId/edit',
        {'newText': newText},
      );
      if (res.success && res.data != null) {
        return ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('editGroupMessage error: $e');
      return null;
    }
  }

  Future<ChatMessage?> reactToGroupMessage(String groupId, String messageId, String reactionType) async {
    try {
      final res = await _api.post(
        '/community/groups/$groupId/messages/$messageId/react',
        {'reactionType': reactionType},
      );
      if (res.success && res.data != null) {
        return ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('reactToGroupMessage error: $e');
      return null;
    }
  }
}
