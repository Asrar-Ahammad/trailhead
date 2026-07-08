#!/bin/bash
# fix_isar_agp.sh
# Patches isar_flutter_libs 3.1.0+1 cached package to be compatible with AGP 8+.
# Run this after `flutter pub get` if the build fails with:
#   "Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported"
#
# Isar 3.x is abandoned and won't receive an official fix.

ISAR_DIR="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android"

if [ ! -d "$ISAR_DIR" ]; then
  echo "isar_flutter_libs-3.1.0+1 not found in pub cache. Skipping."
  exit 0
fi

echo "Patching isar_flutter_libs for AGP 8+ compatibility..."

# 1. Remove package attribute from AndroidManifest.xml
cat > "$ISAR_DIR/src/main/AndroidManifest.xml" << 'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools" />
EOF

# 2. Add namespace to build.gradle if not already present
if ! grep -q "namespace" "$ISAR_DIR/build.gradle"; then
  sed -i '' "s/android {/android {\n    namespace 'dev.isar.isar_flutter_libs'/" "$ISAR_DIR/build.gradle"
fi

echo "Done. isar_flutter_libs patched successfully."
