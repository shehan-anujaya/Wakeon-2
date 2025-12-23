/// Alert Overlay Widget
/// 
/// Full-screen overlay displayed during drowsiness alerts
/// with modern glass morphism design.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/entities/detection_result.dart';
import '../bloc/drowsiness_detection/drowsiness_detection_state.dart';

/// Modern full-screen alert overlay
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _shakeAnimation;
  Timer? _autoDismissTimer;
  int _countdownSeconds = 30;
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.02, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.02, 0), end: const Offset(-0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(_shakeController);
    
    if (widget.alertType == AlertType.criticalEmergency) {
      _shakeController.repeat();
    }
    
    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdownSeconds--;
          if (_countdownSeconds <= 0) {
            timer.cancel();
            widget.onDismiss();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.alertType == AlertType.criticalEmergency;
    final alertColor = isCritical 
        ? const Color(0xFFFF1744) 
        : const Color(0xFFFFD600);
    
    return SlideTransition(
      position: _shakeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              alertColor.withValues(alpha: 0.4),
              alertColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Column(
              children: [
                // Countdown timer at top
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_countdownSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Main alert content
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Column(
                    children: [
                      // Alert icon with glow
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          isCritical ? Icons.warning_rounded : Icons.notifications_active,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Alert title
                      Text(
                        isCritical ? 'WAKE UP!' : 'STAY ALERT',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Fatigue indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, 
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fatigue: ${(widget.result.fatigueScore * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recommendation text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          widget.result.recommendedAction.displayText,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Primary dismiss button
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            "I'M AWAKE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: alertColor,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Emergency button
                      GestureDetector(
                        onTap: widget.onEmergency,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sos,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'CALL EMERGENCY CONTACT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
