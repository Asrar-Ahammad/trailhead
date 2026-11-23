#!/bin/bash
# Migrates phosphor_flutter API calls to phosphoricons_flutter API
# phosphor_flutter:  PhosphorIcons.iconName(PhosphorIconsStyle.fill)
# phosphoricons_flutter: PhosphorIcons.iconNameFill (no function call, suffix style)
# Also converts bare calls: PhosphorIcons.iconName() -> PhosphorIcons.iconName

set -e

FILES=$(grep -rl "phosphor_flutter\|PhosphorIcons\|PhosphorIconsStyle" lib/ --include="*.dart" | grep -v ".g.dart")

for FILE in $FILES; do
  echo "Processing $FILE..."

  # 1. Update import line
  sed -i '' "s|import 'package:phosphor_flutter/phosphor_flutter.dart';|import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';|g" "$FILE"

  # 2. Convert style-based calls: PhosphorIcons.iconName(PhosphorIconsStyle.fill) -> PhosphorIcons.iconNameFill
  # Each style suffix:
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(PhosphorIconsStyle\.fill\)/PhosphorIcons.\${1}Fill/g" "$FILE"
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(PhosphorIconsStyle\.bold\)/PhosphorIcons.\${1}Bold/g" "$FILE"
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(PhosphorIconsStyle\.regular\)/PhosphorIcons.\${1}/g" "$FILE"
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(PhosphorIconsStyle\.light\)/PhosphorIcons.\${1}Light/g" "$FILE"
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(PhosphorIconsStyle\.thin\)/PhosphorIcons.\${1}Thin/g" "$FILE"

  # 3. Convert bare no-arg calls: PhosphorIcons.iconName() -> PhosphorIcons.iconName
  perl -i -0pe "s/PhosphorIcons\.([a-zA-Z]+)\(\)/PhosphorIcons.\$1/g" "$FILE"

  echo "  Done."
done

echo "Migration complete."
