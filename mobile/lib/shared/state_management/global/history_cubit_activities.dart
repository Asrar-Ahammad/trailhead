import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/run_tracking/data/models/run_isar.dart';
import '../async_value.dart';

class HistoryActivitiesCubit extends Cubit<AsyncValue<List<RunIsar>>> {
  HistoryActivitiesCubit(this.watch) : super(const AsyncValue.loading()) {
    _subscription = watch().listen(
      (runs) => emit(AsyncValue.data(runs)),
      onError: (Object error, StackTrace trace) =>
          emit(AsyncValue.error(error, trace)),
    );
  }

  final Stream<List<RunIsar>> Function() watch;

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

  late final StreamSubscription<List<RunIsar>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
