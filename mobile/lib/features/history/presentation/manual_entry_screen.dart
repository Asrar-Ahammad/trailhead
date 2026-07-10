import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/run_tracking/application/nl_logging_service.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  
  // Parsed values
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _effortController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(); // Just as an extra

  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _startListening() async {
    if (!_isListening) {
      ref.read(hapticsServiceProvider).lightImpact();
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _textController.text = val.recognizedWords;
          });
        });
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    if (_isListening) {
      ref.read(hapticsServiceProvider).lightImpact();
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _parseText() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isParsing = true);
    ref.read(soundServiceProvider).playButtonTap();
    final parsed = await ref.read(nlLoggingProvider).parseLog(_textController.text);
    setState(() => _isParsing = false);

    if (parsed != null) {
      ref.read(hapticsServiceProvider).mediumImpact();
      ref.read(soundServiceProvider).playSuccess();
      if (parsed.distanceKm != null) _distanceController.text = parsed.distanceKm.toString();
      if (parsed.subjectiveEffort != null) _effortController.text = parsed.subjectiveEffort!;
      if (parsed.conditions != null) _conditionsController.text = parsed.conditions!;
      if (parsed.timeOfDay != null) _timeController.text = parsed.timeOfDay!;
    } else {
      ref.read(soundServiceProvider).playError();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse text.')));
      }
    }
  }

  Future<void> _saveRun() async {
    final distance = double.tryParse(_distanceController.text);
    if (distance == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid distance required')));
       return;
    }
    
    final repo = ref.read(runHistoryRepositoryProvider);
    final now = DateTime.now();
    
    // Create run
    final run = RunIsar()
      ..clientRunId = DateTime.now().millisecondsSinceEpoch.toString()
      ..startTime = now.subtract(const Duration(hours: 1)) // rough guess
      ..endTime = now
      ..distanceM = distance * 1000
      ..durationS = 3600 // placeholder
      ..avgPaceSPerKm = 3600 / distance
      ..title = "Manual Run"
      ..synced = false
      ..status = "completed"
      ..subjectiveEffort = _effortController.text.isNotEmpty ? _effortController.text : null
      ..conditions = _conditionsController.text.isNotEmpty ? _conditionsController.text : null;
      
    await repo.saveRun(run, []);
    
    ref.read(soundServiceProvider).playRunFinish();
    ref.read(hapticsServiceProvider).heavyImpact();
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('LOG RUN', style: AppTextStyles.retroLabelLarge(color: colors.textPrimary).copyWith(fontSize: 20)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startListening,
                    style: ElevatedButton.styleFrom(backgroundColor: _isListening ? colors.error : colors.surfaceRaised),
                    child: Text(_isListening ? 'Listening...' : 'Voice Input', style: AppTextStyles.bodyMediumBold(color: colors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isParsing ? null : _parseText,
                    style: ElevatedButton.styleFrom(backgroundColor: colors.accent),
                    child: _isParsing 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.surface, strokeWidth: 2)) 
                      : Text('Parse', style: AppTextStyles.bodyMediumBold(color: colors.surface)),
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
              onPressed: _saveRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('SAVE MANUAL RUN', style: AppTextStyles.bodyLargeBold(color: colors.surface)),
            ),
          ],
        ),
      ),
    );
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
