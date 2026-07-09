import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../sync/application/sync_service.dart';
import '../../sync/data/api_client.dart';
import '../../../main.dart';

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
        // Fetch existing remote runs
        try {
          final apiClient = ref.read(apiClientProvider);
          final syncService = SyncService(isar: isarInstance, apiClient: apiClient);
          await syncService.fetchInitialData();
        } catch (e) {
          debugPrint('Failed to fetch initial data: $e');
        }
        setState(() => _isLoading = false);
        // Pop will return back to PermissionGate (or main app flow)
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TRAILHEAD',
                style: AppTextStyles.displayHero(color: colors.accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMedium(color: colors.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              TextField(
                controller: _emailCtrl,
                style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: AppTextStyles.bodyMedium(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.accent)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              
              TextField(
                controller: _passCtrl,
                style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: AppTextStyles.bodyMedium(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.accent)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.xl),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colors.background, strokeWidth: 2))
                    : Text(
                        _isRegister ? 'REGISTER' : 'LOGIN',
                        style: AppTextStyles.labelCaps(color: colors.background),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister ? 'Already have an account? Login' : 'Need an account? Register',
                  style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
