class AiConfig {
  final String provider;
  final String model;
  final String apiKey;

  const AiConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
  });

  bool get isConfigured => apiKey.isNotEmpty;
}
