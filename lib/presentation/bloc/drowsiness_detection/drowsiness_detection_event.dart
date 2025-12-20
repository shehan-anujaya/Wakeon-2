/// Drowsiness Detection Events
/// 
/// Events that can be dispatched to the drowsiness detection bloc.

import '../../../domain/entities/detection_result.dart';

/// Base event for drowsiness detection
sealed class DrowsinessDetectionEvent {
  const DrowsinessDetectionEvent();
}

/// Initialize the detection system
class InitializeDetection extends DrowsinessDetectionEvent {
  const InitializeDetection();
}

/// Start monitoring
class StartMonitoring extends DrowsinessDetectionEvent {
  const StartMonitoring();
}

/// Stop monitoring
class StopMonitoring extends DrowsinessDetectionEvent {
  const StopMonitoring();
}

/// Pause monitoring (temporary)
class PauseMonitoring extends DrowsinessDetectionEvent {
  const PauseMonitoring();
}

/// Resume from pause
class ResumeMonitoring extends DrowsinessDetectionEvent {
  const ResumeMonitoring();
}

/// New frame analysis result received
class FrameResultReceived extends DrowsinessDetectionEvent {
  final FrameAnalysisResult result;
  
  const FrameResultReceived(this.result);
}

/// Drowsiness result computed
class DrowsinessResultComputed extends DrowsinessDetectionEvent {
  final DrowsinessResult result;
  
  const DrowsinessResultComputed(this.result);
}

/// Toggle camera preview visibility
class TogglePreview extends DrowsinessDetectionEvent {
  final bool show;
  
  const TogglePreview(this.show);
}

/// Dismiss current alert
class DismissAlert extends DrowsinessDetectionEvent {
  const DismissAlert();
}

/// Trigger emergency contact
class TriggerEmergency extends DrowsinessDetectionEvent {
  const TriggerEmergency();
}

/// Reset the session
class ResetSession extends DrowsinessDetectionEvent {
  const ResetSession();
}

/// Camera permission result
class CameraPermissionResult extends DrowsinessDetectionEvent {
  final bool granted;
  
  const CameraPermissionResult(this.granted);
}

/// Request camera permission
class RequestCameraPermission extends DrowsinessDetectionEvent {
  const RequestCameraPermission();
}

/// Update performance metrics
class UpdateMetrics extends DrowsinessDetectionEvent {
  final double fps;
  final int inferenceTimeMs;
  
  const UpdateMetrics({
    required this.fps,
    required this.inferenceTimeMs,
  });
}
