import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ShoePhoto extends StatelessWidget {
  const ShoePhoto({
    super.key,
    required this.source,
    required this.size,
    required this.color,
    this.background,
    this.radius = 8,
    this.iconSize,
  });

  final String? source;
  final double size;
  final Color color;
  final Color? background;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final path = source?.trim();
    final placeholder = Center(
      child: Icon(
        PhosphorIcons.sneaker,
        size: iconSize ?? size * 0.55,
        color: color,
      ),
    );
    final uri = path == null ? null : Uri.tryParse(path);
    Widget content = placeholder;
    if (path != null && path.isNotEmpty) {
      if (uri?.scheme == 'http' || uri?.scheme == 'https') {
        content = CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.contain,
          placeholder: (_, _) => Center(
            child: SizedBox.square(
              dimension: math.min(size * 0.45, 22),
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
          ),
          errorWidget: (_, _, _) => placeholder,
        );
      } else {
        try {
          final file = uri?.scheme == 'file' ? File.fromUri(uri!) : File(path);
          content = Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => placeholder,
          );
        } on ArgumentError {
          content = placeholder;
        } on UnsupportedError {
          content = placeholder;
        }
      }
    }
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: background ?? Colors.transparent,
          child: content,
        ),
      ),
    );
  }
}
