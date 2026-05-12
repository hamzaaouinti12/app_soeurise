import '../models/models.dart';
import 'api_client.dart';

class EventService {
  static final EventService instance = EventService._internal();
  EventService._internal();

  /// Fetch all events
  Future<List<Event>> fetchEvents() async {
    try {
      final response = await ApiClient.instance.get('/events');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Event.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  /// Create a new event (Admin only)
  Future<bool> createEvent({
    required String title,
    required DateTime dateTime,
    required String type,
    required String location,
    String imageUrl = '',
  }) async {
    try {
      final response = await ApiClient.instance.post('/events', {
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'type': type,
        'location': location,
        'imageUrl': imageUrl,
      });
      return response.success;
    } catch (e) {
      print('Error creating event: $e');
      return false;
    }
  }
}
