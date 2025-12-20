/// Status Bar Widget
/// 
/// Displays session info, FPS, and system status.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Top status bar showing session metrics
class StatusBar extends StatelessWidget {
  final int sessionDuration;
  final double fps;
  final int inferenceTime;
  
  const StatusBar({
    super.key,
    required this.sessionDuration,
    required this.fps,
    required this.inferenceTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // App title
          const Row(
            children: [
              Icon(
                Icons.drive_eta,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'WakeOn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Session duration
          _buildStatusChip(
            icon: Icons.access_time,
            value: _formatDuration(sessionDuration),
          ),
          
          const SizedBox(width: 12),
          
          // FPS
          _buildStatusChip(
            icon: Icons.speed,
            value: '${fps.round()} FPS',
            isWarning: fps < 20,
          ),
          
          const SizedBox(width: 12),
          
          // Inference time
          _buildStatusChip(
            icon: Icons.memory,
            value: '${inferenceTime}ms',
            isWarning: inferenceTime > 100,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip({
    required IconData icon,
    required String value,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isWarning ? AppTheme.warningColor : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isWarning ? AppTheme.warningColor : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
