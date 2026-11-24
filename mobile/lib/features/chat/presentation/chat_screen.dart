import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/main.dart' show isarInstance;
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:get_it/get_it.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/chat/application/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../ai/application/ai_config_provider.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';



class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Format: { 'role': 'user' | 'assistant', 'content': '...', 'tool_calls'?: ... }
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  Future<void> _injectSystemContextIfNeeded() async {
    // Check if system message is already present
    if (_messages.isNotEmpty && _messages.first['role'] == 'system') {
      return;
    }

    final recentRuns = await isarInstance.runIsars.where().sortByStartTimeDesc().limit(10).findAll();
    
    if (recentRuns.isEmpty) {
      _messages.insert(0, {
        'role': 'system',
        'content': 'You are an expert AI health and fitness coach for the Trailhead app. The user has no logged runs yet. Provide general fitness advice and encourage them to start running or walking.',
      });
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("You are an expert AI health and fitness coach for the Trailhead app. Use the user's recent activity data to provide personalized, contextual advice. Keep responses concise and encouraging.");
    buffer.writeln("Here is the user's recent activity data:");
    
    for (final run in recentRuns) {
      final type = run.activityType ?? 'run';
      final durMins = ((run.durationS ?? 0) / 60).floor();
      final date = run.startTime != null ? '${run.startTime!.year}-${run.startTime!.month.toString().padLeft(2, '0')}-${run.startTime!.day.toString().padLeft(2, '0')}' : 'Unknown date';
      
      final useMiles = context.read<DistanceUnitCubit>().state;
      final distStr = RunFormatUtils.formatDistance(run.distanceM ?? 0, useMiles);
      final unitStr = RunFormatUtils.getUnitString(useMiles);
      buffer.writeln("- $date: $type, $distStr $unitStr in $durMins mins.");

    }

    _messages.insert(0, {
      'role': 'system',
      'content': buffer.toString(),
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    GetIt.instance<SoundService>().playButtonTap();
    GetIt.instance<HapticsService>().lightImpact();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    await _injectSystemContextIfNeeded();

    final assistantIndex = _messages.length;
    setState(() {
      _messages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    try {
      final stream = GetIt.instance<ChatService>().streamMessage(_messages.sublist(0, assistantIndex));
      String accumulated = '';

      await for (final chunk in stream) {
        accumulated += chunk;
        if (mounted) {
          setState(() {
            _messages[assistantIndex]['content'] = accumulated;
          });
          _scrollToBottom();
        }
      }

      if (accumulated.trim().isEmpty && mounted) {
        setState(() {
          _messages[assistantIndex]['content'] = 'Unable to get response from AI coach. Please check your network or API key in Settings.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if ((_messages[assistantIndex]['content'] as String).isEmpty) {
            _messages[assistantIndex]['content'] = 'Error connecting to AI service.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      GetIt.instance<SoundService>().playChatBeep();
      GetIt.instance<HapticsService>().mediumImpact();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final aiConfig = context.watch<AiConfigCubit>().state;
    final isAiConfigured = aiConfig.isConfigured;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('TRAILHEAD AI', style: AppTextStyles.retroLabelLarge(color: colors.textPrimary).copyWith(fontSize: 20)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['role'] == 'system') return const SizedBox.shrink();
                final isUser = msg['role'] == 'user';
                final content = msg['content'] as String? ?? '';

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
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                        color: isUser ? colors.accent : colors.border.withValues(alpha: 0.5),
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
                        listBullet: TextStyle(color: isUser ? colors.surface : colors.textPrimary),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            color: colors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: isAiConfigured,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: isAiConfigured ? 'Ask about your stats...' : 'AI is disabled...',
                      hintStyle: TextStyle(color: colors.textDisabled),
                      filled: true,
                      fillColor: colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => (isAiConfigured && !_isLoading) ? _sendMessage() : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (isAiConfigured && !_isLoading) ? _sendMessage : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isAiConfigured && !_isLoading) ? colors.accent : colors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0), // visually center the paper plane
                      child: Icon(PhosphorIcons.paperPlaneRightFill, color: colors.surface, size: 20),
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

class TypingIndicator extends StatefulWidget {
  final Color color;
  const TypingIndicator({super.key, required this.color});
  
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value - delay) % 1.0;
        final opacity = value < 0 ? 0.0 : (value > 0.5 ? 1.0 - (value - 0.5) * 2 : value * 2);
        
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppColors>()!.surfaceRaised,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          _buildDot(1),
          _buildDot(2),
        ],
      ),
    );
  }
}
