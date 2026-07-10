import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';

class AiCoachData {
  final String coachingFeedback;
  final String? fatigueFlag;

  AiCoachData({required this.coachingFeedback, this.fatigueFlag});
}

final aiCoachProvider = FutureProvider<AiCoachData>((ref) async {
  final client = ref.read(apiClientProvider).client;
  
  // Get timezone string
  final tz = DateTime.now().timeZoneName;
  
  final response = await client.get('/summary/weekly?tz=\$tz');
  
  if (response.statusCode == 200 && response.data != null) {
    return AiCoachData(
      coachingFeedback: response.data['coachingFeedback'] as String? ?? "Start your run streak! Log your first workout of the week to stay active.",
      fatigueFlag: response.data['fatigueFlag'] as String?,
    );
  }
  
  return AiCoachData(coachingFeedback: "Keep running to unlock insights!");
});
