/// Metrics Panel Widget
/// 
/// Displays real-time detection metrics including
/// EAR, PERCLOS, blink rate, and head pose.

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Panel showing detection metrics
class MetricsPanel extends StatelessWidget {
  final double ear;
  final double perclos;
  final double blinkRate;
  final double headPoseScore;
  
  const MetricsPanel({
    super.key,
    required this.ear,
    required this.perclos,
    required this.blinkRate,
    required this.headPoseScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            label: 'EAR',
            value: ear.toStringAsFixed(2),
            icon: Icons.visibility,
            isWarning: ear < EarConstants.closedThreshold,
          ),
          _buildDivider(),
          _buildMetric(
            label: 'PERCLOS',
            value: '${(perclos * 100).round()}%',
            icon: Icons.timer,
            isWarning: perclos > FatigueConstants.perclosWarningThreshold,
          ),
          _buildDivider(),
          _buildMetric(
            label: 'Blinks/min',
            value: blinkRate.toStringAsFixed(1),
            icon: Icons.remove_red_eye,
            isWarning: blinkRate < FatigueConstants.lowBlinkRateThreshold ||
                      blinkRate > FatigueConstants.highBlinkRateThreshold,
          ),
          _buildDivider(),
          _buildMetric(
            label: 'Head Pose',
            value: '${((1 - headPoseScore) * 100).round()}%',
            icon: Icons.face,
            isWarning: headPoseScore > 0.3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    bool isWarning = false,
  }) {
    final color = isWarning ? AppTheme.warningColor : Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
