import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';

final chatServiceProvider = Provider((ref) => ChatService(ref));

class ChatService {
  final Ref _ref;
  
  ChatService(this._ref);

  Future<Map<String, dynamic>?> sendMessage(List<Map<String, dynamic>> messages) async {
    final client = _ref.read(apiClientProvider).client;
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
