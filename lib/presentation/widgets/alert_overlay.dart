/// Alert Overlay Widget
/// 
/// Full-screen overlay displayed during drowsiness alerts
/// with escalating warning levels.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/detection_result.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_state.dart';

/// Full-screen alert overlay
class AlertOverlay extends StatefulWidget {
  final DrowsinessResult result;
  final AlertType alertType;
  final VoidCallback onDismiss;
  final VoidCallback onEmergency;
  
  const AlertOverlay({
    super.key,
    required this.result,
    required this.alertType,
    required this.onDismiss,
    required this.onEmergency,
  });

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _autoDismissTimer;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Auto-dismiss after 30 seconds for non-critical alerts
    if (widget.alertType != AlertType.criticalEmergency) {
      _autoDismissTimer = Timer(const Duration(seconds: 30), () {
        widget.onDismiss();
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.alertType == AlertType.criticalEmergency;
    final backgroundColor = isCritical
        ? AppTheme.dangerColor.withOpacity(0.95)
        : AppTheme.warningColor.withOpacity(0.95);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          color: backgroundColor.withOpacity(
            0.7 + (_pulseAnimation.value - 0.8) * 0.5,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Alert icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(
                    isCritical ? Icons.error : Icons.warning_amber_rounded,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Alert title
                Text(
                  isCritical ? 'WAKE UP!' : 'STAY ALERT',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Alert message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _getAlertMessage(),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Fatigue score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Fatigue Level: ${(widget.result.fatigueScore * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Dismiss button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onDismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: isCritical
                                ? AppTheme.dangerColor
                                : AppTheme.warningColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I\'M AWAKE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Emergency button (only for critical)
                      if (isCritical)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onEmergency,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emergency),
                                SizedBox(width: 8),
                                Text(
                                  'CALL EMERGENCY CONTACT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _getAlertMessage() {
    switch (widget.alertType) {
      case AlertType.audioWarning:
        return 'Signs of drowsiness detected.\nStay focused on the road.';
      case AlertType.audioHaptic:
        return 'You appear to be getting drowsy.\nConsider taking a break soon.';
      case AlertType.criticalEmergency:
        return 'Critical drowsiness detected!\nPull over immediately and rest.';
    }
  }
}
