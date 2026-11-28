import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/widgets/shoe_photo.dart';
import '../../domain/shoes_repository_inventory.dart';
import '../shoe_dashboard_screen.dart';
import '../shoes_dialog_edit_gear.dart';

enum _GearAction { edit, retire, delete }

class ShoeInventoryCard extends StatelessWidget {
  const ShoeInventoryCard({
    super.key,
    required this.shoe,
    required this.colors,
  });
  final ShoeGear shoe;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final distanceKm = shoe.distanceM / 1000.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          context.read<HapticsCubit>().lightImpact();
          AppNavigator.push(
            context,
            AppNavigator.materialPageRoute(
              builder: (_) => ShoeDashboardScreen(shoe: shoe),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'shoe_image_${shoe.clientShoeId ?? shoe.id}',
          child: ShoePhoto(
            source: shoe.imageUrl,
            size: 44,
            color: colors.accent,
            background: colors.surfaceRaised,
          ),
        ),
        title: Text(
          shoe.name ?? 'Unknown Shoe',
          style: AppTextStyles.title(color: colors.textPrimary),
        ),
        subtitle: Text(
          [
            if (shoe.brand?.isNotEmpty == true) shoe.brand!,
            '${distanceKm.toStringAsFixed(1)} km',
          ].join(' • '),
          style: AppTextStyles.label(color: colors.textSecondary),
        ),
        trailing: PopupMenuButton<_GearAction>(
          tooltip: 'Shoe actions',
          onSelected: (action) => showShoeEditor(
            context,
            shoe: shoe,
            retire: switch (action) {
              _GearAction.edit => null,
              _GearAction.retire => true,
              _GearAction.delete => false,
            },
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _GearAction.edit,
              child: Text('Edit Shoe'),
            ),
            if (shoe.isActive)
              const PopupMenuItem(
                value: _GearAction.retire,
                child: Text('Retire Shoe'),
              ),
            const PopupMenuItem(
              value: _GearAction.delete,
              child: Text('Delete Shoe'),
            ),
          ],
        ),
      ),
    );
  }
}
