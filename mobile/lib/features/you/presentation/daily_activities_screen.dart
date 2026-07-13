import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/you/presentation/widgets/activity_card.dart';

class DailyActivitiesScreen extends StatelessWidget {
  final DateTime date;
  final List<RunIsar> runs;

  const DailyActivitiesScreen({
    super.key,
    required this.date,
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; 
    final dateStr = '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';

    return Scaffold(
      backgroundColor: retroColors.background,
      appBar: AppBar(
        title: Text(dateStr, style: AppTextStyles.title(color: retroColors.textPrimary)),
        backgroundColor: retroColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: retroColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 16.0, bottom: 120.0),
        itemCount: runs.length,
        itemBuilder: (context, index) {
          final run = runs[index];
          return ActivityCard(run: run);
        },
      ),
    );
  }
}
