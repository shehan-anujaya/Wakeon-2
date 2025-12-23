/// Fatigue Indicator Widget
/// 
/// Visual indicator showing current drowsiness level
/// with modern glass-morphism design.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/entities/detection_result.dart';

/// Displays fatigue level with visual feedback
class FatigueIndicator extends StatelessWidget {
  final DrowsinessResult? result;
  
  const FatigueIndicator({
    super.key,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    final level = result?.level ?? DrowsinessLevel.normal;
    final fatigueScore = result?.fatigueScore ?? 0.0;
    final action = result?.recommendedAction ?? RecommendedAction.none;
    final levelColor = _getLevelColor(level);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  levelColor.withValues(alpha: 0.25),
                  levelColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: levelColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Header with icon and status
                Row(
                  children: [
                    // Animated status icon with glow
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            levelColor.withValues(alpha: 0.4),
                            levelColor.withValues(alpha: 0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: levelColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getLevelIcon(level),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Status text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLevelText(level),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getActionText(action),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Confidence badge
                    if (result != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${(result!.confidence * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Modern progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fatigue Level',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${(fatigueScore * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                width: constraints.maxWidth * fatigueScore,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      levelColor,
                                      levelColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: levelColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getLevelColor(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => const Color(0xFF00E676),
      DrowsinessLevel.warning => const Color(0xFFFFD600),
      DrowsinessLevel.critical => const Color(0xFFFF1744),
    };
  }
  
  IconData _getLevelIcon(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => Icons.check_circle_rounded,
      DrowsinessLevel.warning => Icons.warning_rounded,
      DrowsinessLevel.critical => Icons.error_rounded,
    };
  }
  
  String _getLevelText(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => 'Alert & Focused',
      DrowsinessLevel.warning => 'Getting Drowsy',
      DrowsinessLevel.critical => 'Critical - Take Action!',
    };
  }
  
  String _getActionText(RecommendedAction action) {
    return switch (action) {
      RecommendedAction.none => 'Keep driving safely',
      RecommendedAction.stayAlert => 'Open windows or play music',
      RecommendedAction.takeBrakeNow => 'Consider taking a break soon',
      RecommendedAction.pullOverImmediately => 'Pull over immediately!',
    };
  }
}
