import 'package:flutter_bloc/flutter_bloc.dart';

import '../async_value.dart';

sealed class AsyncResourceEvent<T> {
  const AsyncResourceEvent();
}

final class LoadResource<T> extends AsyncResourceEvent<T> {
  const LoadResource(this.load);

  final Future<T> Function() load;
}

final class WatchResource<T> extends AsyncResourceEvent<T> {
  const WatchResource(this.stream);

  final Stream<T> stream;
}

/// A page-scoped BLoC for loading a Future or subscribing to a Stream.
class AsyncResourceBloc<T>
    extends Bloc<AsyncResourceEvent<T>, AsyncValue<T>> {
  AsyncResourceBloc() : super(AsyncValue<T>.loading()) {
    on<LoadResource<T>>(_loadResource);
    on<WatchResource<T>>(_watchResource);
  }

  Future<void> _loadResource(
    LoadResource<T> event,
    Emitter<AsyncValue<T>> emit,
  ) async {
    emit(AsyncValue<T>.loading());
    try {
      emit(AsyncValue<T>.data(await event.load()));
    } catch (error, stackTrace) {
      emit(AsyncValue<T>.error(error, stackTrace));
    }
  }

  Future<void> _watchResource(
    WatchResource<T> event,
    Emitter<AsyncValue<T>> emit,
  ) async {
    emit(AsyncValue<T>.loading());
    await emit.forEach<T>(
      event.stream,
      onData: AsyncValue<T>.data,
      onError: AsyncValue<T>.error,
    );
  }
}
