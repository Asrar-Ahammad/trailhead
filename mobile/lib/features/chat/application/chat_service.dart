import 'package:trailhead_mobile/features/sync/data/api_client.dart';

class ChatService {
  final ApiClient _apiClient;
  
  ChatService(this._apiClient);

  Future<Map<String, dynamic>?> sendMessage(List<Map<String, dynamic>> messages) async {
    final client = _apiClient.client;
    try {
      final response = await client.post('/chat', data: {'messages': messages});
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Chat error: $e');
    }
    return null;
  }
}
