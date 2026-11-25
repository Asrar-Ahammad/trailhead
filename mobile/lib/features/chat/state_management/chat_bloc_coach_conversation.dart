import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/chat_entity_coach_conversation.dart';
import '../domain/chat_use_case_coach_conversation.dart';

typedef CreateChatBloc = ChatBloc Function();

class ChatMessageSent {
  const ChatMessageSent(this.text, {required this.useMiles});

  final String text;
  final bool useMiles;
}

class ChatState {
  const ChatState({this.messages = const [], this.isReplying = false});

  final List<ChatMessage> messages;
  final bool isReplying;
}

class ChatBloc extends Bloc<ChatMessageSent, ChatState> {
  ChatBloc(this._conversation) : super(const ChatState()) {
    on<ChatMessageSent>(_send);
  }

  final ChatCoachConversation _conversation;
  ChatMessage? _systemContext;

  Future<void> _send(ChatMessageSent event, Emitter<ChatState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isReplying || !_conversation.isConfigured) return;

    final history = [...state.messages, (role: ChatRole.user, text: text)];
    final response = StringBuffer();
    void publish(String reply, {required bool isReplying}) {
      if (emit.isDone || isClosed) return;
      emit(
        ChatState(
          messages: List.unmodifiable([
            ...history,
            (role: ChatRole.assistant, text: reply),
          ]),
          isReplying: isReplying,
        ),
      );
    }

    publish('', isReplying: true);
    try {
      final system = _systemContext ??= await _conversation.buildContext(
        useMiles: event.useMiles,
      );
      if (emit.isDone || isClosed) return;
      await emit.onEach(
        _conversation.reply([system, ...history]),
        onData: (chunk) {
          response.write(chunk);
          publish(response.toString(), isReplying: true);
        },
      );
      publish(
        response.isEmpty
            ? 'Unable to get a response. Check your connection or API key in Settings.'
            : response.toString(),
        isReplying: false,
      );
    } catch (_) {
      publish(
        response.isEmpty
            ? 'Error connecting to the AI coach.'
            : response.toString(),
        isReplying: false,
      );
    }
  }
}
