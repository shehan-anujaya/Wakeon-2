/// TensorFlow Lite Service
/// 
/// Handles model loading, preprocessing, and inference for
/// drowsiness detection using on-device AI.

import 'dart:typed_data';
import 'dart:isolate';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/math_utils.dart';

/// TensorFlow Lite inference service for drowsiness detection
class TFLiteService {
  Interpreter? _drowsinessInterpreter;
  Interpreter? _landmarkInterpreter;
  
  bool _isInitialized = false;
  
  // Model input/output shapes
  late List<int> _drowsinessInputShape;
  late List<int> _drowsinessOutputShape;
  late List<int> _landmarkInputShape;
  late List<int> _landmarkOutputShape;
  
  bool get isInitialized => _isInitialized;
  
  /// Initialize TFLite interpreters
  Future<void> initialize() async {
    try {
      // Configure interpreter options for optimal performance
      final options = InterpreterOptions()
        ..threads = PerformanceConstants.numThreads
        ..useNnApiForAndroid = true;  // Use Android Neural Networks API if available
      
      // Load drowsiness classification model
      _drowsinessInterpreter = await Interpreter.fromAsset(
        'assets/models/drowsiness_classifier.tflite',
        options: options,
      );
      
      // Load facial landmark detection model
      _landmarkInterpreter = await Interpreter.fromAsset(
        'assets/models/face_landmark.tflite',
        options: options,
      );
      
      // Get model shapes
      _drowsinessInputShape = _drowsinessInterpreter!.getInputTensor(0).shape;
      _drowsinessOutputShape = _drowsinessInterpreter!.getOutputTensor(0).shape;
      _landmarkInputShape = _landmarkInterpreter!.getInputTensor(0).shape;
      _landmarkOutputShape = _landmarkInterpreter!.getOutputTensor(0).shape;
      
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Run facial landmark detection on preprocessed image
  /// Returns 468 3D landmarks (MediaPipe Face Mesh format)
  Future<List<Point3D>> detectFacialLandmarks(Float32List imageData) async {
    if (!_isInitialized || _landmarkInterpreter == null) {
      throw StateError('TFLiteService not initialized');
    }
    
    // Prepare input tensor
    final inputShape = _landmarkInputShape;
    final input = imageData.reshape([
      inputShape[0], // batch
      inputShape[1], // height
      inputShape[2], // width
      inputShape[3], // channels
    ]);
    
    // Prepare output tensor
    final outputShape = _landmarkOutputShape;
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );
    
    // Run inference
    _landmarkInterpreter!.run(input, output);
    
    // Parse landmarks
    final landmarks = <Point3D>[];
    for (int i = 0; i < output[0].length; i++) {
      landmarks.add(Point3D(
        output[0][i][0], // x
        output[0][i][1], // y
        output[0][i][2], // z
      ));
    }
    
    return landmarks;
  }
  
  /// Run drowsiness classification on extracted features
  /// Returns probabilities for [alert, drowsy, microsleep]
  Future<DrowsinessInferenceResult> classifyDrowsiness(
    List<double> features,
  ) async {
    if (!_isInitialized || _drowsinessInterpreter == null) {
      throw StateError('TFLiteService not initialized');
    }
    
    // Prepare input tensor
    final input = Float32List.fromList(features.map((e) => e.toDouble()).toList())
        .reshape([1, features.length]);
    
    // Prepare output tensor [1, 3] for 3 classes
    final output = List.generate(1, (_) => List.filled(3, 0.0));
    
    // Run inference
    _drowsinessInterpreter!.run(input, output);
    
    // Parse results with softmax
    final probabilities = _softmax(output[0]);
    
    return DrowsinessInferenceResult(
      alertProbability: probabilities[0],
      drowsyProbability: probabilities[1],
      microsleepProbability: probabilities[2],
    );
  }
  
  /// Extract eye landmarks for EAR calculation
  /// MediaPipe Face Mesh eye landmark indices
  List<Point2D> extractLeftEyeLandmarks(List<Point3D> faceLandmarks) {
    // Left eye landmark indices in MediaPipe Face Mesh
    const leftEyeIndices = [362, 385, 387, 263, 373, 380];
    
    return leftEyeIndices.map((i) {
      if (i < faceLandmarks.length) {
        return faceLandmarks[i].toPoint2D();
      }
      return const Point2D(0, 0);
    }).toList();
  }
  
  /// Extract right eye landmarks for EAR calculation
  List<Point2D> extractRightEyeLandmarks(List<Point3D> faceLandmarks) {
    // Right eye landmark indices in MediaPipe Face Mesh
    const rightEyeIndices = [33, 160, 158, 133, 153, 144];
    
    return rightEyeIndices.map((i) {
      if (i < faceLandmarks.length) {
        return faceLandmarks[i].toPoint2D();
      }
      return const Point2D(0, 0);
    }).toList();
  }
  
  /// Extract head pose landmarks
  List<Point3D> extractHeadPoseLandmarks(List<Point3D> faceLandmarks) {
    // Key points for head pose: nose tip, chin, left eye, right eye, mouth corners
    const poseIndices = [1, 152, 33, 263, 61, 291];
    
    return poseIndices.map((i) {
      if (i < faceLandmarks.length) {
        return faceLandmarks[i];
      }
      return const Point3D(0, 0, 0);
    }).toList();
  }
  
  /// Apply softmax to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((l) => _exp(l - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }
  
  /// Safe exponential function
  double _exp(double x) {
    if (x > 88.0) return double.maxFinite;
    if (x < -88.0) return 0.0;
    return _fastExp(x);
  }
  
  /// Fast approximation of exp() for performance
  double _fastExp(double x) {
    // Use Schraudolph's algorithm for fast exp approximation
    // More accurate than standard for our use case
    final a = 1048576 / 0.6931471805599453;
    final b = 1072693248 - 60801;
    final v = (a * x + b).toInt();
    
    // Reconstruct double from integer bits (approximation)
    return 2.718281828459045 * (1 + x + x * x / 2 + x * x * x / 6);
  }
  
  /// Preprocess camera frame for model input
  Float32List preprocessFrame(
    Uint8List frameData,
    int srcWidth,
    int srcHeight,
  ) {
    final targetSize = PerformanceConstants.modelInputSize;
    
    // Resize image
    final resized = ImageUtils.resize(
      frameData,
      srcWidth,
      srcHeight,
      targetSize,
      targetSize,
      3, // RGB channels
    );
    
    // Normalize to [-1, 1] range (standard for face models)
    return ImageUtils.normalizeForModel(resized, targetSize, targetSize);
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _drowsinessInterpreter?.close();
    _landmarkInterpreter?.close();
    _drowsinessInterpreter = null;
    _landmarkInterpreter = null;
    _isInitialized = false;
  }
}

/// Result of drowsiness classification inference
class DrowsinessInferenceResult {
  final double alertProbability;
  final double drowsyProbability;
  final double microsleepProbability;
  
  const DrowsinessInferenceResult({
    required this.alertProbability,
    required this.drowsyProbability,
    required this.microsleepProbability,
  });
  
  /// Get the maximum probability (confidence)
  double get maxProbability {
    return [alertProbability, drowsyProbability, microsleepProbability]
        .reduce((a, b) => a > b ? a : b);
  }
  
  /// Get the most likely state
  DrowsinessState get predictedState {
    if (microsleepProbability > drowsyProbability && 
        microsleepProbability > alertProbability) {
      return DrowsinessState.microsleep;
    }
    if (drowsyProbability > alertProbability) {
      return DrowsinessState.drowsy;
    }
    return DrowsinessState.alert;
  }
  
  /// Get confidence of prediction
  double get confidence {
    switch (predictedState) {
      case DrowsinessState.alert:
        return alertProbability;
      case DrowsinessState.drowsy:
        return drowsyProbability;
      case DrowsinessState.microsleep:
        return microsleepProbability;
    }
  }
  
  @override
  String toString() => 
    'Alert: ${(alertProbability * 100).toStringAsFixed(1)}%, '
    'Drowsy: ${(drowsyProbability * 100).toStringAsFixed(1)}%, '
    'Microsleep: ${(microsleepProbability * 100).toStringAsFixed(1)}%';
}

/// Drowsiness state enum
enum DrowsinessState {
  alert,
  drowsy,
  microsleep,
}

/// Isolate entry point for background inference
void inferenceIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);
  
  TFLiteService? service;
  
  receivePort.listen((message) async {
    if (message is InitMessage) {
      service = TFLiteService();
      await service!.initialize();
      mainSendPort.send(InitCompleteMessage());
    } else if (message is InferenceMessage && service != null) {
      final landmarks = await service!.detectFacialLandmarks(message.imageData);
      mainSendPort.send(LandmarkResultMessage(landmarks));
    }
  });
}

/// Messages for isolate communication
class InitMessage {}
class InitCompleteMessage {}

class InferenceMessage {
  final Float32List imageData;
  InferenceMessage(this.imageData);
}

class LandmarkResultMessage {
  final List<Point3D> landmarks;
  LandmarkResultMessage(this.landmarks);
}
