import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'profile_service.dart';

class MessageService {
  MessageService._internal();
  static final MessageService instance = MessageService._internal();

  final _api = ApiClient.instance;
  final Map<String, List<PrivateMessage>> _messages = {};

  Future<void> loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Prioritize ID from ProfileService if available
    String uid = ProfileService.instance.profile.value.id;
    if (uid.isEmpty) {
      uid = prefs.getString('current_user_id') ?? 'unknown';
    }
    
    _messages.clear(); // Clear existing in-memory state before loading
    final keys = prefs.getKeys().where((k) => k.startsWith('chat_${uid}_'));
    for (final key in keys) {
      try {
        final otherUserId = key.replaceFirst('chat_${uid}_', '');
        final msgsJson = prefs.getStringList(key) ?? [];
        final msgs = msgsJson.map((e) => PrivateMessage.fromJson(jsonDecode(e))).toList();
        _messages[otherUserId] = msgs;
      } catch (e) {
        print('Error loading cached chat for key $key: $e');
      }
    }
  }

  List<PrivateMessage> getCachedChat(String otherUserId) {
    return _messages[otherUserId] ?? [];
  }

  Future<List<Conversation>> fetchConversations() async {
    try {
      final res = await _api.get('/messages/conversations');
      if (res.success && res.data != null) {
        final list = res.data!['conversations'] as List? ?? [];
        return list
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PrivateMessage>?> fetchChat(String otherUserId, {int limit = 50}) async {
    try {
      final res = await _api.get('/messages/chat/$otherUserId?limit=$limit');
      if (res.success && res.data != null) {
        final list = res.data!['messages'] as List? ?? [];
        final parsed = list
            .map((e) => PrivateMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        _messages[otherUserId] = parsed;
        _saveChat(otherUserId, parsed);
        return parsed;
      }
      return null; // Return null on business logic failure (e.g. 401, 404)
    } catch (e, stack) {
      print('Error fetching chat for $otherUserId: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  Future<PrivateMessage?> sendTextMessage(String recipientId, String text, {String? replyToId, String? storyImageUrl}) async {
    try {
      final payload = <String, dynamic>{
        'recipientId': recipientId,
        'text': text,
      };
      if (replyToId != null) payload['replyTo'] = replyToId;
      if (storyImageUrl != null) payload['storyImageUrl'] = storyImageUrl;

      final res = await _api.post('/messages/send', payload);
      if (res.success && res.data != null) {
        final msg = PrivateMessage.fromJson(res.data!['message']);
        final current = _messages[recipientId] ?? [];
        _messages[recipientId] = [...current, msg];
        _saveChat(recipientId, _messages[recipientId]!);
        return msg;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PrivateMessage?> sendMediaMessage(
    String recipientId,
    String mediaFilePath, {
    String? text,
    int? audioDurationMs,
    String? replyToId,
  }) async {
    try {
      final fields = <String, String>{
        'recipientId': recipientId,
      };
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
        '/messages/send',
        fields: fields,
        fileField: 'media',
        filePath: mediaFilePath,
      );
      if (res.success && res.data != null) {
        final msg = PrivateMessage.fromJson(res.data!['message']);
        final current = _messages[recipientId] ?? [];
        _messages[recipientId] = [...current, msg];
        _saveChat(recipientId, _messages[recipientId]!);
        return msg;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> markChatRead(String otherUserId) async {
    try {
      await _api.post('/messages/chat/$otherUserId/read');
    } catch (_) {
      // ignore
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      final res = await _api.post('/messages/$messageId/delete');
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<PrivateMessage?> editMessage(String messageId, String newText) async {
    try {
      final res = await _api.post('/messages/$messageId/edit', {
        'newText': newText,
      });
      if (res.success && res.data != null) {
        return PrivateMessage.fromJson(res.data!['message']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PrivateMessage?> reactToMessage(String messageId, String reactionType) async {
    try {
      final res = await _api.post('/messages/$messageId/react', {
        'reactionType': reactionType,
      });
      if (res.success && res.data != null) {
        return PrivateMessage.fromJson(res.data!['message']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveChat(String otherUserId, List<PrivateMessage> msgs) async {
    final prefs = await SharedPreferences.getInstance();
    String uid = ProfileService.instance.profile.value.id;
    if (uid.isEmpty) {
      uid = prefs.getString('current_user_id') ?? 'unknown';
    }

    // Keep only last 50 messages
    final toSave = msgs.length > 50 ? msgs.sublist(msgs.length - 50) : msgs;
    final jsonList = toSave.map((m) => jsonEncode(m.toJson())).toList();

    await prefs.setStringList('chat_${uid}_$otherUserId', jsonList);
  }

  void addMessageFromSocket(String otherUserId, PrivateMessage msg) {
    final current = _messages[otherUserId] ?? [];
    if (current.any((m) => m.id == msg.id)) return;

    final updated = [...current, msg];
    _messages[otherUserId] = updated;
    _saveChat(otherUserId, updated);
  }
}
