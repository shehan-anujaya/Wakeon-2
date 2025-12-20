/// Analyze Frame Use Case
/// 
/// Orchestrates real-time frame analysis for drowsiness detection.

import 'dart:async';

import '../entities/detection_result.dart';
import '../repositories/drowsiness_repository.dart';

/// Use case for analyzing camera frames
class AnalyzeFrameUseCase {
  final DrowsinessRepository repository;
  
  AnalyzeFrameUseCase({required this.repository});
  
  /// Initialize the analysis pipeline
  Future<void> initialize() async {
    await repository.initialize();
  }
  
  /// Start real-time frame analysis
  Future<void> start() async {
    await repository.startMonitoring();
  }
  
  /// Stop frame analysis
  Future<void> stop() async {
    await repository.stopMonitoring();
  }
  
  /// Get stream of analysis results
  Stream<FrameAnalysisResult> get analysisStream => repository.analysisStream;
  
  /// Dispose resources
  Future<void> dispose() async {
    await repository.dispose();
  }
}
