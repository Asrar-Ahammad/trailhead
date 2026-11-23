import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../shared/state/app_cubits.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../data/models/shoe_isar.dart';
import 'shoe_service.dart';

class AllShoesCubit extends Cubit<AsyncState<List<ShoeIsar>>> {
  AllShoesCubit({required ShoeService service})
    : _service = service,
      super(const AsyncState.loading()) {
    load();
  }

  final ShoeService _service;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      emit(AsyncState.data(await _service.getAllShoes()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

class ActiveShoesCubit extends Cubit<AsyncState<List<ShoeIsar>>> {
  ActiveShoesCubit({required ShoeService service})
    : _service = service,
      super(const AsyncState.loading()) {
    load();
  }

  final ShoeService _service;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      emit(AsyncState.data(await _service.getActiveShoes()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

class ShoeRunsCubit extends Cubit<AsyncState<List<RunIsar>>> {
  ShoeRunsCubit({required Isar isar})
    : _isar = isar,
      super(const AsyncState.loading());

  final Isar _isar;
  String? _loadedShoeId;

  Future<void> load(String shoeId) async {
    if (_loadedShoeId == shoeId) return;
    _loadedShoeId = shoeId;
    emit(const AsyncState.loading());
    try {
      final runs = await _isar.runIsars
          .filter()
          .clientShoeIdEqualTo(shoeId)
          .statusEqualTo('completed')
          .sortByStartTimeDesc()
          .findAll();
      emit(AsyncState.data(runs));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}
