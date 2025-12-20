/// Settings Entity
/// 
/// Represents application settings and user preferences.

/// Application settings
class AppSettings {
  // Detection settings
  final double sensitivityLevel;
  final double earThreshold;
  final bool alertsEnabled;
  final bool audioAlertsEnabled;
  final bool hapticAlertsEnabled;
  
  // Emergency settings
  final bool emergencyContactEnabled;
  final String? emergencyContactNumber;
  final String? emergencyContactName;
  
  // Calibration data
  final bool isCalibrated;
  final double calibratedEarBaseline;
  final double calibratedEarStdDev;
  
  // Driver profile
  final String? driverName;
  final int totalDrivingTimeMinutes;
  final int totalAlerts;
  
  // UI settings
  final bool showDebugInfo;
  final bool showCameraPreview;
  
  const AppSettings({
    this.sensitivityLevel = 0.5,
    this.earThreshold = 0.21,
    this.alertsEnabled = true,
    this.audioAlertsEnabled = true,
    this.hapticAlertsEnabled = true,
    this.emergencyContactEnabled = false,
    this.emergencyContactNumber,
    this.emergencyContactName,
    this.isCalibrated = false,
    this.calibratedEarBaseline = 0.30,
    this.calibratedEarStdDev = 0.05,
    this.driverName,
    this.totalDrivingTimeMinutes = 0,
    this.totalAlerts = 0,
    this.showDebugInfo = false,
    this.showCameraPreview = true,
  });
  
  /// Get adaptive EAR threshold based on calibration
  double get adaptiveEarThreshold {
    if (!isCalibrated) return earThreshold;
    
    // Threshold = baseline - (2 * stdDev) adjusted by sensitivity
    final baseThreshold = calibratedEarBaseline - (2 * calibratedEarStdDev);
    final sensitivityAdjustment = (0.5 - sensitivityLevel) * 0.05;
    
    return (baseThreshold + sensitivityAdjustment).clamp(0.15, 0.25);
  }
  
  /// Get formatted total driving time
  String get formattedDrivingTime {
    final hours = totalDrivingTimeMinutes ~/ 60;
    final minutes = totalDrivingTimeMinutes % 60;
    
    if (hours > 0) {
      return '$hours h ${minutes} min';
    }
    return '$minutes min';
  }
  
  /// Create copy with updated values
  AppSettings copyWith({
    double? sensitivityLevel,
    double? earThreshold,
    bool? alertsEnabled,
    bool? audioAlertsEnabled,
    bool? hapticAlertsEnabled,
    bool? emergencyContactEnabled,
    String? emergencyContactNumber,
    String? emergencyContactName,
    bool? isCalibrated,
    double? calibratedEarBaseline,
    double? calibratedEarStdDev,
    String? driverName,
    int? totalDrivingTimeMinutes,
    int? totalAlerts,
    bool? showDebugInfo,
    bool? showCameraPreview,
  }) {
    return AppSettings(
      sensitivityLevel: sensitivityLevel ?? this.sensitivityLevel,
      earThreshold: earThreshold ?? this.earThreshold,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      audioAlertsEnabled: audioAlertsEnabled ?? this.audioAlertsEnabled,
      hapticAlertsEnabled: hapticAlertsEnabled ?? this.hapticAlertsEnabled,
      emergencyContactEnabled: emergencyContactEnabled ?? this.emergencyContactEnabled,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      calibratedEarBaseline: calibratedEarBaseline ?? this.calibratedEarBaseline,
      calibratedEarStdDev: calibratedEarStdDev ?? this.calibratedEarStdDev,
      driverName: driverName ?? this.driverName,
      totalDrivingTimeMinutes: totalDrivingTimeMinutes ?? this.totalDrivingTimeMinutes,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      showCameraPreview: showCameraPreview ?? this.showCameraPreview,
    );
  }
}

/// Calibration data for adaptive thresholds
class CalibrationData {
  /// Baseline EAR value for this driver (eyes open)
  final double earBaseline;
  
  /// Standard deviation of EAR measurements
  final double earStdDev;
  
  /// Calibration timestamp
  final int timestamp;
  
  const CalibrationData({
    required this.earBaseline,
    required this.earStdDev,
    required this.timestamp,
  });
  
  /// Check if calibration is still valid (less than 7 days old)
  bool get isValid {
    final now = DateTime.now().millisecondsSinceEpoch;
    const sevenDays = 7 * 24 * 60 * 60 * 1000;
    return (now - timestamp) < sevenDays;
  }
  
  /// Calculate adaptive threshold
  double get adaptiveThreshold => earBaseline - (2 * earStdDev);
}
