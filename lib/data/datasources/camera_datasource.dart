/// Camera Data Source
/// 
/// Handles camera initialization, frame capture, and preprocessing
/// for real-time drowsiness detection.

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/math_utils.dart';

/// Abstract interface for camera data source
abstract class CameraDataSource {
  /// Initialize camera
  Future<void> initialize();
  
  /// Start camera preview
  Future<void> startPreview();
  
  /// Stop camera preview
  Future<void> stopPreview();
  
  /// Get camera controller for preview widget
  CameraController? get controller;
  
  /// Stream of processed frames
  Stream<ProcessedFrame> get frameStream;
  
  /// Dispose resources
  Future<void> dispose();
  
  /// Check if camera is initialized
  bool get isInitialized;
  
  /// Switch camera (front/back)
  Future<void> switchCamera();
}

/// Implementation of camera data source
class CameraDataSourceImpl implements CameraDataSource {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  final StreamController<ProcessedFrame> _frameStreamController =
      StreamController<ProcessedFrame>.broadcast();
  
  @override
  CameraController? get controller => _controller;
  
  @override
  Stream<ProcessedFrame> get frameStream => _frameStreamController.stream;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> initialize() async {
    // Get available cameras
    _cameras = await availableCameras();
    
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('No cameras available', 'Device has no cameras');
    }
    
    // Find front camera (preferred for driver monitoring)
    _currentCameraIndex = _cameras!.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    
    // Fallback to first camera if no front camera
    if (_currentCameraIndex < 0) {
      _currentCameraIndex = 0;
    }
    
    await _initializeController();
  }
  
  Future<void> _initializeController() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    
    final camera = _cameras![_currentCameraIndex];
    
    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // 480p for optimal performance/quality
      enableAudio: false, // No audio needed
      imageFormatGroup: ImageFormatGroup.yuv420, // Efficient format
    );
    
    await _controller!.initialize();
    
    // Lock exposure for consistent lighting
    await _controller!.setExposureMode(ExposureMode.auto);
    
    // Lock focus for faster processing
    await _controller!.setFocusMode(FocusMode.auto);
    
    _isInitialized = true;
  }
  
  @override
  Future<void> startPreview() async {
    if (!_isInitialized || _controller == null) {
      throw StateError('Camera not initialized');
    }
    
    // Start image stream for processing
    await _controller!.startImageStream(_processFrame);
  }
  
  @override
  Future<void> stopPreview() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }
  
  /// Process incoming camera frame
  void _processFrame(CameraImage image) {
    // Skip if still processing previous frame
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Convert YUV420 to RGB
      final rgbBytes = _convertYUV420ToRGB(image);
      
      // Create processed frame
      final processedFrame = ProcessedFrame(
        data: rgbBytes,
        width: image.width,
        height: image.height,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        rotation: _getRotationCompensation(),
      );
      
      _frameStreamController.add(processedFrame);
    } catch (e) {
      // Log error but don't crash
      // In production, use proper logging
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Convert YUV420 camera format to RGB
  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final width = image.width;
    final height = image.height;
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;
    
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    
    final rgb = Uint8List(width * height * 3);
    
    int rgbIndex = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final yValue = yBytes[yIndex];
        final uValue = uBytes[uvIndex];
        final vValue = vBytes[uvIndex];
        
        // YUV to RGB conversion
        int r = (yValue + 1.370705 * (vValue - 128)).round();
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round();
        int b = (yValue + 1.732446 * (uValue - 128)).round();
        
        rgb[rgbIndex++] = r.clamp(0, 255);
        rgb[rgbIndex++] = g.clamp(0, 255);
        rgb[rgbIndex++] = b.clamp(0, 255);
      }
    }
    
    return rgb;
  }
  
  /// Get rotation compensation based on camera sensor orientation
  int _getRotationCompensation() {
    if (_controller == null) return 0;
    
    final camera = _cameras![_currentCameraIndex];
    return camera.sensorOrientation;
  }
  
  @override
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    // Stop current stream
    await stopPreview();
    
    // Dispose current controller
    await _controller?.dispose();
    
    // Switch to next camera
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    
    // Initialize new controller
    await _initializeController();
    
    // Restart stream
    await startPreview();
  }
  
  @override
  Future<void> dispose() async {
    await stopPreview();
    await _controller?.dispose();
    await _frameStreamController.close();
    _controller = null;
    _isInitialized = false;
  }
}

/// Processed camera frame ready for inference
class ProcessedFrame {
  /// RGB pixel data
  final Uint8List data;
  
  /// Frame width in pixels
  final int width;
  
  /// Frame height in pixels
  final int height;
  
  /// Capture timestamp in milliseconds
  final int timestamp;
  
  /// Rotation compensation in degrees
  final int rotation;
  
  const ProcessedFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.rotation,
  });
  
  /// Convert to Float32List for model input
  Float32List toFloat32List({
    double mean = 127.5,
    double std = 127.5,
  }) {
    return ImageUtils.normalizeForModel(data, width, height, mean: mean, std: std);
  }
  
  /// Get resized version for model input
  ProcessedFrame resize(int targetWidth, int targetHeight) {
    final resized = ImageUtils.resize(
      data,
      width,
      height,
      targetWidth,
      targetHeight,
      3,
    );
    
    return ProcessedFrame(
      data: resized,
      width: targetWidth,
      height: targetHeight,
      timestamp: timestamp,
      rotation: rotation,
    );
  }
}
