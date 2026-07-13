import re

with open('lib/features/profile/presentation/settings_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:trailhead_mobile/shared/providers/unit_provider.dart';" not in content:
    content = content.replace("import '../../sync/data/api_client.dart';", 
"""import '../../sync/data/api_client.dart';
import 'package:trailhead_mobile/shared/providers/unit_provider.dart';""")

old_section = r'''          _buildSectionHeader\('APP PREFERENCES', colors\),
          _buildSectionGroup\(\['''

new_section = '''          _buildSectionHeader('APP PREFERENCES', colors),
          _buildSectionGroup([
            ListTile(
              title: Text('Distance Unit', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
              subtitle: Text('Kilometers or Miles', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
              trailing: DropdownButton<bool>(
                value: ref.watch(distanceUnitProvider),
                dropdownColor: colors.surface,
                style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Kilometers')),
                  DropdownMenuItem(value: true, child: Text('Miles')),
                ],
                onChanged: (useMiles) {
                  if (useMiles != null) {
                    ref.read(distanceUnitProvider.notifier).setUseMiles(useMiles);
                    ref.read(soundServiceProvider).playToggleSwitch();
                  }
                },
              ),
            ),'''

content = re.sub(old_section, new_section, content)

# I should also fix the Audio Cue Frequency labels:
# Every 1 km -> Every 1 {unit}
# I will just replace 'km' with dynamic unit.
old_cues = r'''                        DropdownMenuItem\(value: 1\.0, child: Text\('Every 1 km'\)\),
                        DropdownMenuItem\(value: 0\.5, child: Text\('Every 0\.5 km'\)\),'''

new_cues = '''                        DropdownMenuItem(value: 1.0, child: Text('Every 1 ${ref.watch(distanceUnitProvider) ? 'mi' : 'km'}')),
                        DropdownMenuItem(value: 0.5, child: Text('Every 0.5 ${ref.watch(distanceUnitProvider) ? 'mi' : 'km'}')),'''

content = re.sub(old_cues, new_cues, content)

with open('lib/features/profile/presentation/settings_screen.dart', 'w') as f:
    f.write(content)
