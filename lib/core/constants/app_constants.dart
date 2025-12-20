/// Core Constants for WakeOn Application
/// 
/// Contains all magic numbers, thresholds, and configuration values
/// used throughout the application for drowsiness detection.

library;

/// Eye Aspect Ratio (EAR) thresholds
/// Based on research: "Real-Time Eye Blink Detection using Facial Landmarks"
/// 
/// EAR = (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)
/// where p1-p6 are the 6 eye landmark points
class EarConstants {
  EarConstants._();
  
  /// Normal EAR value when eyes are fully open (typical range: 0.25-0.35)
  static const double normalEar = 0.30;
  
  /// Threshold below which an eye is considered closed
  /// Values below this indicate potential drowsiness
  static const double closedThreshold = 0.21;
  
  /// Critical threshold for extended eye closure
  static const double criticalThreshold = 0.15;
  
  /// Minimum consecutive frames for valid blink detection
  /// Prevents false positives from camera noise
  static const int minBlinkFrames = 2;
  
  /// Maximum frames for normal blink (longer = drowsy)
  /// Normal blink: 100-400ms, at 30fps = 3-12 frames
  static const int maxNormalBlinkFrames = 12;
  
  /// Frames indicating microsleep (dangerous)
  /// >500ms closure indicates microsleep
  static const int microsleepFrames = 15;
}

/// Head Pose Estimation thresholds (in degrees)
class HeadPoseConstants {
  HeadPoseConstants._();
  
  /// Maximum safe yaw angle (left-right head turn)
  static const double maxSafeYaw = 30.0;
  
  /// Maximum safe pitch angle (up-down head tilt)
  static const double maxSafePitch = 20.0;
  
  /// Maximum safe roll angle (head tilt sideways)
  static const double maxSafeRoll = 25.0;
  
  /// Pitch angle indicating head nodding (drowsiness)
  static const double noddingPitchThreshold = 15.0;
  
  /// Duration in ms for head position to be considered "fixed"
  /// Used to detect head dropping from fatigue
  static const int positionFixedDurationMs = 500;
}

/// Fatigue Scoring Constants
class FatigueConstants {
  FatigueConstants._();
  
  /// Time window for PERCLOS calculation (percentage of eye closure)
  /// Standard: 1 minute window
  static const int perclosWindowMs = 60000;
  
  /// PERCLOS threshold for warning state (70% of time eyes >80% closed)
  static const double perclosWarningThreshold = 0.15;
  
  /// PERCLOS threshold for critical state
  static const double perclosCriticalThreshold = 0.25;
  
  /// Sliding window size for time-series analysis
  static const int slidingWindowSize = 30;
  
  /// Weight factors for composite fatigue score
  static const double earWeight = 0.35;
  static const double blinkRateWeight = 0.25;
  static const double headPoseWeight = 0.20;
  static const double perclosWeight = 0.20;
  
  /// Normal blink rate: 15-20 blinks per minute
  static const double normalBlinkRate = 17.0;
  static const double lowBlinkRateThreshold = 10.0;
  static const double highBlinkRateThreshold = 25.0;
  
  /// Fatigue score thresholds (0.0 - 1.0)
  static const double normalThreshold = 0.3;
  static const double warningThreshold = 0.6;
  static const double criticalThreshold = 0.8;
}

/// Alert System Constants
class AlertConstants {
  AlertConstants._();
  
  /// Minimum time between alerts (prevent alert fatigue)
  static const int alertCooldownMs = 5000;
  
  /// Confidence threshold for triggering alerts
  static const double alertConfidenceThreshold = 0.7;
  
  /// Number of consecutive high-risk frames before alert
  static const int consecutiveFramesForAlert = 5;
  
  /// Emergency escalation delay after critical alert (ms)
  static const int emergencyEscalationDelayMs = 10000;
  
  /// Haptic patterns (duration in ms)
  static const List<int> warningVibrationPattern = [0, 200, 100, 200];
  static const List<int> criticalVibrationPattern = [0, 500, 200, 500, 200, 500];
  
  /// Audio volumes
  static const double warningVolume = 0.5;
  static const double criticalVolume = 1.0;
}

/// Performance Constants for Edge AI
class PerformanceConstants {
  PerformanceConstants._();
  
  /// Target frames per second for processing
  static const int targetFps = 15;
  
  /// Maximum inference time before frame skip (ms)
  static const int maxInferenceTimeMs = 100;
  
  /// Camera resolution for optimal performance/accuracy tradeoff
  static const int cameraWidth = 640;
  static const int cameraHeight = 480;
  
  /// Number of frames to skip during high load
  static const int adaptiveFrameSkip = 2;
  
  /// Model input size (typical for mobile models)
  static const int modelInputSize = 224;
  
  /// Batch size for inference (1 for real-time)
  static const int batchSize = 1;
  
  /// Number of threads for TFLite inference
  static const int numThreads = 4;
}

/// Adaptive Threshold Constants
/// Used for per-driver calibration
class CalibrationConstants {
  CalibrationConstants._();
  
  /// Calibration duration in seconds
  static const int calibrationDurationSec = 30;
  
  /// Minimum samples needed for reliable calibration
  static const int minCalibrationSamples = 100;
  
  /// Standard deviation multiplier for adaptive thresholds
  static const double stdDevMultiplier = 2.0;
  
  /// Maximum allowed deviation from default thresholds
  static const double maxThresholdDeviation = 0.15;
}

/// False Alarm Reduction Constants
class FalseAlarmConstants {
  FalseAlarmConstants._();
  
  /// Accelerometer threshold for detecting road bumps (m/s²)
  static const double bumpThreshold = 3.0;
  
  /// Time window to ignore drowsiness after bump detection (ms)
  static const int bumpIgnoreWindowMs = 1000;
  
  /// Minimum face detection confidence
  static const double minFaceConfidence = 0.7;
  
  /// Maximum face angle for reliable detection
  static const double maxFaceAngle = 45.0;
  
  /// Consecutive frames required to confirm state change
  static const int stateConfirmationFrames = 3;
}
