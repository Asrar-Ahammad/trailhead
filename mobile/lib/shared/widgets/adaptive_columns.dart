import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Places cards in columns sized for their content and lets each row grow.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    super.key,
    required this.children,
    required this.maxColumns,
    this.minColumnWidth = 108,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minColumnWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final available = constraints.maxWidth;
      if (!available.isFinite) return Column(children: children);
      final scale = math.max(
        1.0,
        MediaQuery.textScalerOf(context).scale(14) / 14,
      );
      final spaces =
          ((available + spacing) / (minColumnWidth * scale + spacing)).floor();
      final columns = spaces
          .clamp(1, math.min(maxColumns, children.length))
          .toInt();
      final width = (available - spacing * (columns - 1)) / columns;
      return Column(
        children: [
          for (var offset = 0; offset < children.length; offset += columns) ...[
            if (offset > 0) SizedBox(height: spacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var index = offset;
                  index < math.min(offset + columns, children.length);
                  index++
                ) ...[
                  if (index > offset) SizedBox(width: spacing),
                  SizedBox(width: width, child: children[index]),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}
