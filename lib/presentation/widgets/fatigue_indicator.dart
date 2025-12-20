/// Fatigue Indicator Widget
/// 
/// Visual indicator showing current drowsiness level
/// with animated transitions.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getLevelColor(level).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Level indicator
          Row(
            children: [
              // Status icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLevelColor(level).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getLevelIcon(level),
                  color: _getLevelColor(level),
                  size: 32,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(level),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getActionText(action),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Confidence badge
              if (result != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(result!.confidence * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fatigue progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fatigue Level',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    '${(fatigueScore * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(level),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fatigueScore,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(_getLevelColor(level)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getLevelColor(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => AppTheme.safeColor,
      DrowsinessLevel.warning => AppTheme.warningColor,
      DrowsinessLevel.critical => AppTheme.dangerColor,
    };
  }
  
  IconData _getLevelIcon(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => Icons.check_circle,
      DrowsinessLevel.warning => Icons.warning_amber_rounded,
      DrowsinessLevel.critical => Icons.error,
    };
  }
  
  String _getLevelText(DrowsinessLevel level) {
    return switch (level) {
      DrowsinessLevel.normal => 'Alert & Focused',
      DrowsinessLevel.warning => 'Warning - Getting Drowsy',
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
