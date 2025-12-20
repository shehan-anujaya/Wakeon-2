/// Detection Result Entity
/// 
/// Represents the result of frame analysis including
/// facial features and model inference output.

import '../../data/services/tflite_service.dart';
import 'facial_features.dart';

/// Result of analyzing a single camera frame
class FrameAnalysisResult {
  /// Frame capture timestamp
  final int timestamp;
  
  /// Whether a face was detected in the frame
  final bool faceDetected;
  
  /// Extracted facial features (null if no face detected)
  final FacialFeatures? facialFeatures;
  
  /// Model inference result (null if no face detected)
  final DrowsinessInferenceResult? inferenceResult;
  
  /// Processing time in milliseconds
  final int processingTimeMs;
  
  /// Error message if processing failed
  final String? error;
  
  const FrameAnalysisResult({
    required this.timestamp,
    required this.faceDetected,
    this.facialFeatures,
    this.inferenceResult,
    this.processingTimeMs = 0,
    this.error,
  });
  
  /// Create result when no face is detected
  factory FrameAnalysisResult.noFaceDetected({required int timestamp}) {
    return FrameAnalysisResult(
      timestamp: timestamp,
      faceDetected: false,
    );
  }
  
  /// Create result when an error occurred
  factory FrameAnalysisResult.error({
    required int timestamp,
    required String error,
  }) {
    return FrameAnalysisResult(
      timestamp: timestamp,
      faceDetected: false,
      error: error,
    );
  }
  
  /// Check if this result is valid for analysis
  bool get isValid => faceDetected && facialFeatures != null && error == null;
  
  @override
  String toString() => faceDetected
      ? 'Frame@$timestamp: ${facialFeatures?.toString()}'
      : 'Frame@$timestamp: No face detected';
}

/// Aggregated drowsiness detection result
class DrowsinessResult {
  /// Current alert level
  final DrowsinessLevel level;
  
  /// Overall fatigue score (0.0 - 1.0)
  final double fatigueScore;
  
  /// Confidence in the detection (0.0 - 1.0)
  final double confidence;
  
  /// Current EAR value
  final double currentEAR;
  
  /// PERCLOS value (percentage of time eyes are closed)
  final double perclos;
  
  /// Blinks per minute
  final double blinkRate;
  
  /// Head pose deviation score
  final double headPoseScore;
  
  /// Recommended action
  final RecommendedAction recommendedAction;
  
  /// Time in current state (milliseconds)
  final int timeInState;
  
  /// Timestamp of detection
  final int timestamp;
  
  const DrowsinessResult({
    required this.level,
    required this.fatigueScore,
    required this.confidence,
    required this.currentEAR,
    required this.perclos,
    required this.blinkRate,
    required this.headPoseScore,
    required this.recommendedAction,
    required this.timeInState,
    required this.timestamp,
  });
  
  /// Create initial/default result
  factory DrowsinessResult.initial() {
    return DrowsinessResult(
      level: DrowsinessLevel.alert,
      fatigueScore: 0.0,
      confidence: 0.0,
      currentEAR: 0.30,
      perclos: 0.0,
      blinkRate: 17.0,
      headPoseScore: 0.0,
      recommendedAction: RecommendedAction.none,
      timeInState: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Check if alert should be triggered
  bool get shouldAlert => 
    level != DrowsinessLevel.alert && confidence >= 0.7;
  
  @override
  String toString() => 
    'Drowsiness[$level]: Score=${fatigueScore.toStringAsFixed(2)}, '
    'Confidence=${(confidence * 100).toStringAsFixed(0)}%';
}

/// Drowsiness severity levels
enum DrowsinessLevel {
  /// Driver is alert and responsive
  alert,
  
  /// Early signs of fatigue detected
  mild,
  
  /// Moderate drowsiness, caution advised
  moderate,
  
  /// Severe drowsiness, immediate action needed
  severe,
  
  /// Critical state, potential microsleep
  critical,
}

/// Recommended actions for driver
enum RecommendedAction {
  /// No action needed, driver is alert
  none,
  
  /// Take a short break soon
  takeBreakSoon,
  
  /// Pull over for a break
  pullOverNow,
  
  /// Switch drivers if possible
  switchDriver,
  
  /// Immediate stop required
  emergencyStop,
}

extension DrowsinessLevelExtension on DrowsinessLevel {
  /// Get display text
  String get displayText {
    switch (this) {
      case DrowsinessLevel.alert:
        return 'Alert';
      case DrowsinessLevel.mild:
        return 'Mild Fatigue';
      case DrowsinessLevel.moderate:
        return 'Moderate Fatigue';
      case DrowsinessLevel.severe:
        return 'Severe Fatigue';
      case DrowsinessLevel.critical:
        return 'CRITICAL';
    }
  }
  
  /// Get color hex code
  int get colorValue {
    switch (this) {
      case DrowsinessLevel.alert:
        return 0xFF66BB6A;  // Green
      case DrowsinessLevel.mild:
        return 0xFFFFEB3B;  // Yellow
      case DrowsinessLevel.moderate:
        return 0xFFFFB74D;  // Orange
      case DrowsinessLevel.severe:
        return 0xFFFF7043;  // Deep Orange
      case DrowsinessLevel.critical:
        return 0xFFE53935;  // Red
    }
  }
}

extension RecommendedActionExtension on RecommendedAction {
  /// Get display text
  String get displayText {
    switch (this) {
      case RecommendedAction.none:
        return 'Stay focused';
      case RecommendedAction.takeBreakSoon:
        return 'Consider a break';
      case RecommendedAction.pullOverNow:
        return 'Pull over safely';
      case RecommendedAction.switchDriver:
        return 'Switch drivers';
      case RecommendedAction.emergencyStop:
        return 'STOP NOW';
    }
  }
}
