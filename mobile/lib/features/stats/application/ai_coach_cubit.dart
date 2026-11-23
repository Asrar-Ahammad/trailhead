import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/state/app_cubits.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';

class AiCoachData {
  final String coachingFeedback;
  final String? fatigueFlag;

  AiCoachData({required this.coachingFeedback, this.fatigueFlag});
}

class AiCoachCubit extends Cubit<AsyncState<AiCoachData>> {
  AiCoachCubit({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const AsyncState.loading()) {
    load();
  }

  final ApiClient _apiClient;

  Future<void> load() async {
    try {
      final tz = DateTime.now().timeZoneName;
      final response = await _apiClient.client.get('/summary/weekly?tz=$tz');
      if (response.statusCode == 200 && response.data != null) {
        emit(AsyncState.data(AiCoachData(
          coachingFeedback: response.data['coachingFeedback'] as String? ??
              'Start your run streak! Log your first workout of the week to stay active.',
          fatigueFlag: response.data['fatigueFlag'] as String?,
        )));
      } else {
        emit(AsyncState.data(AiCoachData(coachingFeedback: 'Keep running to unlock insights!')));
      }
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}
