import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:isar/isar.dart';
import '../data/models/shoe_isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../../main.dart'; // isarInstance
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../run_tracking/application/run_format_utils.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import '../application/image_processing_service.dart';
import '../application/shoe_service.dart';
import '../../you/presentation/widgets/activity_card.dart';

final shoeRunsProvider = StreamProvider.family<List<RunIsar>, String>((ref, shoeId) {
  final query = isarInstance.runIsars
      .filter()
      .clientShoeIdEqualTo(shoeId)
      .statusEqualTo('completed')
      .sortByStartTimeDesc()
      .build();
      
  return query.watch(fireImmediately: true);
});

class ShoeDashboardScreen extends ConsumerStatefulWidget {
  final ShoeIsar shoe;

  const ShoeDashboardScreen({super.key, required this.shoe});

  @override
  ConsumerState<ShoeDashboardScreen> createState() => _ShoeDashboardScreenState();
}

class _ShoeDashboardScreenState extends ConsumerState<ShoeDashboardScreen> {
  bool _isProcessingImage = false;
  String _loadingMessage = '';
  late ShoeIsar _currentShoe;

  @override
  void initState() {
    super.initState();
    _currentShoe = widget.shoe;
  }

  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    setState(() {
      _isProcessingImage = true;
      _loadingMessage = 'Removing background...';
    });

    try {
      final imageProcessingService = ref.read(imageProcessingServiceProvider);
      final processedFile = await imageProcessingService.removeBackground(File(pickedFile.path));
      
      if (processedFile == null) {
        throw Exception('Could not process image');
      }

      setState(() {
        _loadingMessage = 'Uploading...';
      });

      final shoeService = ref.read(shoeServiceProvider);
      await shoeService.uploadShoeImage(_currentShoe.clientShoeId!, processedFile.path);

      // Refresh shoe
      final updatedShoe = await isarInstance.shoeIsars
          .filter()
          .clientShoeIdEqualTo(_currentShoe.clientShoeId)
          .findFirst();

      if (updatedShoe != null) {
        setState(() {
          _currentShoe = updatedShoe;
        });
        
        // Refresh provider
        ref.invalidate(allShoesProvider);
        ref.invalidate(activeShoesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update shoe photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final runsAsync = ref.watch(shoeRunsProvider(_currentShoe.clientShoeId!));
    final useMiles = context.watch<DistanceUnitCubit>().state;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_currentShoe.name ?? 'Gear Stats', style: AppTextStyles.headline(color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple, color: colors.textPrimary),
            tooltip: 'Edit Shoe',
            onPressed: () => _showEditShoeDialog(colors),
          ),
        ],
      ),
      body: runsAsync.when(
        data: (runs) {
          int totalRuns = runs.length;
          double maxDistanceM = 0;
          double totalDurationS = 0;
          
          for (final run in runs) {
            if (run.distanceM != null && run.distanceM! > maxDistanceM) {
              maxDistanceM = run.distanceM!;
            }
            if (run.durationS != null) {
              totalDurationS += run.durationS!;
            }
          }
          
          final distanceKm = _currentShoe.distanceM / 1000.0;
          final distanceMi = distanceKm * 0.621371;
          final displayDistance = useMiles ? distanceMi : distanceKm;
          final distUnit = useMiles ? 'mi' : 'km';
          
          final maxDistKm = maxDistanceM / 1000.0;
          final displayMaxDist = useMiles ? (maxDistKm * 0.621371) : maxDistKm;
          
          final avgPaceSPerKm = (_currentShoe.distanceM > 0) ? (totalDurationS / (_currentShoe.distanceM / 1000.0)) : 0.0;
          final formattedAvgPace = avgPaceSPerKm > 0 
              ? RunFormatUtils.formatPace(_currentShoe.distanceM, totalDurationS.toInt(), useMiles)
              : '--:--';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: 'shoe_image_${_currentShoe.clientShoeId}',
                        child: _buildShoeImage(colors),
                      ),
                      if (!_isProcessingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndProcessImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.background, width: 2),
                              ),
                              child: Icon(PhosphorIcons.camera, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isProcessingImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(height: 8),
                          Text(_loadingMessage, style: AppTextStyles.label(color: colors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _currentShoe.name ?? 'Unknown Shoe',
                        style: AppTextStyles.displayMedium(color: colors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditShoeDialog(colors),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Icon(PhosphorIcons.pencilSimple, size: 16, color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (_currentShoe.brand != null && _currentShoe.brand!.isNotEmpty)
                  Center(
                    child: Text(
                      _currentShoe.brand!,
                      style: AppTextStyles.bodyLarge(color: colors.textSecondary),
                    ),
                  ),
                  
                const SizedBox(height: 32),
                
                // Stat Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(colors, 'TOTAL DISTANCE', '${displayDistance.toStringAsFixed(1)} $distUnit'),
                    _buildStatCard(colors, 'TOTAL RUNS', '$totalRuns'),
                    _buildStatCard(colors, 'AVERAGE PACE', '$formattedAvgPace / $distUnit'),
                    _buildStatCard(colors, 'LONGEST RUN', '${displayMaxDist.toStringAsFixed(1)} $distUnit'),
                  ],
                ),
                
                const SizedBox(height: 32),
                Text('RECENT ACTIVITY', style: AppTextStyles.labelCaps(color: colors.textSecondary)),
                const SizedBox(height: 16),
                
                if (runs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No runs tracked with this gear yet.', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                    ),
                  )
                else
                  ...runs.take(5).map((run) => ActivityCard(run: run)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading stats: $err', style: TextStyle(color: colors.error))),
      ),
    );
  }
  
  Widget _buildStatCard(AppColors colors, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.labelCaps(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headline(color: colors.textPrimary)),
        ],
      ),
    );
  }

  /// Builds the shoe image, handling both local file paths and network URLs.
  Widget _buildShoeImage(AppColors colors) {
    final imageUrl = _currentShoe.imageUrl;
    if (imageUrl == null) {
      return _buildDefaultShoeIcon(colors);
    }

    // Local file path (stored by shoe_service.uploadShoeImage)
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 150,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildDefaultShoeIcon(colors),
          ),
        );
      }
      return _buildDefaultShoeIcon(colors);
    }

    // Network URL
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 150,
      height: 150,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => _buildDefaultShoeIcon(colors),
    );
  }

  Widget _buildDefaultShoeIcon(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(PhosphorIcons.sneaker, color: colors.accent, size: 64),
    );
  }

  void _showEditShoeDialog(AppColors colors) {
    final nameController = TextEditingController(text: _currentShoe.name ?? '');
    final brandController = TextEditingController(text: _currentShoe.brand ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text('Edit Shoe', style: AppTextStyles.headline(color: colors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Shoe Name',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Brand / Company',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accent)),
                  ),
                ),
              ],
            ),
            actions: [
              if (!isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      setDialogState(() => isSaving = true);
                      final updated = await ref.read(shoeServiceProvider).updateShoe(
                        _currentShoe.id,
                        name: name,
                        brand: brandController.text.trim(),
                      );
                      if (updated != null && mounted) {
                        setState(() {
                          _currentShoe = updated;
                        });
                        ref.invalidate(allShoesProvider);
                        ref.invalidate(activeShoesProvider);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text('Save', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}
