/// Core Utilities for WakeOn Application
/// 
/// Contains helper functions for mathematical calculations,
/// data processing, and performance optimizations.

import 'dart:math' as math;
import 'dart:typed_data';

/// Mathematical utilities for facial landmark analysis
class MathUtils {
  MathUtils._();
  
  /// Calculate Euclidean distance between two 2D points
  static double euclideanDistance(
    double x1, double y1,
    double x2, double y2,
  ) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }
  
  /// Calculate Euclidean distance between two 3D points
  static double euclideanDistance3D(
    double x1, double y1, double z1,
    double x2, double y2, double z2,
  ) {
    return math.sqrt(
      math.pow(x2 - x1, 2) + 
      math.pow(y2 - y1, 2) + 
      math.pow(z2 - z1, 2)
    );
  }
  
  /// Calculate Eye Aspect Ratio (EAR)
  /// 
  /// EAR = (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)
  /// 
  /// [landmarks] should contain 6 points for one eye:
  /// p1: left corner, p2: upper-left, p3: upper-right
  /// p4: right corner, p5: lower-right, p6: lower-left
  static double calculateEAR(List<Point2D> landmarks) {
    if (landmarks.length != 6) {
      throw ArgumentError('EAR calculation requires exactly 6 landmarks');
    }
    
    // Vertical distances
    final v1 = euclideanDistance(
      landmarks[1].x, landmarks[1].y,
      landmarks[5].x, landmarks[5].y,
    );
    final v2 = euclideanDistance(
      landmarks[2].x, landmarks[2].y,
      landmarks[4].x, landmarks[4].y,
    );
    
    // Horizontal distance
    final h = euclideanDistance(
      landmarks[0].x, landmarks[0].y,
      landmarks[3].x, landmarks[3].y,
    );
    
    // EAR formula
    return (v1 + v2) / (2.0 * h);
  }
  
  /// Calculate average EAR for both eyes
  static double calculateAverageEAR(
    List<Point2D> leftEye,
    List<Point2D> rightEye,
  ) {
    final leftEAR = calculateEAR(leftEye);
    final rightEAR = calculateEAR(rightEye);
    return (leftEAR + rightEAR) / 2.0;
  }
  
  /// Calculate head pose angles from facial landmarks
  /// Returns (yaw, pitch, roll) in degrees
  static (double yaw, double pitch, double roll) calculateHeadPose(
    List<Point3D> landmarks,
    double imageWidth,
    double imageHeight,
  ) {
    // Using key facial points for pose estimation:
    // Nose tip, chin, left eye corner, right eye corner,
    // left mouth corner, right mouth corner
    
    if (landmarks.length < 6) {
      return (0.0, 0.0, 0.0);
    }
    
    final noseTip = landmarks[0];
    final chin = landmarks[1];
    final leftEye = landmarks[2];
    final rightEye = landmarks[3];
    
    // Calculate yaw (left-right rotation)
    final eyeCenter = Point3D(
      (leftEye.x + rightEye.x) / 2,
      (leftEye.y + rightEye.y) / 2,
      (leftEye.z + rightEye.z) / 2,
    );
    
    final yaw = math.atan2(
      noseTip.x - eyeCenter.x,
      noseTip.z - eyeCenter.z,
    ) * 180 / math.pi;
    
    // Calculate pitch (up-down rotation)
    final pitch = math.atan2(
      noseTip.y - eyeCenter.y,
      noseTip.z - eyeCenter.z,
    ) * 180 / math.pi;
    
    // Calculate roll (head tilt)
    final roll = math.atan2(
      rightEye.y - leftEye.y,
      rightEye.x - leftEye.x,
    ) * 180 / math.pi;
    
    return (yaw, pitch, roll);
  }
  
  /// Calculate moving average
  static double movingAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  /// Calculate exponential moving average
  static double exponentialMovingAverage(
    double currentValue,
    double previousEMA,
    double alpha,
  ) {
    return alpha * currentValue + (1 - alpha) * previousEMA;
  }
  
  /// Calculate standard deviation
  static double standardDeviation(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = movingAverage(values);
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }
  
  /// Normalize value to 0-1 range
  static double normalize(double value, double min, double max) {
    if (max == min) return 0.5;
    return (value - min) / (max - min);
  }
  
  /// Clamp value within range
  static double clamp(double value, double min, double max) {
    return math.max(min, math.min(max, value));
  }
  
  /// Sigmoid function for smooth transitions
  static double sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
  
  /// Linear interpolation
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// 2D Point representation
class Point2D {
  final double x;
  final double y;
  
  const Point2D(this.x, this.y);
  
  Point2D operator +(Point2D other) => Point2D(x + other.x, y + other.y);
  Point2D operator -(Point2D other) => Point2D(x - other.x, y - other.y);
  Point2D operator *(double scalar) => Point2D(x * scalar, y * scalar);
  
  double distanceTo(Point2D other) => MathUtils.euclideanDistance(x, y, other.x, other.y);
  
  @override
  String toString() => 'Point2D($x, $y)';
}

/// 3D Point representation
class Point3D {
  final double x;
  final double y;
  final double z;
  
  const Point3D(this.x, this.y, this.z);
  
  Point3D operator +(Point3D other) => Point3D(x + other.x, y + other.y, z + other.z);
  Point3D operator -(Point3D other) => Point3D(x - other.x, y - other.y, z - other.z);
  Point3D operator *(double scalar) => Point3D(x * scalar, y * scalar, z * scalar);
  
  double distanceTo(Point3D other) => MathUtils.euclideanDistance3D(x, y, z, other.x, other.y, other.z);
  
  Point2D toPoint2D() => Point2D(x, y);
  
  @override
  String toString() => 'Point3D($x, $y, $z)';
}

/// Image processing utilities
class ImageUtils {
  ImageUtils._();
  
  /// Convert camera image to grayscale for faster processing
  static Float32List convertToGrayscale(Uint8List rgbImage, int width, int height) {
    final grayscale = Float32List(width * height);
    
    for (int i = 0; i < width * height; i++) {
      final r = rgbImage[i * 3];
      final g = rgbImage[i * 3 + 1];
      final b = rgbImage[i * 3 + 2];
      
      // Standard grayscale conversion weights
      grayscale[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    }
    
    return grayscale;
  }
  
  /// Normalize image data for model input
  static Float32List normalizeForModel(
    Uint8List imageData,
    int width,
    int height, {
    double mean = 127.5,
    double std = 127.5,
  }) {
    final normalized = Float32List(width * height * 3);
    
    for (int i = 0; i < imageData.length; i++) {
      normalized[i] = (imageData[i] - mean) / std;
    }
    
    return normalized;
  }
  
  /// Resize image using bilinear interpolation
  static Uint8List resize(
    Uint8List input,
    int srcWidth,
    int srcHeight,
    int dstWidth,
    int dstHeight,
    int channels,
  ) {
    final output = Uint8List(dstWidth * dstHeight * channels);
    
    final xRatio = srcWidth / dstWidth;
    final yRatio = srcHeight / dstHeight;
    
    for (int y = 0; y < dstHeight; y++) {
      for (int x = 0; x < dstWidth; x++) {
        final srcX = (x * xRatio).floor();
        final srcY = (y * yRatio).floor();
        
        final srcIdx = (srcY * srcWidth + srcX) * channels;
        final dstIdx = (y * dstWidth + x) * channels;
        
        for (int c = 0; c < channels; c++) {
          output[dstIdx + c] = input[srcIdx + c];
        }
      }
    }
    
    return output;
  }
}

/// Time-based utilities
class TimeUtils {
  TimeUtils._();
  
  /// Get current timestamp in milliseconds
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;
  
  /// Calculate duration since timestamp
  static int durationSinceMs(int startMs) => nowMs() - startMs;
  
  /// Format duration for display
  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

/// Circular buffer for efficient sliding window operations
class CircularBuffer<T> {
  final List<T?> _buffer;
  final int capacity;
  int _head = 0;
  int _count = 0;
  
  CircularBuffer(this.capacity) : _buffer = List<T?>.filled(capacity, null);
  
  /// Add item to buffer
  void add(T item) {
    _buffer[_head] = item;
    _head = (_head + 1) % capacity;
    if (_count < capacity) _count++;
  }
  
  /// Get all items in order (oldest to newest)
  List<T> toList() {
    final result = <T>[];
    final start = _count < capacity ? 0 : _head;
    
    for (int i = 0; i < _count; i++) {
      final idx = (start + i) % capacity;
      if (_buffer[idx] != null) {
        result.add(_buffer[idx] as T);
      }
    }
    
    return result;
  }
  
  /// Get the most recent item
  T? get latest {
    if (_count == 0) return null;
    final idx = (_head - 1 + capacity) % capacity;
    return _buffer[idx];
  }
  
  /// Get item at index (0 = oldest)
  T? operator [](int index) {
    if (index < 0 || index >= _count) return null;
    final start = _count < capacity ? 0 : _head;
    final idx = (start + index) % capacity;
    return _buffer[idx];
  }
  
  int get length => _count;
  bool get isEmpty => _count == 0;
  bool get isFull => _count == capacity;
  
  void clear() {
    _buffer.fillRange(0, capacity, null);
    _head = 0;
    _count = 0;
  }
}
