import 'dart:io';
import '../models/models.dart';
import 'api_client.dart';

class MessageService {
  MessageService._internal();
  static final MessageService instance = MessageService._internal();

  final _api = ApiClient.instance;

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

  Future<List<PrivateMessage>> fetchChat(String otherUserId, {int limit = 50}) async {
    try {
      final res = await _api.get('/messages/chat/$otherUserId?limit=$limit');
      if (res.success && res.data != null) {
        final list = res.data!['messages'] as List? ?? [];
        return list
            .map((e) => PrivateMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PrivateMessage?> sendTextMessage(String recipientId, String text) async {
    try {
      final res = await _api.post('/messages/send', {
        'recipientId': recipientId,
        'text': text,
      });
      if (res.success && res.data != null) {
        return PrivateMessage.fromJson(res.data!['message']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PrivateMessage?> sendMediaMessage(
    String recipientId,
    File file, {
    String? text,
    int? audioDurationMs,
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

      final res = await _api.multipartRequest(
        'POST',
        '/messages/send',
        fields: fields,
        fileField: 'media',
        filePath: file.path,
      );
      if (res.success && res.data != null) {
        return PrivateMessage.fromJson(res.data!['message']);
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
}
