/// Performance Optimization Utilities
/// 
/// Contains tools for monitoring and optimizing real-time
/// processing performance on mobile devices.

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import '../constants/app_constants.dart';

/// Performance metrics for monitoring system health
class PerformanceMetrics {
  final double fps;
  final double inferenceTimeMs;
  final double cpuUsage;
  final double memoryUsageMb;
  final int frameDrops;
  final bool isThrottled;
  
  const PerformanceMetrics({
    required this.fps,
    required this.inferenceTimeMs,
    required this.cpuUsage,
    required this.memoryUsageMb,
    required this.frameDrops,
    required this.isThrottled,
  });
  
  bool get isPerformanceGood => 
    fps >= PerformanceConstants.targetFps * 0.8 &&
    inferenceTimeMs < PerformanceConstants.maxInferenceTimeMs;
  
  @override
  String toString() => 
    'FPS: ${fps.toStringAsFixed(1)}, '
    'Inference: ${inferenceTimeMs.toStringAsFixed(1)}ms, '
    'Drops: $frameDrops';
}

/// Frame rate controller with adaptive throttling
class FrameRateController {
  final int targetFps;
  final Queue<int> _frameTimes = Queue<int>();
  final int _windowSize = 30;
  
  int _lastFrameTime = 0;
  int _frameDrops = 0;
  int _adaptiveSkipCount = 0;
  
  FrameRateController({this.targetFps = PerformanceConstants.targetFps});
  
  /// Calculate target frame interval in milliseconds
  int get targetIntervalMs => (1000 / targetFps).round();
  
  /// Check if enough time has passed for next frame
  bool shouldProcessFrame() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_lastFrameTime == 0) {
      _lastFrameTime = now;
      return true;
    }
    
    final elapsed = now - _lastFrameTime;
    
    // Adaptive frame skipping under load
    if (_adaptiveSkipCount > 0) {
      _adaptiveSkipCount--;
      return false;
    }
    
    if (elapsed >= targetIntervalMs) {
      // Record frame time for FPS calculation
      _frameTimes.add(elapsed);
      if (_frameTimes.length > _windowSize) {
        _frameTimes.removeFirst();
      }
      
      _lastFrameTime = now;
      return true;
    }
    
    return false;
  }
  
  /// Report inference completed, potentially trigger adaptive skipping
  void reportInferenceComplete(int inferenceTimeMs) {
    if (inferenceTimeMs > PerformanceConstants.maxInferenceTimeMs) {
      _frameDrops++;
      // Enable adaptive frame skipping
      _adaptiveSkipCount = PerformanceConstants.adaptiveFrameSkip;
    }
  }
  
  /// Calculate current FPS
  double getCurrentFps() {
    if (_frameTimes.isEmpty) return 0.0;
    
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return 1000.0 / avgFrameTime;
  }
  
  /// Get frame drop count and reset
  int getAndResetFrameDrops() {
    final drops = _frameDrops;
    _frameDrops = 0;
    return drops;
  }
  
  /// Reset controller state
  void reset() {
    _frameTimes.clear();
    _lastFrameTime = 0;
    _frameDrops = 0;
    _adaptiveSkipCount = 0;
  }
}

/// Inference time tracker for performance monitoring
class InferenceTimer {
  int _startTime = 0;
  final List<int> _recentTimes = [];
  final int _historySize = 100;
  
  /// Start timing an inference
  void start() {
    _startTime = DateTime.now().microsecondsSinceEpoch;
  }
  
  /// Stop timing and return duration in milliseconds
  double stop() {
    final endTime = DateTime.now().microsecondsSinceEpoch;
    final durationMs = (endTime - _startTime) / 1000.0;
    
    _recentTimes.add(durationMs.round());
    if (_recentTimes.length > _historySize) {
      _recentTimes.removeAt(0);
    }
    
    return durationMs;
  }
  
  /// Get average inference time
  double get averageMs {
    if (_recentTimes.isEmpty) return 0.0;
    return _recentTimes.reduce((a, b) => a + b) / _recentTimes.length;
  }
  
  /// Get max inference time
  int get maxMs {
    if (_recentTimes.isEmpty) return 0;
    return _recentTimes.reduce((a, b) => a > b ? a : b);
  }
  
  /// Get min inference time
  int get minMs {
    if (_recentTimes.isEmpty) return 0;
    return _recentTimes.reduce((a, b) => a < b ? a : b);
  }
  
  /// Check if performance is within target
  bool get isWithinTarget => averageMs < PerformanceConstants.maxInferenceTimeMs;
}

/// Background isolate manager for CPU-intensive tasks
class IsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Completer<void>? _initCompleter;
  
  bool get isInitialized => _sendPort != null;
  
  /// Initialize background isolate
  Future<void> initialize(void Function(SendPort) entryPoint) async {
    if (isInitialized) return;
    
    _initCompleter = Completer<void>();
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      entryPoint,
      _receivePort!.sendPort,
    );
    
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _initCompleter?.complete();
      }
    });
    
    await _initCompleter!.future;
  }
  
  /// Send data to isolate for processing
  void send(dynamic data) {
    _sendPort?.send(data);
  }
  
  /// Listen for results from isolate
  Stream<dynamic> get results {
    return _receivePort?.asBroadcastStream() ?? const Stream.empty();
  }
  
  /// Dispose of isolate resources
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _sendPort = null;
    _receivePort = null;
  }
}

/// Memory-efficient object pool for reusing heavy objects
class ObjectPool<T> {
  final T Function() _factory;
  final void Function(T)? _reset;
  final Queue<T> _available = Queue<T>();
  final int _maxSize;
  
  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 10,
  }) : _factory = factory,
       _reset = reset,
       _maxSize = maxSize;
  
  /// Acquire an object from the pool
  T acquire() {
    if (_available.isNotEmpty) {
      return _available.removeFirst();
    }
    return _factory();
  }
  
  /// Release an object back to the pool
  void release(T object) {
    if (_available.length < _maxSize) {
      _reset?.call(object);
      _available.add(object);
    }
  }
  
  /// Clear all pooled objects
  void clear() {
    _available.clear();
  }
  
  int get availableCount => _available.length;
}

/// Throttle function calls to prevent excessive execution
class Throttler {
  final int intervalMs;
  int _lastExecutionTime = 0;
  
  Throttler({required this.intervalMs});
  
  /// Execute function if enough time has passed
  bool execute(void Function() action) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - _lastExecutionTime >= intervalMs) {
      _lastExecutionTime = now;
      action();
      return true;
    }
    
    return false;
  }
  
  /// Reset throttle timer
  void reset() {
    _lastExecutionTime = 0;
  }
}

/// Debouncer to delay execution until activity stops
class Debouncer {
  final int delayMs;
  Timer? _timer;
  
  Debouncer({required this.delayMs});
  
  /// Schedule execution after delay
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delayMs), action);
  }
  
  /// Cancel pending execution
  void cancel() {
    _timer?.cancel();
  }
  
  /// Dispose resources
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Battery-aware processing mode
enum ProcessingMode {
  highPerformance,  // Full FPS, max accuracy
  balanced,         // Normal operation
  batterySaver,     // Reduced FPS, skip frames
}

/// Battery-aware performance manager
class BatteryAwareManager {
  ProcessingMode _currentMode = ProcessingMode.balanced;
  
  ProcessingMode get currentMode => _currentMode;
  
  /// Get target FPS for current mode
  int get targetFps {
    switch (_currentMode) {
      case ProcessingMode.highPerformance:
        return 30;
      case ProcessingMode.balanced:
        return 15;
      case ProcessingMode.batterySaver:
        return 10;
    }
  }
  
  /// Get frame skip count for current mode
  int get frameSkip {
    switch (_currentMode) {
      case ProcessingMode.highPerformance:
        return 0;
      case ProcessingMode.balanced:
        return 1;
      case ProcessingMode.batterySaver:
        return 2;
    }
  }
  
  /// Update processing mode
  void setMode(ProcessingMode mode) {
    _currentMode = mode;
  }
  
  /// Auto-select mode based on battery level
  void updateForBatteryLevel(int batteryPercent) {
    if (batteryPercent <= 15) {
      _currentMode = ProcessingMode.batterySaver;
    } else if (batteryPercent <= 30) {
      _currentMode = ProcessingMode.balanced;
    } else {
      _currentMode = ProcessingMode.highPerformance;
    }
  }
}
