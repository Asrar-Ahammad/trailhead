import re

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'r') as f:
    content = f.read()

# The old button code
old_button = r'''                    // Location Button
                    Align\(
                      alignment: Alignment\.centerRight,
                      child: Padding\(
                        padding: const EdgeInsets\.only\(right: 16, bottom: 12\),
                        child: FloatingActionButton\(
                          heroTag: 'manual_location',
                          mini: true,
                          backgroundColor: colors\.surfaceRaised,
                          onPressed: \(\) async \{
                            try \{
                              // Geolocator needs to be imported or we can just rely on the controller\.
                              // Wait, instead of Geolocator directly here, I can just read it\. 
                              // I'll add the import at the top of the file using a multi-replace\.
                              final pos = await Geolocator\.getCurrentPosition\(
                                desiredAccuracy: LocationAccuracy\.high,
                                timeLimit: const Duration\(seconds: 10\),
                              \);
                              ref\.read\(runTrackerProvider\.notifier\)\.updateInitialPosition\(pos\);
                            \} catch \(\_\) \{
                              if \(context\.mounted\) \{
                                ScaffoldMessenger\.of\(context\)\.showSnackBar\(
                                  const SnackBar\(content: Text\('Could not fetch location'\)\),
                                \);
                              \}
                            \}
                          \},
                          child: Icon\(PhosphorIcons\.navigationArrow\(PhosphorIconsStyle\.fill\), color: colors\.accent\),
                        \),
                      \),
                    \),'''

new_button = '''                    // Location Button
                    _LocationButton(colors: colors),'''

content = re.sub(old_button, new_button, content)

# Append _LocationButton class
location_button_class = '''
class _LocationButton extends ConsumerStatefulWidget {
  final AppColors colors;
  const _LocationButton({required this.colors});

  @override
  ConsumerState<_LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends ConsumerState<_LocationButton> {
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 12),
        child: FloatingActionButton(
          heroTag: 'manual_location',
          mini: true,
          backgroundColor: widget.colors.surfaceRaised,
          onPressed: _isFetching ? null : () async {
            setState(() {
              _isFetching = true;
            });
            try {
              final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              );
              ref.read(runTrackerProvider.notifier).updateInitialPosition(pos);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not fetch location')),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isFetching = false;
                });
              }
            }
          },
          child: _isFetching 
              ? SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.colors.accent),
                )
              : Icon(PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill), color: widget.colors.accent),
        ),
      ),
    );
  }
}
'''

content += location_button_class

with open('lib/features/run_tracking/presentation/active_run_screen.dart', 'w') as f:
    f.write(content)

