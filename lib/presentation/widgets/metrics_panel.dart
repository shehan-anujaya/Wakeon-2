/// Metrics Panel Widget
/// 
/// Displays real-time detection metrics with
/// modern glass-morphism design.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard(
                  label: 'EAR',
                  value: ear.toStringAsFixed(2),
                  icon: Icons.visibility_rounded,
                  isWarning: ear < EarConstants.closedThreshold,
                ),
                _buildMetricCard(
                  label: 'PERCLOS',
                  value: '${(perclos * 100).round()}%',
                  icon: Icons.timelapse_rounded,
                  isWarning: perclos > FatigueConstants.perclosWarningThreshold,
                ),
                _buildMetricCard(
                  label: 'BLINKS',
                  value: blinkRate.toStringAsFixed(0),
                  icon: Icons.remove_red_eye_rounded,
                  isWarning: blinkRate < FatigueConstants.lowBlinkRateThreshold ||
                            blinkRate > FatigueConstants.highBlinkRateThreshold,
                  subtitle: '/min',
                ),
                _buildMetricCard(
                  label: 'HEAD',
                  value: '${((1 - headPoseScore) * 100).round()}%',
                  icon: Icons.face_rounded,
                  isWarning: headPoseScore > 0.3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    bool isWarning = false,
    String? subtitle,
  }) {
    final Color baseColor = isWarning 
        ? const Color(0xFFFFD600) 
        : Colors.white;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isWarning 
            ? const Color(0xFFFFD600).withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              icon,
              size: 18,
              color: baseColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: baseColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: baseColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: baseColor.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
