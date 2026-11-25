class AiProviderOptions {
  const AiProviderOptions(this.id, this.label, this.models);

  final String id;
  final String label;
  final List<String> models;

  String get defaultModel => models.first;

  static const all = [
    AiProviderOptions('openai', 'OpenAI', [
      'gpt-5',
      'gpt-5-mini',
      'gpt-5-pro',
      'gpt-4o',
      'o3-mini',
    ]),
    AiProviderOptions('gemini', 'Google Gemini', [
      'gemini-3.8-flash',
      'gemini-3.8-flash-lite',
      'gemini-3.8-pro',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
    ]),
    AiProviderOptions('anthropic', 'Anthropic', [
      'claude-5-sonnet',
      'claude-5-opus',
      'claude-4-5-haiku',
      'claude-3-7-sonnet',
      'claude-3-5-sonnet',
      'claude-3-5-haiku',
    ]),
  ];

  static AiProviderOptions forProvider(String id) =>
      all.firstWhere((provider) => provider.id == id, orElse: () => all.first);

  List<String> includingSavedModel(String model) =>
      models.contains(model) ? models : [...models, model];
}
