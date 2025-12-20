/// Drowsiness Repository Interface
/// 
/// Defines the contract for drowsiness detection data operations.

import '../entities/detection_result.dart';

/// Abstract repository for drowsiness detection
abstract class DrowsinessRepository {
  /// Initialize the repository and camera
  Future<void> initialize();
  
  /// Start real-time monitoring
  Future<void> startMonitoring();
  
  /// Stop monitoring
  Future<void> stopMonitoring();
  
  /// Stream of frame analysis results
  Stream<FrameAnalysisResult> get analysisStream;
  
  /// Dispose resources
  Future<void> dispose();
}
