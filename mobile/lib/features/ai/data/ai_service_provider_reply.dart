import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'ai_request_model_provider_reply.dart';
import 'ai_response_model_provider_reply.dart';
import 'ai_service_provider_transport.dart';

class AiProviderReplyService {
  const AiProviderReplyService();

  Future<AiProviderReplyResponseModel?> complete(
    AiProviderRequestModel request,
  ) => compute(_complete, request);

  Future<AiConnectionResponseModel> checkConnection(
    AiProviderRequestModel request,
  ) => compute(_checkConnection, request);

  Stream<AiProviderReplyResponseModel> stream(AiProviderRequestModel request) {
    if (kIsWeb) return _withIdleTimeout(_stream(request));

    final port = ReceivePort();
    Isolate? worker;
    var cancelled = false;
    late final StreamController<AiProviderReplyResponseModel> controller;
    controller = StreamController(
      onListen: () async {
        port.listen((message) {
          if (controller.isClosed) return;
          if (message is AiProviderReplyResponseModel) {
            controller.add(message);
          } else {
            if (message != null) {
              controller.addError(StateError('The AI reply worker stopped.'));
            }
            unawaited(controller.close());
          }
        });
        try {
          worker = await Isolate.spawn(
            _runWorker,
            (request: request, output: port.sendPort),
            onExit: port.sendPort,
            onError: port.sendPort,
          );
          if (cancelled) worker?.kill(priority: Isolate.immediate);
        } catch (error, trace) {
          if (!cancelled) {
            controller.addError(error, trace);
            unawaited(controller.close());
          }
        }
      },
      onCancel: () {
        cancelled = true;
        port.close();
        worker?.kill(priority: Isolate.immediate);
      },
    );
    return _withIdleTimeout(controller.stream);
  }

  Stream<AiProviderReplyResponseModel> _withIdleTimeout(
    Stream<AiProviderReplyResponseModel> stream,
  ) => stream.timeout(
    const Duration(seconds: 45),
    onTimeout: (sink) {
      sink.addError(TimeoutException('The AI reply stopped responding.'));
      sink.close();
    },
  );
}

Future<AiProviderReplyResponseModel?> _complete(
  AiProviderRequestModel request,
) async {
  final transport = AiProviderTransport(request.config);
  try {
    final reply = await transport.chat(request.toMessages());
    return reply == null ? null : AiProviderReplyResponseModel(reply);
  } finally {
    transport.close();
  }
}

Future<AiConnectionResponseModel> _checkConnection(
  AiProviderRequestModel request,
) async {
  final transport = AiProviderTransport(request.config);
  try {
    return await transport.testConnection();
  } finally {
    transport.close();
  }
}

Stream<AiProviderReplyResponseModel> _stream(
  AiProviderRequestModel request,
) async* {
  final transport = AiProviderTransport(request.config);
  try {
    yield* transport
        .streamChat(request.toMessages())
        .map(AiProviderReplyResponseModel.new);
  } finally {
    transport.close();
  }
}

Future<void> _runWorker(
  ({AiProviderRequestModel request, SendPort output}) input,
) async {
  await for (final reply in _stream(input.request)) {
    input.output.send(reply);
  }
}
