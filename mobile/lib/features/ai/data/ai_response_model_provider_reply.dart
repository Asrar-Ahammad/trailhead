class AiProviderReplyResponseModel {
  const AiProviderReplyResponseModel(this.text);

  final String text;
}

class AiConnectionResponseModel {
  const AiConnectionResponseModel({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}
