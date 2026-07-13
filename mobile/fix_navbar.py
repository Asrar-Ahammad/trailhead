import re

with open('lib/features/navigation/presentation/main_scaffold.dart', 'r') as f:
    content = f.read()

# Replace the layout surrounding _AnimatedNavBar
old_layout = '''                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: retroColors.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: retroColors.border.withOpacity(0.4), 
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _AnimatedNavBar(
                            currentIndex: currentIndex,
                            colors: retroColors,
                            onTap: onTabTapped,
                          ),
                        ),
                      ),
                    ),'''

new_layout = '''                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: retroColors.surface.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: retroColors.border.withOpacity(0.4), 
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _AnimatedNavBar(
                          currentIndex: currentIndex,
                          colors: retroColors,
                          onTap: onTabTapped,
                        ),
                      ],
                    ),'''

content = content.replace(old_layout, new_layout)

# Restore _AnimatedNavBar height to 64
content = content.replace(
'''  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,''',
'''  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,'''
)

# Replace the NavBarItem height
content = content.replace(
'''      child: SizedBox(
        width: width,
        height: 88, // increased height to accommodate larger button''',
'''      child: SizedBox(
        width: width,
        height: 64,'''
)

# Change the Container to OverflowBox for the primary button
old_primary = '''              child: isPrimary
                ? Container(
                    key: const ValueKey('primary'),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(iconFill, color: Colors.white, size: 42),
                  )'''

new_primary = '''              child: isPrimary
                ? OverflowBox(
                    maxHeight: 84,
                    maxWidth: 84,
                    child: Container(
                      key: const ValueKey('primary'),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(iconFill, color: Colors.white, size: 42),
                    ),
                  )'''

content = content.replace(old_primary, new_primary)

with open('lib/features/navigation/presentation/main_scaffold.dart', 'w') as f:
    f.write(content)

