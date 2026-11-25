import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../domain/ai_config.dart';
import '../domain/ai_use_case_select_provider.dart';
import 'ai_response_model_provider_reply.dart';

class AiProviderTransport {
  final AiConfig config;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  AiProviderTransport(this.config);

  String get _model => config.model.isNotEmpty
      ? config.model
      : AiProviderOptions.forProvider(config.provider).defaultModel;

  void close() => _dio.close(force: true);

  Future<String?> chat(List<Map<String, dynamic>> messages) async {
    if (!config.isConfigured) return null;

    try {
      if (config.provider == 'openai') {
        return await _callOpenAI(messages);
      } else if (config.provider == 'gemini') {
        return await _callGemini(messages);
      } else if (config.provider == 'anthropic') {
        return await _callAnthropic(messages);
      }
    } catch (e) {
      debugPrint('AI request failed (${e.runtimeType}).');
    }
    return null;
  }

  Stream<String> streamChat(List<Map<String, dynamic>> messages) async* {
    if (!config.isConfigured) return;

    try {
      if (config.provider == 'openai') {
        yield* _streamOpenAI(messages);
      } else if (config.provider == 'gemini') {
        yield* _streamGemini(messages);
      } else if (config.provider == 'anthropic') {
        yield* _streamAnthropic(messages);
      }
    } catch (e) {
      debugPrint('AI stream failed (${e.runtimeType}).');
    }
  }

  Future<String?> _callOpenAI(List<Map<String, dynamic>> messages) async {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {'model': _model, 'messages': messages},
    );
    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'] as String?;
    }
    return null;
  }

  Stream<String> _streamOpenAI(List<Map<String, dynamic>> messages) async* {
    final response = await _dio.post<ResponseBody>(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {'model': _model, 'messages': messages, 'stream': true},
    );

    final stream = utf8.decoder
        .bind(response.data!.stream)
        .transform(const LineSplitter());
    await for (final line in stream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == 'data: [DONE]') break;
      if (trimmed.startsWith('data: ')) {
        final jsonStr = trimmed.substring(6).trim();
        try {
          final data = jsonDecode(jsonStr);
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta']?['content'];
            if (delta != null && delta is String) {
              yield delta;
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<String?> _callGemini(List<Map<String, dynamic>> messages) async {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemInstruction = msg['content'];
      } else {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        contents.add({
          'role': role,
          'parts': [
            {'text': msg['content']},
          ],
        });
      }
    }

    final modelName = _model;
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${config.apiKey}';

    final payload = <String, dynamic>{'contents': contents};
    if (systemInstruction != null) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction},
        ],
      };
    }

    final response = await _dio.post(
      url,
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: payload,
    );

    if (response.statusCode == 200) {
      return response.data['candidates'][0]['content']['parts'][0]['text']
          as String?;
    }
    return null;
  }

  Stream<String> _streamGemini(List<Map<String, dynamic>> messages) async* {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemInstruction = msg['content'];
      } else {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        contents.add({
          'role': role,
          'parts': [
            {'text': msg['content']},
          ],
        });
      }
    }

    final modelName = _model;
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:streamGenerateContent?alt=sse&key=${config.apiKey}';

    final payload = <String, dynamic>{'contents': contents};
    if (systemInstruction != null) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction},
        ],
      };
    }

    final response = await _dio.post<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Content-Type': 'application/json'},
      ),
      data: payload,
    );

    final stream = utf8.decoder
        .bind(response.data!.stream)
        .transform(const LineSplitter());
    await for (final line in stream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('data: ')) {
        final jsonStr = trimmed.substring(6).trim();
        try {
          final data = jsonDecode(jsonStr);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'];
              if (text != null && text is String) {
                yield text;
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<String?> _callAnthropic(List<Map<String, dynamic>> messages) async {
    final systemPrompt =
        messages.firstWhere(
              (m) => m['role'] == 'system',
              orElse: () => {},
            )['content']
            as String?;
    final filteredMessages = messages
        .where((m) => m['role'] != 'system')
        .map((m) => {'role': m['role'], 'content': m['content']})
        .toList();

    final modelName = _model;

    final payload = <String, dynamic>{
      'model': modelName,
      'messages': filteredMessages,
      'max_tokens': 1000,
    };
    if (systemPrompt != null) {
      payload['system'] = systemPrompt;
    }

    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      ),
      data: payload,
    );

    if (response.statusCode == 200) {
      return response.data['content'][0]['text'] as String?;
    }
    return null;
  }

  Stream<String> _streamAnthropic(List<Map<String, dynamic>> messages) async* {
    final systemPrompt =
        messages.firstWhere(
              (m) => m['role'] == 'system',
              orElse: () => {},
            )['content']
            as String?;
    final filteredMessages = messages
        .where((m) => m['role'] != 'system')
        .map((m) => {'role': m['role'], 'content': m['content']})
        .toList();

    final modelName = _model;

    final payload = <String, dynamic>{
      'model': modelName,
      'messages': filteredMessages,
      'max_tokens': 1000,
      'stream': true,
    };
    if (systemPrompt != null) {
      payload['system'] = systemPrompt;
    }

    final response = await _dio.post<ResponseBody>(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
      ),
      data: payload,
    );

    final stream = utf8.decoder
        .bind(response.data!.stream)
        .transform(const LineSplitter());
    await for (final line in stream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('data: ')) {
        final jsonStr = trimmed.substring(6).trim();
        try {
          final data = jsonDecode(jsonStr);
          if (data['type'] == 'content_block_delta') {
            final text = data['delta']?['text'];
            if (text != null && text is String) {
              yield text;
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<AiConnectionResponseModel> testConnection() async {
    final key = config.apiKey.trim();
    if (key.isEmpty) {
      return const AiConnectionResponseModel(
        success: false,
        message: 'API key is empty. Please enter an API key first.',
      );
    }

    try {
      if (config.provider == 'openai') {
        return await _testOpenAI();
      } else if (config.provider == 'gemini') {
        return await _testGemini();
      } else if (config.provider == 'anthropic') {
        return await _testAnthropic();
      } else {
        return AiConnectionResponseModel(
          success: false,
          message: 'Unsupported provider: ${config.provider}',
        );
      }
    } catch (e) {
      return AiConnectionResponseModel(
        success: false,
        message: _formatTestError(e),
      );
    }
  }

  Future<AiConnectionResponseModel> _testOpenAI() async {
    final model = _model;
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
      data: {
        'model': model,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
        'max_tokens': 5,
      },
    );

    if (response.statusCode == 200) {
      return AiConnectionResponseModel(
        success: true,
        message: 'Connected to OpenAI ($model)',
      );
    }
    return AiConnectionResponseModel(
      success: false,
      message: 'OpenAI returned status ${response.statusCode}',
    );
  }

  Future<AiConnectionResponseModel> _testGemini() async {
    final modelName = _model;
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${config.apiKey.trim()}';

    final response = await _dio.post(
      url,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': 'Hi'},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 5},
      },
    );

    if (response.statusCode == 200) {
      return AiConnectionResponseModel(
        success: true,
        message: 'Connected to Gemini ($modelName)',
      );
    }
    return AiConnectionResponseModel(
      success: false,
      message: 'Gemini returned status ${response.statusCode}',
    );
  }

  Future<AiConnectionResponseModel> _testAnthropic() async {
    final modelName = _model;
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.apiKey.trim(),
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
      data: {
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
        'max_tokens': 5,
      },
    );

    if (response.statusCode == 200) {
      return AiConnectionResponseModel(
        success: true,
        message: 'Connected to Anthropic ($modelName)',
      );
    }
    return AiConnectionResponseModel(
      success: false,
      message: 'Anthropic returned status ${response.statusCode}',
    );
  }

  String _formatTestError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['error'] is Map && data['error']['message'] != null) {
            return '${data['error']['message']}';
          }
          if (data['error'] is String) {
            return data['error'] as String;
          }
          if (data['message'] is String) {
            return data['message'] as String;
          }
        }
        final code = e.response?.statusCode;
        if (code == 401) return 'Invalid API Key (401 Unauthorized)';
        if (code == 403) return 'Forbidden: Check API Key permissions (403)';
        if (code == 404) return 'Model or endpoint not found (404)';
        if (code == 429) return 'Rate limit exceeded or quota exhausted (429)';
        return 'Request failed with status $code';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Check your internet connection.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Network error. Could not reach AI server.';
      }
      return e.message ?? 'Unknown connection error';
    }
    return e.toString();
  }
}
