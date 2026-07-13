import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

if "import 'dart:ui';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:ui';")

# 1. Update _StatPanel
stat_panel_old = r'''    return Container\(
      margin: const EdgeInsets\.symmetric\(horizontal: 16\),
      padding: const EdgeInsets\.symmetric\(vertical: 24, horizontal: 16\),
      decoration: BoxDecoration\(
        color: colors\.surfaceRaised, // Themed card color
        borderRadius: BorderRadius\.circular\(24\),
        boxShadow: \[
          BoxShadow\(
            color: Colors\.black\.withValues\(alpha: 0\.1\),
            blurRadius: 16,
            offset: const Offset\(0, 8\),
          \),
        \],
      \),
      child: Column\('''

stat_panel_new = '''    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceRaised.withValues(alpha: 0.75), // Glass effect
              border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column('''

content = re.sub(stat_panel_old, stat_panel_new, content)


# 2. Update _RunControls
run_controls_old = r'''        return Container\(
          margin: const EdgeInsets\.only\(left: 16, right: 16, bottom: 16\),
          decoration: BoxDecoration\(
            color: colors\.surfaceRaised, // Themed sheet color
            borderRadius: BorderRadius\.circular\(24\),
            boxShadow: \[
              BoxShadow\(
                color: Colors\.black\.withValues\(alpha: 0\.1\),
                blurRadius: 16,
                offset: const Offset\(0, 8\),
              \),
            \],
          \),
          padding: const EdgeInsets\.only\(top: 12, bottom: 24, left: 16, right: 16\),
          child: Column\('''

run_controls_new = '''        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Container(
                padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised.withValues(alpha: 0.75), // Glass effect
                  border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column('''

content = re.sub(run_controls_old, run_controls_new, content)


with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)

