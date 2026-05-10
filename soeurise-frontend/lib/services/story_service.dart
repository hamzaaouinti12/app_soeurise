import 'dart:io';
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
    required File mediaFile,
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

  Future<(bool, String?)> deleteStory(String storyId) async {
    try {
      final response = await ApiClient.instance.delete('/stories/$storyId');
      if (response.success) {
        return (true, null);
      } else {
        final errorMessage = response.errorMessage ?? 'Erreur inconnue';
        return (false, errorMessage);
      }
    } catch (e) {
      print('Error deleting story: $e');
      return (false, 'Erreur de connexion: $e');
    }
  }
}
