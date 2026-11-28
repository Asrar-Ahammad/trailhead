import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/shoes/domain/shoes_repository_inventory.dart';
import '../async_value.dart';

class ShoesCubit extends Cubit<AsyncValue<List<ShoeGear>>> {
  ShoesCubit(ShoesRepository repository) : super(const AsyncValue.loading()) {
    _subscription = repository.watchAll().listen(
      (shoes) => emit(AsyncValue.data(shoes)),
      onError: (Object error, StackTrace trace) =>
          emit(AsyncValue.error(error, trace)),
    );
  }
  late final StreamSubscription<List<ShoeGear>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
