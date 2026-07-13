import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../application/shoe_service.dart';
import '../data/models/shoe_isar.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../haptics/application/haptics_service.dart';
import 'shoe_dashboard_screen.dart';

class ShoeManagementScreen extends ConsumerWidget {
  const ShoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final shoesAsync = ref.watch(allShoesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Shoes', style: AppTextStyles.headline(color: colors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(hapticsServiceProvider).lightImpact();
          _showAddShoeDialog(context, ref, colors);
        },
        backgroundColor: colors.accent,
        shape: const CircleBorder(),
        child: Icon(PhosphorIcons.plus(), color: Colors.white),
      ),
      body: shoesAsync.when(
        data: (shoes) {
          if (shoes.isEmpty) {
            return Center(
              child: Text(
                'No shoes added yet.\nTap + to add your gear.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            );
          }

          final activeShoes = shoes.where((s) => s.isActive).toList();
          final retiredShoes = shoes.where((s) => !s.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeShoes.isNotEmpty) ...[
                Text('ACTIVE GEAR', style: AppTextStyles.label(color: colors.accent)),
                const SizedBox(height: 8),
                ...activeShoes.map((s) => _buildShoeCard(context, ref, colors, s)),
                const SizedBox(height: 24),
              ],
              if (retiredShoes.isNotEmpty) ...[
                Text('RETIRED GEAR', style: AppTextStyles.label(color: colors.textSecondary)),
                const SizedBox(height: 8),
                ...retiredShoes.map((s) => _buildShoeCard(context, ref, colors, s)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: colors.error))),
      ),
    );
  }

  Widget _buildShoeCard(BuildContext context, WidgetRef ref, AppColors colors, ShoeIsar shoe) {
    final distanceKm = shoe.distanceM / 1000.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: ListTile(
        onTap: () {
          ref.read(hapticsServiceProvider).lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShoeDashboardScreen(shoe: shoe)),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(PhosphorIcons.sneaker(), color: colors.accent),
        ),
        title: Text(shoe.name ?? 'Unknown Shoe', style: AppTextStyles.title(color: colors.textPrimary)),
        subtitle: Text(
          '${shoe.brand ?? ''} • ${distanceKm.toStringAsFixed(1)} km',
          style: AppTextStyles.label(color: colors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shoe.isActive)
              IconButton(
                icon: Icon(PhosphorIcons.archive(), color: colors.textSecondary),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      bool isRetiring = false;
                      return StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          backgroundColor: colors.surface,
                          title: Text('Retire Gear?', style: AppTextStyles.headline(color: colors.textPrimary)),
                          content: Text(
                            'Are you sure you want to retire this gear? It will no longer be available for new runs.',
                            style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                          ),
                          actions: [
                            if (!isRetiring)
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                              ),
                            if (isRetiring)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.error,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  setState(() => isRetiring = true);
                                  await ref.read(shoeServiceProvider).retireShoe(shoe.id);
                                  ref.refresh(allShoesProvider);
                                  ref.refresh(activeShoesProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Retire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            IconButton(
              icon: Icon(PhosphorIcons.trash(), color: colors.error),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    bool isDeleting = false;
                    return StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        backgroundColor: colors.surface,
                        title: Text('Delete Gear?', style: AppTextStyles.headline(color: colors.textPrimary)),
                        content: Text(
                          'Are you sure you want to delete this gear permanently?',
                          style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                        ),
                        actions: [
                          if (!isDeleting)
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                            ),
                          if (isDeleting)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                setState(() => isDeleting = true);
                                await ref.read(shoeServiceProvider).deleteShoe(shoe.id);
                                ref.refresh(allShoesProvider);
                                ref.refresh(activeShoesProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShoeDialog(BuildContext context, WidgetRef ref, AppColors colors) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text('Add New Shoe', style: AppTextStyles.headline(color: colors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
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
                    labelText: 'Brand (Optional)',
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
                      setState(() => isSaving = true);
                      await ref.read(shoeServiceProvider).addShoe(name, brandController.text.trim());
                      ref.refresh(allShoesProvider);
                      ref.refresh(activeShoesProvider);
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
