import '../models/models.dart';
import 'api_client.dart';

class MasterclassService {
  static final MasterclassService instance = MasterclassService._internal();
  MasterclassService._internal();

  /// Fetch all masterclasses
  Future<List<Masterclass>> fetchMasterclasses() async {
    try {
      final response = await ApiClient.instance.get('/masterclasses');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Masterclass.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching masterclasses: $e');
      return [];
    }
  }
}
