import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trailhead_mobile/features/audio/application/sound_service.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

enum ShareAspectRatio {
  square(1.0, '1:1'),
  story(9.0 / 16.0, '9:16');

  final double ratio;
  final String label;
  const ShareAspectRatio(this.ratio, this.label);
}

class ShareActivityScreen extends ConsumerStatefulWidget {
  final RunIsar run;
  final List<LatLng> points;

  const ShareActivityScreen({
    super.key,
    required this.run,
    required this.points,
  });

  @override
  ConsumerState<ShareActivityScreen> createState() => _ShareActivityScreenState();
}

class _ShareActivityScreenState extends ConsumerState<ShareActivityScreen> {
  final GlobalKey _previewKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  File? _backgroundPhoto;
  ShareAspectRatio _aspectRatio = ShareAspectRatio.square;
  Alignment _alignment = Alignment.bottomCenter;
  Color _routeColor = const Color(0xFFFF5722); // Trailhead Orange
  bool _isGlassCard = true;
  double _dimming = 0.25;
  double _overlayScale = 0.85;
  bool _showRoute = true;
  bool _isExporting = false;
  bool _isDragging = false;

  final List<Color> _palette = const [
    Color(0xFFFF5722), // Signature Orange
    Color(0xFF00E676), // Neon Lime
    Color(0xFF00E5FF), // Cyber Cyan
    Color(0xFFFFD600), // Electric Yellow
    Color(0xFFFFFFFF), // Crisp White
    Color(0xFFFF1744), // Coral Red
  ];

  final List<Alignment> _gridAlignments = const [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (picked != null) {
        setState(() {
          _backgroundPhoto = File(picked.path);
        });
        ref.read(hapticsServiceProvider).lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _backgroundPhoto = null;
    });
    ref.read(hapticsServiceProvider).lightImpact();
  }

  Future<void> _exportAndShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      ref.read(soundServiceProvider).playActivityTap();
      // Wait for any pending frame to draw
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas boundary not available');
      }

      // Render at high resolution (3x DPI for crisp 1080+ px)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/trailhead_activity_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        text: 'Finished my ${_formatActivityType()} with Trailhead!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatActivityType() {
    final type = widget.run.activityType ?? 'run';
    return type.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final useMiles = context.watch<DistanceUnitCubit>().state;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.8),
        elevation: 0,
        title: Text(
          'SHARE ACTIVITY',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.x, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isExporting ? null : _exportAndShare,
              icon: _isExporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.surface),
                    )
                  : Icon(PhosphorIcons.shareNetworkBold, size: 18, color: colors.surface),
              label: Text(
                'SHARE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: colors.surface,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas Preview Area ──────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: _aspectRatio.ratio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RepaintBoundary(
                      key: _previewKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Background Image or Gradient
                          if (_backgroundPhoto != null)
                            Image.file(
                              _backgroundPhoto!,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF181B20),
                                    Color(0xFF0F1115),
                                  ],
                                ),
                              ),
                            ),

                          // 2. Dimming & Contrast Layer
                          Container(
                            color: Colors.black.withValues(alpha: _backgroundPhoto != null ? _dimming : 0.1),
                          ),

                          // 3. Grid Guidelines (visible during dragging)
                          _buildGridGuidelines(),

                          // 4. Draggable Grid-Snapped Route & Stats Overlay
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxSafeW = constraints.maxWidth - 24.0;
                              final maxSafeH = constraints.maxHeight - 24.0;
                              final targetW = (maxSafeW * _overlayScale).clamp(160.0, maxSafeW);

                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: AnimatedAlign(
                                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  alignment: _alignment,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) {
                                      setState(() => _isDragging = true);
                                      ref.read(hapticsServiceProvider).lightImpact();
                                    },
                                    onPanUpdate: (details) {
                                      final dx = details.delta.dx / (maxSafeW / 2);
                                      final dy = details.delta.dy / (maxSafeH / 2);
                                      setState(() {
                                        _alignment = Alignment(
                                          (_alignment.x + dx).clamp(-1.0, 1.0),
                                          (_alignment.y + dy).clamp(-1.0, 1.0),
                                        );
                                      });
                                    },
                                    onPanEnd: (_) => _snapToNearestGrid(),
                                    onPanCancel: () => _snapToNearestGrid(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: targetW,
                                        maxHeight: maxSafeH,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: _alignment,
                                        child: _buildOverlayCard(colors, useMiles, targetW, _overlayScale),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Editor Toolbar ────────────────────────────────────
          _buildEditorToolbar(colors),
        ],
      ),
    );
  }

  /// Composite widget containing route polyline, stats and Trailhead logo
  Widget _buildOverlayCard(AppColors colors, bool useMiles, double cardWidth, double scale) {
    final distanceStr = RunFormatUtils.formatDistance(widget.run.distanceM ?? 0, useMiles);
    final unitStr = RunFormatUtils.getUnitString(useMiles);
    final durationStr = RunFormatUtils.formatDuration(widget.run.durationS ?? 0);
    final paceStr = RunFormatUtils.formatPace(widget.run.distanceM ?? 0, widget.run.durationS ?? 0, useMiles);
    final elevStr = '${(widget.run.elevationGainM ?? 0).toStringAsFixed(0)} m';

    final paddingVal = (12.0 * scale).clamp(8.0, 16.0);
    final routeH = (75.0 * scale).clamp(40.0, 95.0);

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(paddingVal),
      decoration: _isGlassCard
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Activity tag + Trailhead Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _routeColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _routeColor.withValues(alpha: 0.6), width: 1),
                    ),
                    child: Text(
                      _formatActivityType(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: (10.0 * scale).clamp(8.0, 11.0),
                        fontWeight: FontWeight.w800,
                        color: _routeColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'TRAILHEAD',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: (10.0 * scale).clamp(8.0, 11.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),

          // Route Vector Polyline (if enabled & points exist)
          if (_showRoute && widget.points.length >= 2) ...[
            SizedBox(height: 8.0 * scale),
            SizedBox(
              height: routeH,
              child: CustomPaint(
                size: Size.infinite,
                painter: _RoutePolylinePainter(
                  points: widget.points,
                  routeColor: _routeColor,
                ),
              ),
            ),
          ],

          SizedBox(height: 8.0 * scale),

          // Primary Stat: Distance
          Text(
            distanceStr,
            style: GoogleFonts.barlowCondensed(
              fontSize: (44.0 * scale).clamp(28.0, 48.0),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.95,
            ),
          ),
          Text(
            unitStr.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: (10.0 * scale).clamp(8.0, 11.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 8.0 * scale),

          // Secondary Stats: Time, Pace, Elevation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildMiniStat('TIME', durationStr, scale)),
              Flexible(child: _buildMiniStat('PACE', '$paceStr /${unitStr.toLowerCase()}', scale)),
              Flexible(child: _buildMiniStat('ELEVATION', elevStr, scale)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            fontSize: (18.0 * scale).clamp(13.0, 20.0),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: (8.5 * scale).clamp(7.0, 10.0),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Bottom Editor Controls
  Widget _buildEditorToolbar(AppColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Photo, Aspect Ratio, Card Style, Route Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Photo options
              Row(
                children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.camera, color: colors.textPrimary),
                    tooltip: 'Take Photo',
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.image, color: colors.textPrimary),
                    tooltip: 'Choose from Gallery',
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                  ),
                  if (_backgroundPhoto != null)
                    IconButton(
                      icon: Icon(PhosphorIcons.trash, color: colors.error),
                      tooltip: 'Remove Photo',
                      onPressed: _removePhoto,
                    ),
                ],
              ),

              // Aspect Ratio Toggle
              SegmentedButton<ShareAspectRatio>(
                segments: const [
                  ButtonSegment(value: ShareAspectRatio.square, label: Text('1:1')),
                  ButtonSegment(value: ShareAspectRatio.story, label: Text('9:16')),
                ],
                selected: {_aspectRatio},
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colors.surfaceRaised,
                  selectedBackgroundColor: colors.accent,
                  selectedForegroundColor: colors.surface,
                  foregroundColor: colors.textSecondary,
                ),
                onSelectionChanged: (set) {
                  setState(() => _aspectRatio = set.first);
                  ref.read(soundServiceProvider).playToggleSwitch();
                },
              ),

              // Glass card toggle
              IconButton(
                icon: Icon(
                  _isGlassCard ? PhosphorIcons.squareHalf : PhosphorIcons.square,
                  color: _isGlassCard ? colors.accent : colors.textSecondary,
                ),
                tooltip: _isGlassCard ? 'Card Overlay' : 'Minimal Overlay',
                onPressed: () {
                  setState(() => _isGlassCard = !_isGlassCard);
                  ref.read(soundServiceProvider).playToggleSwitch();
                },
              ),

              // Toggle route path
              IconButton(
                icon: Icon(
                  PhosphorIcons.path,
                  color: _showRoute ? colors.accent : colors.textSecondary,
                ),
                tooltip: 'Toggle Route Map',
                onPressed: () {
                  setState(() => _showRoute = !_showRoute);
                  ref.read(soundServiceProvider).playToggleSwitch();
                },
              ),
            ],
          ),

          // Size Control: Quick S, M, L presets + fine adjustment slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'SIZE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                _buildSizePill('S', 0.70, colors),
                const SizedBox(width: 6),
                _buildSizePill('M', 0.85, colors),
                const SizedBox(width: 6),
                _buildSizePill('L', 1.00, colors),
                const SizedBox(width: 10),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.surfaceRaised,
                      thumbColor: colors.accent,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _overlayScale,
                      min: 0.60,
                      max: 1.00,
                      onChanged: (val) {
                        setState(() => _overlayScale = val);
                      },
                    ),
                  ),
                ),
                Text(
                  '${(_overlayScale * 100).round()}%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Row 2: Snap-to-Grid 3x3 Selector + Route Colors
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3x3 Interactive Grid Snapper
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALIGNMENT (SNAP TO GRID)',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildGridSnapper(colors),
                ],
              ),

              const SizedBox(width: 24),

              // Route Accent Color Palette
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE ACCENT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _palette.map((color) {
                        final isSelected = _routeColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _routeColor = color);
                            ref.read(soundServiceProvider).playToggleSwitch();
                            ref.read(hapticsServiceProvider).lightImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? colors.textPrimary : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3x3 Grid Snapper Controller
  Widget _buildGridSnapper(AppColors colors) {
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: _gridAlignments.length,
        itemBuilder: (context, index) {
          final gridAlign = _gridAlignments[index];
          final isSelected = (_alignment.x - gridAlign.x).abs() < 0.35 &&
              (_alignment.y - gridAlign.y).abs() < 0.35;
          return GestureDetector(
            onTap: () {
              setState(() {
                _isDragging = false;
                _alignment = gridAlign;
              });
              ref.read(hapticsServiceProvider).lightImpact();
              ref.read(soundServiceProvider).playToggleSwitch();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Quick size pill button (S, M, L)
  Widget _buildSizePill(String label, double scale, AppColors colors) {
    final isSelected = (_overlayScale - scale).abs() < 0.05;
    return GestureDetector(
      onTap: () {
        setState(() => _overlayScale = scale);
        ref.read(soundServiceProvider).playToggleSwitch();
        ref.read(hapticsServiceProvider).lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? colors.surface : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Snaps current drag position to nearest 3x3 grid point
  void _snapToNearestGrid() {
    double snapX;
    if (_alignment.x < -0.33) {
      snapX = -1.0;
    } else if (_alignment.x > 0.33) {
      snapX = 1.0;
    } else {
      snapX = 0.0;
    }

    double snapY;
    if (_alignment.y < -0.33) {
      snapY = -1.0;
    } else if (_alignment.y > 0.33) {
      snapY = 1.0;
    } else {
      snapY = 0.0;
    }

    final target = Alignment(snapX, snapY);
    setState(() {
      _isDragging = false;
      _alignment = target;
    });
    ref.read(hapticsServiceProvider).mediumImpact();
    ref.read(soundServiceProvider).playToggleSwitch();
  }

  /// Guidelines that illuminate on the photo canvas while dragging
  Widget _buildGridGuidelines() {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isDragging ? 1.0 : 0.0,
        child: CustomPaint(
          size: Size.infinite,
          painter: _GridGuidelinesPainter(),
        ),
      ),
    );
  }
}

/// Painter for subtle 3x3 grid lines while dragging
class _GridGuidelinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double oneThirdW = size.width / 3.0;
    final double twoThirdsW = size.width * 2.0 / 3.0;
    final double oneThirdH = size.height / 3.0;
    final double twoThirdsH = size.height * 2.0 / 3.0;

    // Vertical guides
    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdsW, 0), Offset(twoThirdsW, size.height), paint);

    // Horizontal guides
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdsH), Offset(size.width, twoThirdsH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for crisp, scaled vector rendering of the route polyline
class _RoutePolylinePainter extends CustomPainter {
  final List<LatLng> points;
  final Color routeColor;

  _RoutePolylinePainter({
    required this.points,
    required this.routeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    if (latRange <= 0 && lngRange <= 0) return;

    const padding = 10.0;
    final drawableWidth = size.width - (padding * 2);
    final drawableHeight = size.height - (padding * 2);

    final scaleX = lngRange > 0 ? drawableWidth / lngRange : 1.0;
    final scaleY = latRange > 0 ? drawableHeight / latRange : 1.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - (lngRange * scale)) / 2;
    final offsetY = (size.height - (latRange * scale)) / 2;

    final path = ui.Path();
    bool first = true;
    for (var p in points) {
      final x = offsetX + (p.longitude - minLng) * scale;
      final y = offsetY + (maxLat - p.latitude) * scale;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Shadow / glow for visibility over any photo
    final glowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    final polylinePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, polylinePaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePolylinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.routeColor != routeColor;
  }
}
