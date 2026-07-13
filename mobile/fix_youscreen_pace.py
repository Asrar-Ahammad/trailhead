import re

with open('lib/features/you/presentation/you_screen.dart', 'r') as f:
    content = f.read()

# Replace formatPace signature
old_sig = r'  String formatPace\(String category, double value\) \{'
new_sig = r'  String formatPace(String category, double value, bool useMiles) {'
content = re.sub(old_sig, new_sig, content)

# Replace the return string inside formatPace
old_ret = r"      return '\$paceMins:\$paceSecs /km';"
new_ret = r"      return RunFormatUtils.formatPace(distanceM, value.toInt(), useMiles) + ' /${RunFormatUtils.getUnitString(useMiles)}';"
content = re.sub(old_ret, new_ret, content)

with open('lib/features/you/presentation/you_screen.dart', 'w') as f:
    f.write(content)
