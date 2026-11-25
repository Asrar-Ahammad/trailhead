import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/state_management/async_value.dart';
import '../domain/ai_config.dart';
import '../domain/ai_repository_provider_reply.dart';

typedef CreateAiConnectionBloc = AiConnectionBloc Function();
typedef AiConnectionCheck = ({AiConfig config, AiTestResult result});

class AiConnectionRequested {
  const AiConnectionRequested(this.config);
  final AiConfig config;
}

class AiConnectionBloc
    extends Bloc<AiConnectionRequested, AsyncValue<AiConnectionCheck?>> {
  AiConnectionBloc(this._repository) : super(const AsyncValue.data(null)) {
    on<AiConnectionRequested>(_check);
  }

  final AiReplyRepository _repository;

  Future<void> _check(
    AiConnectionRequested event,
    Emitter<AsyncValue<AiConnectionCheck?>> emit,
  ) async {
    if (state.isLoading) return;
    emit(const AsyncValue.loading());
    try {
      final result = await _repository.checkConnection(event.config);
      emit(AsyncValue.data((config: event.config, result: result)));
    } catch (_) {
      emit(
        AsyncValue.data((
          config: event.config,
          result: const AiTestResult(
            success: false,
            message: 'Could not check the AI connection.',
          ),
        )),
      );
    }
  }
}
