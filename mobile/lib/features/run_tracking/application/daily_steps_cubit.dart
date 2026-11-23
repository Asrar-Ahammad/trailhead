import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/daily_steps_isar.dart';

import '../../../shared/state/app_cubits.dart';

class DailyStepsCubit extends Cubit<AsyncState<int>> {
  DailyStepsCubit({required Isar isar})
    : _isar = isar,
      super(const AsyncState.loading());

  final Isar _isar;
  String? _dateKey;

  Future<void> load(String dateKey) async {
    if (_dateKey == dateKey && state.status != AsyncStatus.error) return;
    _dateKey = dateKey;
    emit(const AsyncState.loading());
    try {
      final record = await _isar.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(dateKey)
          .findFirst();
      emit(AsyncState.data(record?.steps ?? 0));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}
