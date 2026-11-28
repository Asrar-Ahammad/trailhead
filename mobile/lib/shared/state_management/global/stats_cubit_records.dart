import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_repository_personal_records.dart';
import '../async_value.dart';

class StatsRecordsCubit extends Cubit<AsyncValue<RecordGroup>> {
  StatsRecordsCubit(this.watch) : super(const AsyncValue.loading()) {
    _subscription = watch().listen(
      (group) => emit(AsyncValue.data(group)),
      onError: (Object error, StackTrace trace) =>
          emit(AsyncValue.error(error, trace)),
    );
  }

  final Stream<RecordGroup> Function() watch;

  Future<void> refresh() async {
    final before = state;
    try {
      final value = await watch().first;
      if (!isClosed && identical(state, before)) emit(AsyncValue.data(value));
    } catch (error, trace) {
      if (!isClosed && identical(state, before))
        emit(AsyncValue.error(error, trace));
    }
  }

  late final StreamSubscription<RecordGroup> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
