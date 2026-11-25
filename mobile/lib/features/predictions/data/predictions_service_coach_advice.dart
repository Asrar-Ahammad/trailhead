import '../../ai/domain/ai_config.dart';
import '../../ai/domain/ai_repository_provider_reply.dart';
import 'predictions_request_model_coach_advice.dart';
import 'predictions_response_model_coach_advice.dart';

class PredictionsCoachAdviceService {
  const PredictionsCoachAdviceService(this._ai);

  final AiReplyRepository _ai;

  Future<PredictionsCoachAdviceResponseModel> fetch(
    AiConfig config,
    PredictionsCoachAdviceRequestModel request,
  ) async {
    final advice = await _ai.complete(config, [
      for (final message in request.toMessages())
        (role: message['role']!, content: message['content']!),
    ]);
    return PredictionsCoachAdviceResponseModel(advice);
  }
}
