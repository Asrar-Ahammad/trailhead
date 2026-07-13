import re

with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    content = f.read()

# 1. Add imports
if "import 'package:isar/isar.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", 
"""import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/main.dart' show isarInstance;
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';""")


# 2. Add _getSystemContextMessage and modify _sendMessage
new_methods = """
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
      final distKm = ((run.distanceM ?? 0) / 1000).toStringAsFixed(2);
      final durMins = ((run.durationS ?? 0) / 60).floor();
      final date = run.startTime != null ? '${run.startTime!.year}-${run.startTime!.month.toString().padLeft(2, '0')}-${run.startTime!.day.toString().padLeft(2, '0')}' : 'Unknown date';
      buffer.writeln("- $date: $type, $distKm km in $durMins mins.");
    }

    _messages.insert(0, {
      'role': 'system',
      'content': buffer.toString(),
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(soundServiceProvider).playButtonTap();
    ref.read(hapticsServiceProvider).lightImpact();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    await _injectSystemContextIfNeeded();

    final response = await ref.read(chatServiceProvider).sendMessage(_messages);
"""

# Replace old _sendMessage
old_send_message = r'''  Future<void> _sendMessage\(\) async \{
    final text = _textController\.text\.trim\(\);
    if \(text\.isEmpty\) return;

    _textController\.clear\(\);
    ref\.read\(soundServiceProvider\)\.playButtonTap\(\);
    ref\.read\(hapticsServiceProvider\)\.lightImpact\(\);

    setState\(\(\) \{
      _messages\.add\(\{'role': 'user', 'content': text\}\);
      _isLoading = true;
    \}\);
    _scrollToBottom\(\);

    final response = await ref\.read\(chatServiceProvider\)\.sendMessage\(_messages\);'''

content = re.sub(old_send_message, new_methods, content)

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(content)
