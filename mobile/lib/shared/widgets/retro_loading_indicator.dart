import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class RetroLoadingIndicator extends StatefulWidget {
  final String text;
  
  const RetroLoadingIndicator({super.key, this.text = 'ANALYZING'});

  @override
  State<RetroLoadingIndicator> createState() => _RetroLoadingIndicatorState();
}

class _RetroLoadingIndicatorState extends State<RetroLoadingIndicator> {
  int _tick = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _tick++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    final showCursor = _tick % 2 == 0;
    final dotsCount = (_tick ~/ 2) % 4;
    final dots = List.filled(dotsCount, '.').join('');
    // Fill remaining space with invisible characters to prevent layout jumping
    final invisibleSpaces = List.filled(3 - dotsCount, '.').join('');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: retroColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: retroColors.border, width: 2),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: showCursor ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 12,
                height: 16,
                color: retroColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: AppTextStyles.retroLabelLarge(color: retroColors.accent),
                children: [
                  TextSpan(text: '${widget.text}$dots'),
                  TextSpan(
                    text: invisibleSpaces,
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RetroButtonLoadingIndicator extends StatefulWidget {
  final Color? color;
  
  const RetroButtonLoadingIndicator({super.key, this.color});

  @override
  State<RetroButtonLoadingIndicator> createState() => _RetroButtonLoadingIndicatorState();
}

class _RetroButtonLoadingIndicatorState extends State<RetroButtonLoadingIndicator> {
  int _tick = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (mounted) {
        setState(() {
          _tick++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final color = widget.color ?? retroColors.background;
    
    final show = _tick % 2 == 0;

    return Text(
      show ? '[█]' : '[ ]',
      style: AppTextStyles.bodyMediumBold(color: color),
    );
  }
}

