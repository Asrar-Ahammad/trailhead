import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/navigation/app_navigator.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';
import '../../../shared/state_management/global/audio_cubit_ui_sounds.dart';
import '../../../shared/state_management/global/distance_unit_cubit.dart';
import '../../../shared/state_management/global/haptics_cubit_feedback.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/chat_entity_coach_conversation.dart';
import '../state_management/chat_bloc_coach_conversation.dart';
import 'chat_widget_typing_indicator.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final createBloc = context.read<CreateChatBloc>();
    return BlocProvider(create: (_) => createBloc(), child: const _ChatView());
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _scrollScheduled = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isReplying ||
        !context.read<AiConfigCubit>().state.isConfigured) {
      return;
    }
    _textController.clear();
    context.read<AudioCubit>().playButtonTap();
    context.read<HapticsCubit>().lightImpact();
    bloc.add(
      ChatMessageSent(text, useMiles: context.read<DistanceUnitCubit>().state),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        _scrollToBottom();
        if (!state.isReplying) {
          context.read<AudioCubit>().playChatBeep();
          context.read<HapticsCubit>().mediumImpact();
        }
      },
      builder: _buildChat,
    );
  }

  Widget _buildChat(BuildContext context, ChatState state) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final aiConfig = context.watch<AiConfigCubit>().state;
    final isAiConfigured = aiConfig.isConfigured;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'TRAILHEAD AI',
          style: AppTextStyles.retroLabelLarge(
            color: colors.textPrimary,
          ).copyWith(fontSize: 20),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => AppNavigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!isAiConfigured)
            Container(
              padding: const EdgeInsets.all(12),
              color: colors.error.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Icon(PhosphorIcons.warningCircle, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI features require an API key. Please configure your key in Settings.',
                      style: AppTextStyles.bodyMedium(color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                final isUser = message.role == ChatRole.user;
                final content = message.text;

                if (!isUser && content.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(color: colors.textPrimary),
                    ),
                  );
                }

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? colors.accent : colors.surfaceRaised,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isUser ? 14 : 2),
                        bottomRight: Radius.circular(isUser ? 2 : 14),
                      ),
                      border: Border.all(
                        color: isUser
                            ? colors.accent
                            : colors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTextStyles.bodyMedium(
                          color: isUser ? colors.surface : colors.textPrimary,
                        ),
                        strong: AppTextStyles.bodyMedium(
                          color: isUser ? colors.surface : colors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.bold),
                        listBullet: TextStyle(
                          color: isUser ? colors.surface : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(
              16,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            color: colors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: isAiConfigured,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: isAiConfigured
                          ? 'Ask about your stats...'
                          : 'AI is disabled...',
                      hintStyle: TextStyle(color: colors.textDisabled),
                      filled: true,
                      fillColor: colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => (isAiConfigured && !state.isReplying)
                        ? _sendMessage()
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (isAiConfigured && !state.isReplying)
                      ? _sendMessage
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isAiConfigured && !state.isReplying)
                          ? colors.accent
                          : colors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                      ), // visually center the paper plane
                      child: Icon(
                        PhosphorIcons.paperPlaneRightFill,
                        color: colors.surface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
