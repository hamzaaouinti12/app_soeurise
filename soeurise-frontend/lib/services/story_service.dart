import 'dart:io' if (dart.library.html) 'package:soeurise/src/file_stub.dart';
import '../models/models.dart';
import 'api_client.dart';

class StoryService {
  static final StoryService instance = StoryService._internal();
  StoryService._internal();

  Future<List<Story>> fetchStories() async {
    try {
      final response = await ApiClient.instance.get('/stories');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Story.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching stories: $e');
      return [];
    }
  }

  Future<List<Story>> fetchUserStories(String userId) async {
    try {
      final response = await ApiClient.instance.get('/stories/user/$userId');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Story.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching user stories: $e');
      return [];
    }
  }

  Future<Story?> createStory({
    File? mediaFile,
    List<int>? mediaBytes,
    String? mediaFileName,
    required String mediaType,
    String? caption,
  }) async {
    try {
      final fields = {
        'mediaType': mediaType,
        if (caption != null) 'caption': caption,
      };

      final response = await ApiClient.instance.multipartPost(
        '/stories',
        fields: fields,
        file: mediaFile,
        fileField: 'media',
        fileBytes: mediaBytes,
        fileName: mediaFileName,
      );

      if (response.success && response.data != null) {
        return Story.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error creating story: $e');
      return null;
    }
  }

  Future<bool> addView(String storyId) async {
    try {
      final response = await ApiClient.instance.post('/stories/$storyId/view');
      return response.success;
    } catch (e) {
      print('Error adding story view: $e');
      return false;
    }
  }

  Future<bool> reactToStory(String storyId, String type) async {
    try {
      final response = await ApiClient.instance.post(
        '/stories/$storyId/reactions',
        {'type': type},
      );
      return response.success;
    } catch (e) {
      print('Error reacting to story: $e');
      return false;
    }
  }

  Future<List<StoryViewer>> fetchViewers(String storyId) async {
    try {
      final response = await ApiClient.instance.get('/stories/$storyId/views');
      if (response.success && response.data != null) {
        final raw = response.data;
        final list = raw is List
            ? raw
            : (raw is Map<String, dynamic> ? raw['viewers'] as List? : null) ??
                [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => StoryViewer.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching story viewers: $e');
      return [];
    }
  }

  Future<(bool, String?)> deleteStory(String storyId) async {
    try {
      final response = await ApiClient.instance.delete('/stories/$storyId');
      if (response.success) {
        return (true, null);
      } else {
        final errorMessage = response.errorMessage;
        return (false, errorMessage);
      }
    } catch (e) {
      print('Error deleting story: $e');
      return (false, 'Erreur de connexion: $e');
    }
  }
}
