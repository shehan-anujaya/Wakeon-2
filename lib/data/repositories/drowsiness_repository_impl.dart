/// Drowsiness Repository Implementation
/// 
/// Implements the drowsiness detection domain interface using
/// camera and TFLite data sources.

import 'dart:async';

import '../../core/utils/math_utils.dart';
import '../../domain/entities/detection_result.dart';
import '../../domain/entities/facial_features.dart';
import '../../domain/repositories/drowsiness_repository.dart';
import '../datasources/camera_datasource.dart';
import '../services/tflite_service.dart';

/// Implementation of drowsiness repository
class DrowsinessRepositoryImpl implements DrowsinessRepository {
  final CameraDataSource cameraDataSource;
  final TFLiteService tfliteService;
  
  StreamSubscription<ProcessedFrame>? _frameSubscription;
  final StreamController<FrameAnalysisResult> _analysisController =
      StreamController<FrameAnalysisResult>.broadcast();
  
  DrowsinessRepositoryImpl({
    required this.cameraDataSource,
    required this.tfliteService,
  });
  
  @override
  Future<void> initialize() async {
    await cameraDataSource.initialize();
  }
  
  @override
  Future<void> startMonitoring() async {
    await cameraDataSource.startPreview();
    
    _frameSubscription = cameraDataSource.frameStream.listen(
      _processFrame,
      onError: (error) {
        _analysisController.addError(error);
      },
    );
  }
  
  @override
  Future<void> stopMonitoring() async {
    await _frameSubscription?.cancel();
    await cameraDataSource.stopPreview();
  }
  
  @override
  Stream<FrameAnalysisResult> get analysisStream => _analysisController.stream;
  
  /// Process a single camera frame
  Future<void> _processFrame(ProcessedFrame frame) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      
      // Preprocess frame for model
      final preprocessed = tfliteService.preprocessFrame(
        frame.data,
        frame.width,
        frame.height,
      );
      
      // Detect facial landmarks
      final landmarks = await tfliteService.detectFacialLandmarks(preprocessed);
      
      if (landmarks.isEmpty) {
        _analysisController.add(FrameAnalysisResult.noFaceDetected(
          timestamp: frame.timestamp,
        ));
        return;
      }
      
      // Extract eye landmarks
      final leftEye = tfliteService.extractLeftEyeLandmarks(landmarks);
      final rightEye = tfliteService.extractRightEyeLandmarks(landmarks);
      
      // Calculate EAR
      final leftEAR = MathUtils.calculateEAR(leftEye);
      final rightEAR = MathUtils.calculateEAR(rightEye);
      final avgEAR = (leftEAR + rightEAR) / 2.0;
      
      // Extract head pose landmarks
      final poseLandmarks = tfliteService.extractHeadPoseLandmarks(landmarks);
      
      // Calculate head pose
      final (yaw, pitch, roll) = MathUtils.calculateHeadPose(
        poseLandmarks,
        frame.width.toDouble(),
        frame.height.toDouble(),
      );
      
      // Build features for classification
      final features = _buildFeatureVector(
        ear: avgEAR,
        yaw: yaw,
        pitch: pitch,
        roll: roll,
      );
      
      // Run drowsiness classification
      final inferenceResult = await tfliteService.classifyDrowsiness(features);
      
      final endTime = DateTime.now().millisecondsSinceEpoch;
      
      // Build result
      final result = FrameAnalysisResult(
        timestamp: frame.timestamp,
        faceDetected: true,
        facialFeatures: FacialFeatures(
          leftEyeAspectRatio: leftEAR,
          rightEyeAspectRatio: rightEAR,
          averageEAR: avgEAR,
          yaw: yaw,
          pitch: pitch,
          roll: roll,
          leftEyeLandmarks: leftEye,
          rightEyeLandmarks: rightEye,
        ),
        inferenceResult: inferenceResult,
        processingTimeMs: endTime - startTime,
      );
      
      _analysisController.add(result);
    } catch (e) {
      // Non-fatal error, just skip frame
      _analysisController.add(FrameAnalysisResult.error(
        timestamp: frame.timestamp,
        error: e.toString(),
      ));
    }
  }
  
  /// Build feature vector for drowsiness classification
  List<double> _buildFeatureVector({
    required double ear,
    required double yaw,
    required double pitch,
    required double roll,
  }) {
    // Normalize features to consistent ranges
    return [
      ear,                          // 0-1 range (already normalized)
      yaw / 90.0,                   // Normalize to -1 to 1
      pitch / 90.0,                 // Normalize to -1 to 1
      roll / 90.0,                  // Normalize to -1 to 1
      ear < 0.21 ? 1.0 : 0.0,       // Binary: eyes closed indicator
      pitch > 15.0 ? 1.0 : 0.0,     // Binary: head nodding indicator
    ];
  }
  
  @override
  Future<void> dispose() async {
    await _frameSubscription?.cancel();
    await _analysisController.close();
    await cameraDataSource.dispose();
  }
}
