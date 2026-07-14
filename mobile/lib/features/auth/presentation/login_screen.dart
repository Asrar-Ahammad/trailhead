import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/retro_loading_indicator.dart';
import '../../sync/application/sync_service.dart';
import '../../sync/data/api_client.dart';
import '../../../main.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../shoes/application/shoe_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isRegister = false;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    bool success = false;
    if (_isRegister) {
      success = await auth.register(email, pass);
    } else {
      success = await auth.login(email, pass);
    }

    if (mounted) {
      if (success) {
        try {
          final apiClient = ref.read(apiClientProvider);
          final syncService = SyncService(isar: isarInstance, apiClient: apiClient);
          await syncService.fetchInitialData();
          // Invalidate shoe providers so they re-read from updated Isar
          ref.invalidate(allShoesProvider);
          ref.invalidate(activeShoesProvider);
        } catch (e) {
          debugPrint('Error starting sync: $e');
        }
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _isLoading = false);
        _error = 'Authentication failed. Please check your credentials.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // Sleek Hero Text
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TRAILHEAD',
                      style: AppTextStyles.displayHero(color: colors.accent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Subtle Retro Badge Accent
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'START YOUR JOURNEY',
                      style: AppTextStyles.retroLabelLarge(color: colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodyMediumBold(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Sleek Email Field
                _SleekTextField(
                  controller: _emailCtrl,
                  labelText: 'Email Address',
                  colors: colors,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Sleek Password Field
                _SleekTextField(
                  controller: _passCtrl,
                  labelText: 'Password',
                  colors: colors,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Sleek Pill Button
                PressableScale(
                  onTap: _isLoading ? () {} : _submit,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withOpacity(0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading 
                          ? RetroButtonLoadingIndicator(color: colors.background)
                          : Text(
                              _isRegister ? 'Register' : 'Login',
                              style: AppTextStyles.bodyLargeBold(color: colors.background),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Subtle Text Toggle
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegister = !_isRegister;
                        _error = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: Text(
                      _isRegister 
                          ? 'Already have an account? Login' 
                          : 'Need an account? Register',
                      style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleekTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final AppColors colors;

  const _SleekTextField({
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.bodyMedium(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
      ),
    );
  }
}
