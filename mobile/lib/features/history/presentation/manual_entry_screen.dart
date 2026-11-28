import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trailhead_mobile/features/history/state_management/manual_entry_bloc.dart';
import 'package:trailhead_mobile/features/history/domain/use_cases/save_manual_run.dart';

class ManualEntryScreen extends StatelessWidget {
  const ManualEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => context.read<CreateManualEntryBloc>()(),
    child: const _ManualEntryContent(),
  );
}

class _ManualEntryContent extends StatefulWidget {
  const _ManualEntryContent();
  @override
  State<_ManualEntryContent> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<_ManualEntryContent> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  
  // Parsed values
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _effortController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String _textBeforeCursor = '';
  String _textAfterCursor = '';
  
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }
  
  Future<bool> _initSpeechIfNeeded() async {
    if (_hasInitialized) return true;
    _hasInitialized = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'notListening' || status == 'done')) {
          setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    return _hasInitialized;
  }

  void _startListening() async {
    if (!_isListening) {
      context.read<HapticsCubit>().lightImpact();
      
      var micStatus = await Permission.microphone.status;
      if (micStatus.isPermanentlyDenied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable microphone in app settings')));
        await openAppSettings();
        return;
      }
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }

      var speechStatus = await Permission.speech.status;
      if (speechStatus.isPermanentlyDenied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable speech in app settings')));
        await openAppSettings();
        return;
      }
      if (!speechStatus.isGranted) {
        speechStatus = await Permission.speech.request();
      }
      
      if (micStatus.isGranted) {
        bool available = await _initSpeechIfNeeded();
        if (!mounted) return;
        if (available) {
          context.read<AudioCubit>().playMicStart();
          setState(() => _isListening = true);
          
          final int cursorPos = _textController.selection.baseOffset >= 0 
              ? _textController.selection.baseOffset 
              : _textController.text.length;
          _textBeforeCursor = _textController.text.substring(0, cursorPos);
          _textAfterCursor = _textController.text.substring(cursorPos);

          _speech.listen(onResult: (val) {
            if (mounted) {
              setState(() {
                final recognized = val.recognizedWords.trim();
                final prefix = (_textBeforeCursor.isNotEmpty && !_textBeforeCursor.endsWith(' ')) ? ' ' : '';
                final insertStr = recognized.isNotEmpty ? '$prefix$recognized ' : '';
                
                final newText = _textBeforeCursor + insertStr + _textAfterCursor;
                _textController.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: _textBeforeCursor.length + insertStr.length),
                );
                
                // Reliably reset the button when the system signals the session is completely done
                if (val.finalResult) {
                  _isListening = false;
                }
              });
            }
          });
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available on this device')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    if (_isListening) {
      context.read<HapticsCubit>().lightImpact();
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _parseText() {
    if (_textController.text.trim().isEmpty) return;

    context.read<AudioCubit>().playButtonTap();
    context.read<ManualEntryBloc>().add(ParseManualEntry(_textController.text));
  }

  void _saveRun() {
    context.read<ManualEntryBloc>().add(
      SaveManualEntry(
        distanceText: _distanceController.text,
        effort: _effortController.text,
        conditions: _conditionsController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final manualEntryState = context.watch<ManualEntryBloc>().state;
    final isParsing = manualEntryState.isParsing;
    final isBusy = isParsing || manualEntryState.isSaving;
    
    return BlocListener<ManualEntryBloc, ManualEntryState>(
      listener: _handleManualEntryState,
      child: Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('LOG RUN', style: AppTextStyles.headline(color: colors.textPrimary)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => AppNavigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Describe your run in natural language or use voice.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceRaised,
                hintText: 'e.g. "Ran 5k this morning, felt tired and it was humid"',
                hintStyle: TextStyle(color: colors.textDisabled),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? colors.error : colors.surfaceRaised,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text(_isListening ? 'Listening...' : 'Voice Input', style: AppTextStyles.bodyMediumBold(color: colors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      return ElevatedButton(
                        onPressed: (isBusy || !hasText) ? null : _parseText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: isParsing
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colors.surface, strokeWidth: 2))
                          : Text('Parse', style: AppTextStyles.bodyMediumBold(color: colors.surface)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('PARSED DETAILS', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
            const SizedBox(height: 16),
            _buildField('Distance (km)', _distanceController, colors, TextInputType.number),
            const SizedBox(height: 12),
            _buildField('Effort (easy/moderate/hard)', _effortController, colors, TextInputType.text),
            const SizedBox(height: 12),
            _buildField('Conditions', _conditionsController, colors, TextInputType.text),
            const SizedBox(height: 12),
            _buildField('Time of Day', _timeController, colors, TextInputType.text),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isBusy ? null : _saveRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: manualEntryState.isSaving
                  ? const CircularProgressIndicator()
                  : Text('SAVE MANUAL RUN', style: AppTextStyles.bodyLargeBold(color: colors.surface)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _handleManualEntryState(BuildContext context, ManualEntryState state) {
    if (state.parseCompleted) {
      final parsed = state.parsedLog;
      if (parsed == null) {
        context.read<AudioCubit>().playError();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to parse text.')),
        );
      } else {
        context.read<HapticsCubit>().mediumImpact();
        context.read<AudioCubit>().playSuccess();
        if (parsed.distanceKm != null) {
          _distanceController.text = parsed.distanceKm.toString();
        }
        if (parsed.subjectiveEffort != null) {
          _effortController.text = parsed.subjectiveEffort!;
        }
        if (parsed.conditions != null) {
          _conditionsController.text = parsed.conditions!;
        }
        if (parsed.timeOfDay != null) {
          _timeController.text = parsed.timeOfDay!;
        }
      }
    }

    switch (state.saveResult) {
      case ManualRunSaveResult.saved:
        context.read<AudioCubit>().playRunFinish();
        context.read<HapticsCubit>().heavyImpact();
        AppNavigator.pop(context);
        break;
      case ManualRunSaveResult.invalidDistance:
        context.read<AudioCubit>().playError();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valid distance required')),
        );
        break;
      case ManualRunSaveResult.failed:
        context.read<AudioCubit>().playError();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the run. Please try again.')),
        );
        break;
      case null:
        break;
    }
  }

  Widget _buildField(String label, TextEditingController controller, AppColors colors, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
      ),
    );
  }
}
