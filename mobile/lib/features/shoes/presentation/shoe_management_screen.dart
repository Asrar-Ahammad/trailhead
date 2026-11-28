import 'widgets/shoes_widget_inventory_card.dart';
import 'package:trailhead_mobile/shared/widgets/app_bar_backdrop.dart';
import '../../../shared/state_management/global/shoes_cubit_inventory.dart';
import 'shoes_dialog_edit_gear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';

class ShoeManagementScreen extends StatelessWidget {
  const ShoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final shoesAsync = context.watch<ShoesCubit>().state;

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: const AppBarBackdrop(),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => AppNavigator.pop(context),
        ),
        title: Text(
          'My Shoes',
          style: AppTextStyles.headline(color: colors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<HapticsCubit>().lightImpact();
          showShoeEditor(context);
        },
        backgroundColor: colors.accent,
        shape: const CircleBorder(),
        child: Icon(PhosphorIcons.plus, color: Colors.white),
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            children: [
              if (activeShoes.isNotEmpty) ...[
                Text(
                  'ACTIVE GEAR',
                  style: AppTextStyles.label(color: colors.accent),
                ),
                const SizedBox(height: 8),
                ...activeShoes.map((s) => ShoeInventoryCard(shoe: s, colors: colors)),
                const SizedBox(height: 24),
              ],
              if (retiredShoes.isNotEmpty) ...[
                Text(
                  'RETIRED GEAR',
                  style: AppTextStyles.label(color: colors.textSecondary),
                ),
                const SizedBox(height: 8),
                ...retiredShoes.map((s) => ShoeInventoryCard(shoe: s, colors: colors)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: TextStyle(color: colors.error)),
        ),
      ),
    );
  }

}
