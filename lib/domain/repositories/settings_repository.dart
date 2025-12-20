/// Settings Repository Interface
/// 
/// Defines the contract for settings and calibration data operations.

import '../entities/settings.dart';

/// Abstract repository for settings
abstract class SettingsRepository {
  /// Load all settings
  Future<AppSettings> loadSettings();
  
  /// Save all settings
  Future<void> saveSettings(AppSettings settings);
  
  /// Save calibration data
  Future<void> saveCalibration(CalibrationData calibration);
  
  /// Load calibration data
  Future<CalibrationData?> loadCalibration();
  
  /// Update driving statistics
  Future<void> updateDrivingStats({
    required int additionalMinutes,
    required int additionalAlerts,
  });
  
  /// Clear calibration data
  Future<void> clearCalibration();
  
  /// Reset all settings to defaults
  Future<void> resetAllSettings();
}
