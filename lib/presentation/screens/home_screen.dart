/// Home Screen - Modern Redesign
/// 
/// Sleek, minimalist driver safety interface with
/// focus on clear status visibility and smooth animations.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/detection_result.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_bloc.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_event.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_state.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/camera_preview_widget.dart';

/// Modern home screen with glass morphism design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    context.read<DrowsinessDetectionBloc>().add(const InitializeDetection());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<DrowsinessDetectionBloc>();
    if (state == AppLifecycleState.paused) {
      bloc.add(const PauseMonitoring());
    } else if (state == AppLifecycleState.resumed) {
      bloc.add(const ResumeMonitoring());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: BlocConsumer<DrowsinessDetectionBloc, DrowsinessDetectionState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Stack(
            children: [
              // Animated background gradient
              _buildAnimatedBackground(state),
              
              // Main content
              SafeArea(
                child: _buildContent(context, state),
              ),
              
              // Alert overlay
              if (state is DrowsinessDetectionAlert)
                AlertOverlay(
                  result: state.result,
                  alertType: state.alertType,
                  onDismiss: () => context.read<DrowsinessDetectionBloc>()
                      .add(const DismissAlert()),
                  onEmergency: () => context.read<DrowsinessDetectionBloc>()
                      .add(const TriggerEmergency()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(DrowsinessDetectionState state) {
    Color glowColor = AppTheme.safeColor;
    
    if (state is DrowsinessDetectionActive) {
      final level = state.currentResult?.level ?? DrowsinessLevel.normal;
      glowColor = switch (level) {
        DrowsinessLevel.normal => const Color(0xFF00E676),
        DrowsinessLevel.warning => const Color(0xFFFFD600),
        DrowsinessLevel.critical => const Color(0xFFFF1744),
      };
    }
    
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5 + (_breatheController.value * 0.3),
              colors: [
                glowColor.withValues(alpha: 0.15),
                glowColor.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, DrowsinessDetectionState state) {
    if (state is DrowsinessDetectionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, DrowsinessDetectionState state) {
    return switch (state) {
      DrowsinessDetectionInitial() => _buildSplashState(),
      DrowsinessDetectionLoading() => _buildLoadingState(state),
      DrowsinessDetectionPermissionRequired() => _buildPermissionState(context),
      DrowsinessDetectionActive() => _buildMonitoringUI(context, state),
      DrowsinessDetectionPaused() => _buildPausedState(context, state),
      DrowsinessDetectionError() => _buildErrorState(context, state),
      DrowsinessDetectionAlert() => _buildMonitoringUI(
          context, DrowsinessDetectionActive(currentResult: state.result)),
    };
  }

  Widget _buildSplashState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.3 + _pulseController.value * 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'WAKEON',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w200,
              letterSpacing: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Driver Safety AI',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 4,
              color: Colors.white.withValues(alpha: 0.5),
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
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                // Outer ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                ),
                // Inner icon
                const Center(
                  child: Icon(
                    Icons.sensors,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            state.message.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 3,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              size: 48,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Camera Access',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enable camera to monitor your alertness\nand keep you safe on the road.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => context.read<DrowsinessDetectionBloc>()
                .add(const RequestCameraPermission()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Text(
                'Enable Camera',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringUI(BuildContext context, DrowsinessDetectionActive state) {
    final result = state.currentResult;
    final level = result?.level ?? DrowsinessLevel.normal;
    
    return Column(
      children: [
        // Top status bar
        _buildTopBar(context, state),
        
        // Main status display
        Expanded(
          child: Column(
            children: [
              const Spacer(),
              
              // Central status ring
              _buildStatusRing(level, result),
              
              const SizedBox(height: 32),
              
              // Status text
              _buildStatusText(level, result),
              
              const Spacer(),
              
              // Metrics cards
              _buildMetricsRow(result),
              
              const SizedBox(height: 24),
              
              // Control bar
              _buildControlBar(context, state),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, DrowsinessDetectionActive state) {
    final duration = Duration(seconds: state.sessionDurationSec);
    final timeStr = '${duration.inHours.toString().padLeft(2, '0')}:'
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Session time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // FPS indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.fps.round()} FPS',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Settings button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tune,
                size: 20,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRing(DrowsinessLevel level, DrowsinessResult? result) {
    final color = switch (level) {
      DrowsinessLevel.normal => const Color(0xFF00E676),
      DrowsinessLevel.warning => const Color(0xFFFFD600),
      DrowsinessLevel.critical => const Color(0xFFFF1744),
    };
    
    final fatigueScore = result?.fatigueScore ?? 0.0;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = level == DrowsinessLevel.critical 
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;
            
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                
                // Progress ring background
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                
                // Progress ring
                SizedBox(
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fatigueScore),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(color),
                      );
                    },
                  ),
                ),
                
                // Inner content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      switch (level) {
                        DrowsinessLevel.normal => Icons.check_circle_outline,
                        DrowsinessLevel.warning => Icons.warning_amber_outlined,
                        DrowsinessLevel.critical => Icons.error_outline,
                      },
                      size: 48,
                      color: color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(fatigueScore * 100).round()}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(DrowsinessLevel level, DrowsinessResult? result) {
    final statusText = switch (level) {
      DrowsinessLevel.normal => 'ALERT',
      DrowsinessLevel.warning => 'DROWSY',
      DrowsinessLevel.critical => 'DANGER',
    };
    
    final color = switch (level) {
      DrowsinessLevel.normal => const Color(0xFF00E676),
      DrowsinessLevel.warning => const Color(0xFFFFD600),
      DrowsinessLevel.critical => const Color(0xFFFF1744),
    };
    
    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          result?.recommendedAction.displayText ?? 'Monitoring active',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(DrowsinessResult? result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildMetricCard(
            'EAR',
            result?.currentEAR.toStringAsFixed(2) ?? '--',
            Icons.visibility_outlined,
          ),
          const SizedBox(width: 12),
          _buildMetricCard(
            'PERCLOS',
            result != null ? '${(result.perclos * 100).round()}%' : '--',
            Icons.timelapse_outlined,
          ),
          const SizedBox(width: 12),
          _buildMetricCard(
            'BLINKS',
            result?.blinkRate.toStringAsFixed(0) ?? '--',
            Icons.remove_red_eye_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white38),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, DrowsinessDetectionActive state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera toggle
          _buildControlButton(
            icon: state.showPreview ? Icons.videocam : Icons.videocam_off,
            label: 'Camera',
            onTap: () => context.read<DrowsinessDetectionBloc>()
                .add(const TogglePreview()),
          ),
          
          // Pause/Resume
          _buildControlButton(
            icon: Icons.pause_circle_outline,
            label: 'Pause',
            primary: true,
            onTap: () => context.read<DrowsinessDetectionBloc>()
                .add(const PauseMonitoring()),
          ),
          
          // Emergency
          _buildControlButton(
            icon: Icons.sos,
            label: 'SOS',
            color: const Color(0xFFFF1744),
            onTap: () => context.read<DrowsinessDetectionBloc>()
                .add(const TriggerEmergency()),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: primary ? 64 : 52,
            height: primary ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color?.withValues(alpha: 0.2) ?? Colors.white.withValues(alpha: primary ? 0.15 : 0.08),
              border: Border.all(
                color: color ?? (primary ? Colors.white24 : Colors.white10),
                width: primary ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: primary ? 28 : 24,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedState(BuildContext context, DrowsinessDetectionPaused state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Icon(
              Icons.pause_rounded,
              size: 60,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Monitoring is temporarily disabled',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => context.read<DrowsinessDetectionBloc>()
                .add(const ResumeMonitoring()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, DrowsinessDetectionError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Color(0xFFFF1744),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            if (state.canRetry) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.read<DrowsinessDetectionBloc>()
                    .add(const InitializeDetection()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
