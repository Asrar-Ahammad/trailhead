/// Loading, success, and failure state shared by local resource BLoCs.
sealed class AsyncValue<T> {
  const AsyncValue();

  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T value) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) =
      AsyncError<T>;

  T? get valueOrNull => switch (this) {
    AsyncData<T>(:final value) => value,
    _ => null,
  };

  bool get isLoading => this is AsyncLoading<T>;
  bool get hasValue => this is AsyncData<T>;
  bool get hasError => this is AsyncError<T>;

  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) => switch (this) {
    AsyncLoading<T>() => loading(),
    AsyncData<T>(:final value) => data(value),
    AsyncError<T>(error: final failure, :final stackTrace) =>
      error(failure, stackTrace),
  };

  R maybeWhen<R>({
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) => switch (this) {
    AsyncLoading<T>() => loading?.call() ?? orElse(),
    AsyncData<T>(:final value) => data?.call(value) ?? orElse(),
    AsyncError<T>(error: final failure, :final stackTrace) =>
      error?.call(failure, stackTrace) ?? orElse(),
  };
}

final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
