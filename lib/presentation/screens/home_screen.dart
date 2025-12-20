/// Home Screen
/// 
/// Main screen for the driver safety assistant with
/// camera preview and drowsiness status display.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/detection_result.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_bloc.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_event.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_state.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/fatigue_indicator.dart';
import '../widgets/metrics_panel.dart';
import '../widgets/status_bar.dart';

/// Main monitoring screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize detection on screen load
    context.read<DrowsinessDetectionBloc>().add(const InitializeDetection());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<DrowsinessDetectionBloc>();
    
    switch (state) {
      case AppLifecycleState.paused:
        bloc.add(const PauseMonitoring());
        break;
      case AppLifecycleState.resumed:
        bloc.add(const ResumeMonitoring());
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<DrowsinessDetectionBloc, DrowsinessDetectionState>(
          listener: _handleStateChanges,
          builder: (context, state) {
            return Stack(
              children: [
                // Main content
                _buildMainContent(context, state),
                
                // Alert overlay
                if (state is DrowsinessDetectionAlert)
                  AlertOverlay(
                    result: state.result,
                    alertType: state.alertType,
                    onDismiss: () {
                      context.read<DrowsinessDetectionBloc>()
                          .add(const DismissAlert());
                    },
                    onEmergency: () {
                      context.read<DrowsinessDetectionBloc>()
                          .add(const TriggerEmergency());
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleStateChanges(
    BuildContext context,
    DrowsinessDetectionState state,
  ) {
    if (state is DrowsinessDetectionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          action: state.canRetry
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    context.read<DrowsinessDetectionBloc>()
                        .add(const InitializeDetection());
                  },
                )
              : null,
        ),
      );
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    DrowsinessDetectionState state,
  ) {
    return switch (state) {
      DrowsinessDetectionInitial() => _buildInitialState(),
      DrowsinessDetectionLoading() => _buildLoadingState(state),
      DrowsinessDetectionPermissionRequired() => _buildPermissionState(context),
      DrowsinessDetectionActive() => _buildActiveState(context, state),
      DrowsinessDetectionPaused() => _buildPausedState(context, state),
      DrowsinessDetectionError() => _buildErrorState(context, state),
      DrowsinessDetectionAlert() => _buildActiveState(
          context,
          DrowsinessDetectionActive(currentResult: state.result),
        ),
    };
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drive_eta,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 24),
          Text(
            'WakeOn',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI Driver Safety Assistant',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(DrowsinessDetectionLoading state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'WakeOn needs camera access to detect drowsiness and keep you safe while driving.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<DrowsinessDetectionBloc>()
                    .add(const RequestCameraPermission());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState(
    BuildContext context,
    DrowsinessDetectionActive state,
  ) {
    return Column(
      children: [
        // Status bar at top
        StatusBar(
          sessionDuration: state.sessionDurationSec,
          fps: state.fps,
          inferenceTime: state.inferenceTimeMs,
        ),
        
        // Camera preview
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: state.showPreview
                  ? const CameraPreviewWidget()
                  : _buildMinimalPreview(state),
            ),
          ),
        ),
        
        // Fatigue indicator
        FatigueIndicator(result: state.currentResult),
        
        // Metrics panel
        MetricsPanel(
          ear: state.currentResult?.currentEAR ?? 0.0,
          perclos: state.currentResult?.perclos ?? 0.0,
          blinkRate: state.currentResult?.blinkRate ?? 0.0,
          headPoseScore: state.currentResult?.headPoseScore ?? 0.0,
        ),
        
        // Control buttons
        _buildControlButtons(context, state),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMinimalPreview(DrowsinessDetectionActive state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(state.currentResult?.level),
              size: 80,
              color: _getStatusColor(state.currentResult?.level),
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusText(state.currentResult?.level),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(state.currentResult?.level),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(DrowsinessLevel? level) {
    return switch (level) {
      DrowsinessLevel.normal || null => Icons.check_circle,
      DrowsinessLevel.warning => Icons.warning_amber,
      DrowsinessLevel.critical => Icons.error,
    };
  }

  Color _getStatusColor(DrowsinessLevel? level) {
    return switch (level) {
      DrowsinessLevel.normal || null => AppTheme.safeColor,
      DrowsinessLevel.warning => AppTheme.warningColor,
      DrowsinessLevel.critical => AppTheme.dangerColor,
    };
  }

  String _getStatusText(DrowsinessLevel? level) {
    return switch (level) {
      DrowsinessLevel.normal || null => 'Alert',
      DrowsinessLevel.warning => 'Warning',
      DrowsinessLevel.critical => 'Critical',
    };
  }

  Widget _buildControlButtons(
    BuildContext context,
    DrowsinessDetectionActive state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle preview
          IconButton(
            onPressed: () {
              context.read<DrowsinessDetectionBloc>()
                  .add(TogglePreview(!state.showPreview));
            },
            icon: Icon(
              state.showPreview ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            tooltip: state.showPreview ? 'Hide Preview' : 'Show Preview',
          ),
          
          // Main start/stop button
          ElevatedButton(
            onPressed: () {
              final bloc = context.read<DrowsinessDetectionBloc>();
              if (state.frameResult != null) {
                bloc.add(const StopMonitoring());
              } else {
                bloc.add(const StartMonitoring());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: state.frameResult != null
                  ? AppTheme.dangerColor
                  : AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              state.frameResult != null ? 'Stop' : 'Start Monitoring',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Settings
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.white70,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPausedState(
    BuildContext context,
    DrowsinessDetectionPaused state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle_filled,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          const Text(
            'Monitoring Paused',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Session: ${_formatDuration(state.pausedAtSec)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<DrowsinessDetectionBloc>()
                  .add(const ResumeMonitoring());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text(
              'Resume',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    DrowsinessDetectionError state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.dangerColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (state.canRetry)
              ElevatedButton(
                onPressed: () {
                  context.read<DrowsinessDetectionBloc>()
                      .add(const InitializeDetection());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
