import 'package:flutter/foundation.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';
import '../../ai/application/ai_client.dart';

class ChatService {
  ChatService(this._aiConfigCubit);

  final AiConfigCubit _aiConfigCubit;

  Future<Map<String, dynamic>?> sendMessage(List<Map<String, dynamic>> messages) async {
    final aiConfig = _aiConfigCubit.state;
    if (!aiConfig.isConfigured) {
      return {'reply': 'AI feature is disabled. Please configure your API key in Settings.'};
    }

    final aiClient = AiClient(aiConfig);
    try {
      final reply = await aiClient.chat(messages);
      if (reply != null) {
        return {'reply': reply};
      }
    } catch (e) {
      debugPrint('Chat error: $e');
    }
    return null;
  }

  Stream<String> streamMessage(List<Map<String, dynamic>> messages) async* {
    final aiConfig = _aiConfigCubit.state;
    if (!aiConfig.isConfigured) {
      const errorMsg = 'AI feature is disabled. Please configure your API key in Settings.';
      for (final word in errorMsg.split(' ')) {
        await Future.delayed(const Duration(milliseconds: 35));
        yield '$word ';
      }
      return;
    }

    final aiClient = AiClient(aiConfig);
    bool hasYielded = false;
    try {
      await for (final chunk in aiClient.streamChat(messages)) {
        hasYielded = true;
        yield chunk;
      }
    } catch (e) {
      debugPrint('Chat stream error: $e');
    }

    if (!hasYielded) {
      // Fallback to regular chat if stream didn't yield anything
      try {
        final fallbackReply = await aiClient.chat(messages);
        if (fallbackReply != null && fallbackReply.trim().isNotEmpty) {
          yield fallbackReply.trim();
        } else {
          yield 'Unable to get response from AI coach. Please check your network or API key in Settings.';
        }
      } catch (e) {
        yield 'Error connecting to AI service.';
      }
    }
  }
}
