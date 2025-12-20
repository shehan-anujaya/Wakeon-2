/// Facial Features Entity
/// 
/// Represents extracted facial features from a single frame
/// including eye metrics and head pose estimation.

import '../../core/utils/math_utils.dart';

/// Facial features extracted from camera frame
class FacialFeatures {
  /// Left eye aspect ratio (EAR)
  final double leftEyeAspectRatio;
  
  /// Right eye aspect ratio (EAR)
  final double rightEyeAspectRatio;
  
  /// Average EAR of both eyes
  final double averageEAR;
  
  /// Head yaw angle (left-right rotation) in degrees
  final double yaw;
  
  /// Head pitch angle (up-down tilt) in degrees
  final double pitch;
  
  /// Head roll angle (sideways tilt) in degrees
  final double roll;
  
  /// Left eye landmark points (6 points for EAR calculation)
  final List<Point2D> leftEyeLandmarks;
  
  /// Right eye landmark points (6 points for EAR calculation)
  final List<Point2D> rightEyeLandmarks;
  
  const FacialFeatures({
    required this.leftEyeAspectRatio,
    required this.rightEyeAspectRatio,
    required this.averageEAR,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.leftEyeLandmarks,
    required this.rightEyeLandmarks,
  });
  
  /// Check if eyes are considered closed based on threshold
  bool areEyesClosed(double threshold) => averageEAR < threshold;
  
  /// Check if head is in normal position
  bool get isHeadPositionNormal =>
      yaw.abs() < 30.0 && pitch.abs() < 20.0 && roll.abs() < 25.0;
  
  /// Check if head appears to be nodding (drowsiness indicator)
  bool get isNodding => pitch > 15.0;
  
  /// Get normalized head pose values (0-1 range)
  (double, double, double) get normalizedHeadPose => (
    (yaw.abs() / 90.0).clamp(0.0, 1.0),
    (pitch.abs() / 90.0).clamp(0.0, 1.0),
    (roll.abs() / 90.0).clamp(0.0, 1.0),
  );
  
  /// Create empty instance when no face is detected
  factory FacialFeatures.empty() {
    return FacialFeatures(
      leftEyeAspectRatio: 0.0,
      rightEyeAspectRatio: 0.0,
      averageEAR: 0.0,
      yaw: 0.0,
      pitch: 0.0,
      roll: 0.0,
      leftEyeLandmarks: [],
      rightEyeLandmarks: [],
    );
  }
  
  @override
  String toString() => 
    'EAR: ${averageEAR.toStringAsFixed(3)}, '
    'Pose: (Y:${yaw.toStringAsFixed(1)}°, P:${pitch.toStringAsFixed(1)}°, R:${roll.toStringAsFixed(1)}°)';
}

/// Blink event detected from EAR time series
class BlinkEvent {
  /// Blink start timestamp
  final int startTime;
  
  /// Blink end timestamp
  final int endTime;
  
  /// Duration in milliseconds
  final int durationMs;
  
  /// Minimum EAR during blink (how closed were the eyes)
  final double minEar;
  
  /// Was this a complete blink (eyes reopened)
  final bool isComplete;
  
  const BlinkEvent({
    required this.startTime,
    required this.endTime,
    required this.durationMs,
    required this.minEar,
    required this.isComplete,
  });
  
  /// Check if this is a microsleep (prolonged eye closure)
  bool get isMicrosleep => durationMs > 500;
  
  /// Check if this is a normal blink (100-400ms)
  bool get isNormalBlink => durationMs >= 100 && durationMs <= 400;
  
  /// Check if this is a slow blink (fatigue indicator)
  bool get isSlowBlink => durationMs > 400 && durationMs <= 500;
}
