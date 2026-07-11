import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../profile/presentation/settings_screen.dart';
import '../application/run_tracker_controller.dart';
import '../../navigation/presentation/main_scaffold.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/retro_loading_indicator.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

class PermissionGateScreen extends ConsumerStatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  ConsumerState<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends ConsumerState<PermissionGateScreen> {
  bool _requestingForeground = false;
  bool _requestingBackground = false;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    // Check permission status on startup, if already granted, go to ActiveRunScreen directly after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndNavigate();
    });
  }

  void _checkPermissionsAndNavigate() {
    final state = ref.read(runTrackerProvider);
    if (state.permissionsGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackerState = ref.watch(runTrackerProvider);
    
    // Automatically redirect if permission gets granted
    ref.listen(runTrackerProvider, (prev, next) {
      if (next.permissionsGranted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    });

    if (!trackerState.permissionsChecked) {
      return const Scaffold(
        backgroundColor: Color(0xff121212),
        body: Center(child: RetroLoadingIndicator(text: 'INITIALIZING')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // App logo/name
              // App logo/name and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance for settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill),
                        color: const Color(0xffff5a3c),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRAILHEAD',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular), color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Informational card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xff1c1c1e),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff2e2e30)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.mapPin(PhosphorIconsStyle.bold),
                        color: const Color(0xffff5a3c),
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Location Access Required',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Trailhead is a native GPS tracker. To record your run route, duration, and distance accurately when the screen is locked or the app is backgrounded, background location access is mandatory.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          color: const Color(0xffa0a0a3),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMsg,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Permission actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PressableScale(
                    onTap: _requestingForeground ? null : _handleForegroundRequest,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xffff5a3c),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _requestingForeground
                          ? const RetroLoadingIndicator(text: 'REQUESTING')
                          : Text(
                              '1. Grant Location Permission',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PressableScale(
                    onTap: _requestingBackground ? null : _handleBackgroundRequest,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffff5a3c), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: _requestingBackground
                          ? const RetroLoadingIndicator(text: 'REQUESTING')
                          : Text(
                              '2. Allow all the time (Background)',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xffff5a3c),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: Please select "Allow all the time" in the system settings dialog for background tracking to work.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xff5c5c5e),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleForegroundRequest() async {
    setState(() {
      _requestingForeground = true;
      _errorMsg = "";
    });
    try {
      final granted = await ref.read(runTrackerProvider.notifier).requestForegroundPermission();
      if (!granted) {
        setState(() {
          _errorMsg = "Foreground location permission denied. Please enable location permissions.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Error requesting foreground permission: $e";
      });
    } finally {
      setState(() {
        _requestingForeground = false;
      });
    }
  }

  Future<void> _handleBackgroundRequest() async {
    setState(() {
      _requestingBackground = true;
      _errorMsg = "";
    });
    try {
      final granted = await ref.read(runTrackerProvider.notifier).requestBackgroundPermission();
      if (!granted) {
        setState(() {
          _errorMsg = "Background location permission denied. Change permission to 'Allow all the time' in settings.";
        });
      } else {
        // Ask for battery optimization exemption on Android
        try {
          bool? isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
          if (isBatteryOptimizationDisabled == false) {
            await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
          }
        } catch (e) {
          debugPrint('Battery optimization check failed: $e');
        }
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Error requesting background permission: $e";
      });
    } finally {
      setState(() {
        _requestingBackground = false;
      });
    }
  }
}
