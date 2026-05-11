import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'profile_service.dart';
class ChatMessage {
  final String senderId;
  final String sender;
  final String senderAvatar;
  final String text;
  final String type;
  final String mediaUrl;
  final String mediaMime;
  final int? audioDurationMs;
  final DateTime timestamp;

  ChatMessage({
    this.senderId = '',
    required this.sender,
    this.senderAvatar = '',
    required this.text,
    this.type = 'text',
    this.mediaUrl = '',
    this.mediaMime = '',
    this.audioDurationMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'sender': sender,
        'senderAvatar': senderAvatar,
        'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'mediaMime': mediaMime,
      'audioDurationMs': audioDurationMs,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final dynamic ts = json['timestamp'];
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

  String get _currentUserId => ProfileService.instance.profile.value.id;

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
        
        // Reverse if backend sends newest first, but backend already reversed it.
        // Actually the backend mapping returns old-to-new. Let's just assign.
        final notifier = messagesFor(communityId);
        notifier.value = parsed;
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  /// Send a message to the backend
  Future<bool> sendMessage(String communityId, String text) async {
    try {
      final res = await _api.post('/community/groups/$communityId/messages', {
        'text': text,
      });
      if (res.success && res.data != null) {
        final newMsg = ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
        final notifier = messagesFor(communityId);
        final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
        notifier.value = updated;
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
    File file, {
    String? text,
    int? audioDurationMs,
  }) async {
    try {
      final fields = <String, String>{};
      if (text != null && text.trim().isNotEmpty) {
        fields['text'] = text.trim();
      }
      if (audioDurationMs != null) {
        fields['audioDurationMs'] = audioDurationMs.toString();
      }

      final res = await _api.multipartRequest(
        'POST',
        '/community/groups/$communityId/messages',
        fields: fields,
        fileField: 'media',
        filePath: file.path,
      );
      if (res.success && res.data != null) {
        final newMsg = ChatMessage.fromJson(
          res.data!['message'] as Map<String, dynamic>,
        );
        final notifier = messagesFor(communityId);
        final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
        notifier.value = updated;
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
    if (notifier.value.any(
      (m) =>
          m.senderId == newMsg.senderId &&
          m.text == newMsg.text &&
          m.mediaUrl == newMsg.mediaUrl &&
          (m.timestamp.difference(newMsg.timestamp).inSeconds.abs() < 5),
    )) {
      return;
    }
    
    final updated = List<ChatMessage>.from(notifier.value)..add(newMsg);
    notifier.value = updated;
  }
}
