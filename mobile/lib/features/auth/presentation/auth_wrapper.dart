import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_service.dart';
import 'login_screen.dart';
import '../../run_tracking/presentation/permission_gate_screen.dart';
import '../../../shared/widgets/retro_loading_indicator.dart';
import '../../sync/application/sync_service.dart';
import '../../sync/data/api_client.dart';
import '../../../main.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = ref.read(authServiceProvider);
    final token = await auth.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final apiClient = ref.read(apiClientProvider);
        final syncService = SyncService(isar: isarInstance, apiClient: apiClient);
        syncService.fetchInitialData().catchError((e) {
          debugPrint('Failed to fetch initial data on boot: $e');
        });
      } catch (e) {
        debugPrint('Error starting sync on boot: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: RetroLoadingIndicator(text: 'BOOTING SYSTEM')),
      );
    }

    if (_isAuthenticated) {
      return const PermissionGateScreen();
    } else {
      return const LoginScreen();
    }
  }
}
