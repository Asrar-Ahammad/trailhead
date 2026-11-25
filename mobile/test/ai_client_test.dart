import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/ai/application/ai_client.dart';
import 'package:trailhead_mobile/features/ai/application/ai_config_provider.dart';

void main() {
  test('Native reply worker closes cleanly without an API key', () async {
    const client = AiClient(
      AiConfig(provider: 'openai', model: 'gpt-5', apiKey: ''),
    );
    expect(await client.streamChat([]).toList(), isEmpty);
  });

  group('AiClient.testConnection Tests', () {
    test('Fails immediately when API key is empty', () async {
      final config = AiConfig(
        provider: 'openai',
        model: 'gpt-4o-mini',
        apiKey: '',
      );
      final client = AiClient(config);
      final result = await client.testConnection();

      expect(result.success, isFalse);
      expect(result.message, contains('API key is empty'));
    });

    test('Fails immediately when API key contains only whitespace', () async {
      final config = AiConfig(
        provider: 'gemini',
        model: 'gemini-2.0-flash',
        apiKey: '   ',
      );
      final client = AiClient(config);
      final result = await client.testConnection();

      expect(result.success, isFalse);
      expect(result.message, contains('API key is empty'));
    });

    test('Fails when provider is unsupported', () async {
      final config = AiConfig(
        provider: 'custom_unknown_provider',
        model: 'custom_model',
        apiKey: 'sk-test-fake-key-12345',
      );
      final client = AiClient(config);
      final result = await client.testConnection();

      expect(result.success, isFalse);
      expect(result.message, contains('Unsupported provider'));
    });

    test('AiTestResult models status and message correctly', () {
      const successResult = AiTestResult(
        success: true,
        message: 'Connected successfully',
      );
      expect(successResult.success, isTrue);
      expect(successResult.message, 'Connected successfully');

      const failureResult = AiTestResult(
        success: false,
        message: 'Invalid API key',
      );
      expect(failureResult.success, isFalse);
      expect(failureResult.message, 'Invalid API key');
    });
  });
}
