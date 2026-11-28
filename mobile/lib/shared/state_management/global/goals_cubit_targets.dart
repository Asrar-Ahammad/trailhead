import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/goals/domain/goals_repository_targets.dart';
import '../async_value.dart';

class GoalsCubit extends Cubit<AsyncValue<Goals>> {
  GoalsCubit(this.repository) : super(const AsyncValue.loading()) {
    reload();
  }

  final GoalsRepository repository;
  Future<void> _pending = Future.value();

  Future<void> reload() => _enqueue(() async {
    try {
      final goals = await repository.load();
      if (!isClosed) emit(AsyncValue.data(goals));
    } catch (error, stackTrace) {
      if (!isClosed && !state.hasValue)
        emit(AsyncValue.error(error, stackTrace));
    }
  });

  Future<void> saveGoals(Goals goals) => _enqueue(() async {
    await repository.save(goals);
    if (!isClosed) emit(AsyncValue.data(goals));
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
