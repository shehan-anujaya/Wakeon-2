/// Drowsiness Detection BLoC
/// 
/// Manages the state of real-time drowsiness detection system.
/// Handles camera initialization, frame analysis, and alert triggering.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/alert_service.dart';
import '../../../domain/entities/detection_result.dart';
import '../../../domain/usecases/analyze_frame_usecase.dart';
import 'drowsiness_detection_event.dart';
import 'drowsiness_detection_state.dart';

/// BLoC for managing drowsiness detection
class DrowsinessDetectionBloc
    extends Bloc<DrowsinessDetectionEvent, DrowsinessDetectionState> {
  final AnalyzeFrameUseCase _analyzeFrameUseCase;
  final AlertService _alertService;
  
  StreamSubscription<FrameAnalysisResult>? _frameSubscription;
  Timer? _sessionTimer;
  Timer? _alertCooldownTimer;
  
  int _sessionDurationSec = 0;
  int _totalBlinks = 0;
  double _earSum = 0.0;
  int _earCount = 0;
  bool _isAlertActive = false;
  bool _canTriggerAlert = true;
  int _lastAlertTime = 0;
  
  // Sliding window for fatigue analysis
  final List<DrowsinessResult> _resultHistory = [];
  static const int _historySize = 60; // Last 60 results
  
  DrowsinessDetectionBloc({
    required AnalyzeFrameUseCase analyzeFrameUseCase,
    required AlertService alertService,
  })  : _analyzeFrameUseCase = analyzeFrameUseCase,
        _alertService = alertService,
        super(const DrowsinessDetectionInitial()) {
    on<InitializeDetection>(_onInitialize);
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<PauseMonitoring>(_onPauseMonitoring);
    on<ResumeMonitoring>(_onResumeMonitoring);
    on<FrameResultReceived>(_onFrameResultReceived);
    on<DrowsinessResultComputed>(_onDrowsinessResultComputed);
    on<TogglePreview>(_onTogglePreview);
    on<DismissAlert>(_onDismissAlert);
    on<TriggerEmergency>(_onTriggerEmergency);
    on<ResetSession>(_onResetSession);
    on<CameraPermissionResult>(_onCameraPermissionResult);
    on<RequestCameraPermission>(_onRequestCameraPermission);
    on<UpdateMetrics>(_onUpdateMetrics);
  }
  
  Future<void> _onInitialize(
    InitializeDetection event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    emit(const DrowsinessDetectionLoading(message: 'Checking permissions...'));
    
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    
    if (!cameraStatus.isGranted) {
      emit(const DrowsinessDetectionPermissionRequired());
      return;
    }
    
    emit(const DrowsinessDetectionLoading(
      message: 'Loading AI models...',
      progress: 0.3,
    ));
    
    try {
      await _analyzeFrameUseCase.initialize();
      await _alertService.initialize();
      
      emit(const DrowsinessDetectionLoading(
        message: 'Ready to start',
        progress: 1.0,
      ));
      
      // Short delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const DrowsinessDetectionActive());
    } catch (e) {
      emit(DrowsinessDetectionError(
        message: 'Failed to initialize: ${e.toString()}',
        error: e,
      ));
    }
  }
  
  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    if (state is! DrowsinessDetectionActive) return;
    
    try {
      await _analyzeFrameUseCase.start();
      
      // Subscribe to frame analysis results
      _frameSubscription = _analyzeFrameUseCase.analysisStream.listen(
        (result) => add(FrameResultReceived(result)),
      );
      
      // Start session timer
      _startSessionTimer();
      
      emit(const DrowsinessDetectionActive(showPreview: true));
    } catch (e) {
      emit(DrowsinessDetectionError(
        message: 'Failed to start monitoring: ${e.toString()}',
        error: e,
      ));
    }
  }
  
  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    await _cleanup();
    emit(const DrowsinessDetectionActive());
  }
  
  Future<void> _onPauseMonitoring(
    PauseMonitoring event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    if (state is DrowsinessDetectionActive) {
      final currentState = state as DrowsinessDetectionActive;
      await _analyzeFrameUseCase.stop();
      _sessionTimer?.cancel();
      
      emit(DrowsinessDetectionPaused(
        pausedAtSec: _sessionDurationSec,
        lastResult: currentState.currentResult,
      ));
    }
  }
  
  Future<void> _onResumeMonitoring(
    ResumeMonitoring event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    if (state is DrowsinessDetectionPaused) {
      final pausedState = state as DrowsinessDetectionPaused;
      
      await _analyzeFrameUseCase.start();
      _startSessionTimer();
      
      emit(DrowsinessDetectionActive(
        currentResult: pausedState.lastResult,
        sessionDurationSec: pausedState.pausedAtSec,
        showPreview: true,
      ));
    }
  }
  
  void _onFrameResultReceived(
    FrameResultReceived event,
    Emitter<DrowsinessDetectionState> emit,
  ) {
    if (state is! DrowsinessDetectionActive) return;
    
    final currentState = state as DrowsinessDetectionActive;
    final result = event.result;
    
    // Update EAR statistics
    if (result.isValid && result.facialFeatures != null) {
      _earSum += result.facialFeatures!.averageEAR;
      _earCount++;
    }
    
    emit(currentState.copyWith(
      frameResult: result,
      inferenceTimeMs: result.processingTimeMs,
    ));
    
    // If valid result, compute drowsiness level
    if (result.isValid) {
      _computeDrowsinessResult(result);
    }
  }
  
  void _computeDrowsinessResult(FrameAnalysisResult frameResult) {
    if (frameResult.inferenceResult == null) return;
    
    // Compute fatigue score from features
    final fatigueScore = _computeFatigueScore(frameResult);
    final level = _determineDrowsinessLevel(fatigueScore);
    final action = _getRecommendedAction(level, fatigueScore);
    
    final result = DrowsinessResult(
      level: level,
      fatigueScore: fatigueScore,
      confidence: frameResult.inferenceResult!.maxProbability,
      currentEAR: frameResult.facialFeatures!.averageEAR,
      perclos: _computePERCLOS(),
      blinkRate: _computeBlinkRate(),
      headPoseScore: _computeHeadPoseScore(frameResult.facialFeatures!),
      recommendedAction: action,
      timeInState: _getTimeInCurrentState(level),
      timestamp: frameResult.timestamp,
    );
    
    // Add to history for trend analysis
    _resultHistory.add(result);
    if (_resultHistory.length > _historySize) {
      _resultHistory.removeAt(0);
    }
    
    add(DrowsinessResultComputed(result));
  }
  
  double _computeFatigueScore(FrameAnalysisResult result) {
    final features = result.facialFeatures!;
    final inference = result.inferenceResult!;
    
    // Weighted composite score
    final earScore = _normalizeEAR(features.averageEAR);
    final blinkScore = _normalizeBlinkRate(_computeBlinkRate());
    final headScore = _computeHeadPoseScore(features);
    final modelScore = inference.drowsyProbability + 
                       inference.microsleepProbability * 1.5;
    
    return (earScore * FatigueConstants.earWeight +
            blinkScore * FatigueConstants.blinkRateWeight +
            headScore * FatigueConstants.headPoseWeight +
            modelScore * 0.30).clamp(0.0, 1.0);
  }
  
  double _normalizeEAR(double ear) {
    // Lower EAR = higher score (more closed)
    if (ear >= EarConstants.normalEar) return 0.0;
    if (ear <= EarConstants.criticalThreshold) return 1.0;
    return 1.0 - (ear - EarConstants.criticalThreshold) /
           (EarConstants.normalEar - EarConstants.criticalThreshold);
  }
  
  double _normalizeBlinkRate(double blinkRate) {
    // Abnormal blink rates indicate fatigue
    if (blinkRate < FatigueConstants.lowBlinkRateThreshold) {
      return (FatigueConstants.lowBlinkRateThreshold - blinkRate) / 
             FatigueConstants.lowBlinkRateThreshold;
    }
    if (blinkRate > FatigueConstants.highBlinkRateThreshold) {
      return (blinkRate - FatigueConstants.highBlinkRateThreshold) / 30.0;
    }
    return 0.0;
  }
  
  double _computeHeadPoseScore(dynamic features) {
    final (yawNorm, pitchNorm, rollNorm) = features.normalizedHeadPose;
    return (yawNorm + pitchNorm * 1.5 + rollNorm) / 3.5;
  }
  
  double _computePERCLOS() {
    if (_resultHistory.isEmpty) return 0.0;
    
    // Count frames where eyes were closed
    final closedCount = _resultHistory.where((r) =>
      r.currentEAR < EarConstants.closedThreshold
    ).length;
    
    return closedCount / _resultHistory.length;
  }
  
  double _computeBlinkRate() {
    // Approximate based on session data
    if (_sessionDurationSec < 10) return FatigueConstants.normalBlinkRate;
    return _totalBlinks / (_sessionDurationSec / 60.0);
  }
  
  DrowsinessLevel _determineDrowsinessLevel(double fatigueScore) {
    if (fatigueScore >= FatigueConstants.criticalThreshold) {
      return DrowsinessLevel.critical;
    }
    if (fatigueScore >= FatigueConstants.warningThreshold) {
      return DrowsinessLevel.warning;
    }
    return DrowsinessLevel.normal;
  }
  
  RecommendedAction _getRecommendedAction(
    DrowsinessLevel level,
    double fatigueScore,
  ) {
    switch (level) {
      case DrowsinessLevel.normal:
        return RecommendedAction.none;
      case DrowsinessLevel.warning:
        return fatigueScore > 0.7
            ? RecommendedAction.takeBrakeNow
            : RecommendedAction.stayAlert;
      case DrowsinessLevel.critical:
        return RecommendedAction.pullOverImmediately;
    }
  }
  
  int _getTimeInCurrentState(DrowsinessLevel level) {
    if (_resultHistory.isEmpty) return 0;
    
    int count = 0;
    for (int i = _resultHistory.length - 1; i >= 0; i--) {
      if (_resultHistory[i].level == level) {
        count++;
      } else {
        break;
      }
    }
    
    // Approximate time based on ~30fps
    return (count * 33).round();
  }
  
  void _onDrowsinessResultComputed(
    DrowsinessResultComputed event,
    Emitter<DrowsinessDetectionState> emit,
  ) {
    if (state is! DrowsinessDetectionActive) return;
    
    final currentState = state as DrowsinessDetectionActive;
    final result = event.result;
    
    // Check if we need to trigger an alert
    if (_shouldTriggerAlert(result)) {
      _triggerAlert(result);
    }
    
    emit(currentState.copyWith(
      currentResult: result,
      sessionDurationSec: _sessionDurationSec,
      totalBlinks: _totalBlinks,
      averageEAR: _earCount > 0 ? _earSum / _earCount : 0.0,
    ));
  }
  
  bool _shouldTriggerAlert(DrowsinessResult result) {
    if (_isAlertActive || !_canTriggerAlert) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastAlertTime < AlertConstants.alertCooldownMs) return false;
    
    return result.level == DrowsinessLevel.warning ||
           result.level == DrowsinessLevel.critical;
  }
  
  void _triggerAlert(DrowsinessResult result) {
    _isAlertActive = true;
    _lastAlertTime = DateTime.now().millisecondsSinceEpoch;
    
    if (result.level == DrowsinessLevel.critical) {
      _alertService.triggerCriticalAlert();
    } else {
      _alertService.triggerWarningAlert();
    }
    
    // Auto-dismiss after timeout
    _alertCooldownTimer?.cancel();
    _alertCooldownTimer = Timer(
      Duration(milliseconds: AlertConstants.alertDurationMs),
      () {
        _isAlertActive = false;
        add(const DismissAlert());
      },
    );
  }
  
  void _onTogglePreview(
    TogglePreview event,
    Emitter<DrowsinessDetectionState> emit,
  ) {
    if (state is DrowsinessDetectionActive) {
      emit((state as DrowsinessDetectionActive).copyWith(
        showPreview: event.show,
      ));
    }
  }
  
  void _onDismissAlert(
    DismissAlert event,
    Emitter<DrowsinessDetectionState> emit,
  ) {
    _isAlertActive = false;
    _alertService.stopAlert();
    
    if (state is DrowsinessDetectionAlert) {
      final alertState = state as DrowsinessDetectionAlert;
      emit(DrowsinessDetectionActive(
        currentResult: alertState.result,
        showPreview: true,
        sessionDurationSec: _sessionDurationSec,
      ));
    }
  }
  
  Future<void> _onTriggerEmergency(
    TriggerEmergency event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    await _alertService.triggerEmergency();
  }
  
  Future<void> _onResetSession(
    ResetSession event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    await _cleanup();
    _sessionDurationSec = 0;
    _totalBlinks = 0;
    _earSum = 0.0;
    _earCount = 0;
    _resultHistory.clear();
    
    emit(const DrowsinessDetectionActive());
  }
  
  Future<void> _onCameraPermissionResult(
    CameraPermissionResult event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    if (event.granted) {
      add(const InitializeDetection());
    } else {
      emit(const DrowsinessDetectionError(
        message: 'Camera permission is required for drowsiness detection',
        canRetry: true,
      ));
    }
  }
  
  Future<void> _onRequestCameraPermission(
    RequestCameraPermission event,
    Emitter<DrowsinessDetectionState> emit,
  ) async {
    final status = await Permission.camera.request();
    add(CameraPermissionResult(status.isGranted));
  }
  
  void _onUpdateMetrics(
    UpdateMetrics event,
    Emitter<DrowsinessDetectionState> emit,
  ) {
    if (state is DrowsinessDetectionActive) {
      emit((state as DrowsinessDetectionActive).copyWith(
        fps: event.fps,
        inferenceTimeMs: event.inferenceTimeMs,
      ));
    }
  }
  
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionDurationSec++;
    });
  }
  
  Future<void> _cleanup() async {
    _frameSubscription?.cancel();
    _sessionTimer?.cancel();
    _alertCooldownTimer?.cancel();
    await _analyzeFrameUseCase.stop();
    _alertService.stopAlert();
    _isAlertActive = false;
  }
  
  @override
  Future<void> close() async {
    await _cleanup();
    await _analyzeFrameUseCase.dispose();
    await _alertService.dispose();
    return super.close();
  }
}
