/// Drowsiness Detection State
/// 
/// Represents the different states of the drowsiness detection system.

import '../../../domain/entities/detection_result.dart';

/// Base state for drowsiness detection
sealed class DrowsinessDetectionState {
  const DrowsinessDetectionState();
}

/// Initial state before system starts
class DrowsinessDetectionInitial extends DrowsinessDetectionState {
  const DrowsinessDetectionInitial();
}

/// Loading state while initializing
class DrowsinessDetectionLoading extends DrowsinessDetectionState {
  final String message;
  final double progress;
  
  const DrowsinessDetectionLoading({
    this.message = 'Initializing...',
    this.progress = 0.0,
  });
}

/// State when camera permission is needed
class DrowsinessDetectionPermissionRequired extends DrowsinessDetectionState {
  final String permissionType;
  
  const DrowsinessDetectionPermissionRequired({
    this.permissionType = 'camera',
  });
}

/// Active monitoring state
class DrowsinessDetectionActive extends DrowsinessDetectionState {
  /// Current drowsiness detection result
  final DrowsinessResult? currentResult;
  
  /// Current frame analysis result
  final FrameAnalysisResult? frameResult;
  
  /// Current FPS
  final double fps;
  
  /// Is camera preview visible
  final bool showPreview;
  
  /// Inference time in milliseconds
  final int inferenceTimeMs;
  
  /// Session duration in seconds
  final int sessionDurationSec;
  
  /// Total blinks detected
  final int totalBlinks;
  
  /// Average EAR over session
  final double averageEAR;
  
  const DrowsinessDetectionActive({
    this.currentResult,
    this.frameResult,
    this.fps = 0.0,
    this.showPreview = true,
    this.inferenceTimeMs = 0,
    this.sessionDurationSec = 0,
    this.totalBlinks = 0,
    this.averageEAR = 0.0,
  });
  
  DrowsinessDetectionActive copyWith({
    DrowsinessResult? currentResult,
    FrameAnalysisResult? frameResult,
    double? fps,
    bool? showPreview,
    int? inferenceTimeMs,
    int? sessionDurationSec,
    int? totalBlinks,
    double? averageEAR,
  }) {
    return DrowsinessDetectionActive(
      currentResult: currentResult ?? this.currentResult,
      frameResult: frameResult ?? this.frameResult,
      fps: fps ?? this.fps,
      showPreview: showPreview ?? this.showPreview,
      inferenceTimeMs: inferenceTimeMs ?? this.inferenceTimeMs,
      sessionDurationSec: sessionDurationSec ?? this.sessionDurationSec,
      totalBlinks: totalBlinks ?? this.totalBlinks,
      averageEAR: averageEAR ?? this.averageEAR,
    );
  }
}

/// Paused state
class DrowsinessDetectionPaused extends DrowsinessDetectionState {
  final int pausedAtSec;
  final DrowsinessResult? lastResult;
  
  const DrowsinessDetectionPaused({
    required this.pausedAtSec,
    this.lastResult,
  });
}

/// Error state
class DrowsinessDetectionError extends DrowsinessDetectionState {
  final String message;
  final Object? error;
  final bool canRetry;
  
  const DrowsinessDetectionError({
    required this.message,
    this.error,
    this.canRetry = true,
  });
}

/// Alert state - triggered when drowsiness detected
class DrowsinessDetectionAlert extends DrowsinessDetectionState {
  final DrowsinessResult result;
  final AlertType alertType;
  final int alertStartTime;
  
  const DrowsinessDetectionAlert({
    required this.result,
    required this.alertType,
    required this.alertStartTime,
  });
}

/// Type of alert being triggered
enum AlertType {
  /// Audio warning only
  audioWarning,
  
  /// Audio + haptic feedback
  audioHaptic,
  
  /// Critical alert with emergency options
  criticalEmergency,
}
