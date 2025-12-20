/// Settings Repository Implementation
/// 
/// Implements the settings domain interface using local storage.

import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_datasource.dart';

/// Implementation of settings repository
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource dataSource;
  
  SettingsRepositoryImpl({required this.dataSource});
  
  @override
  Future<AppSettings> loadSettings() async {
    return AppSettings(
      // Detection settings
      sensitivityLevel: await dataSource.getDouble(
        SettingsKeys.sensitivityLevel,
        defaultValue: 0.5,
      ),
      earThreshold: await dataSource.getDouble(
        SettingsKeys.earThreshold,
        defaultValue: 0.21,
      ),
      alertsEnabled: await dataSource.getBool(
        SettingsKeys.alertsEnabled,
        defaultValue: true,
      ),
      audioAlertsEnabled: await dataSource.getBool(
        SettingsKeys.audioAlertsEnabled,
        defaultValue: true,
      ),
      hapticAlertsEnabled: await dataSource.getBool(
        SettingsKeys.hapticAlertsEnabled,
        defaultValue: true,
      ),
      
      // Emergency settings
      emergencyContactEnabled: await dataSource.getBool(
        SettingsKeys.emergencyContactEnabled,
        defaultValue: false,
      ),
      emergencyContactNumber: await dataSource.getString(
        SettingsKeys.emergencyContactNumber,
      ),
      emergencyContactName: await dataSource.getString(
        SettingsKeys.emergencyContactName,
      ),
      
      // Calibration data
      isCalibrated: await dataSource.getBool(
        SettingsKeys.isCalibrated,
        defaultValue: false,
      ),
      calibratedEarBaseline: await dataSource.getDouble(
        SettingsKeys.calibratedEarBaseline,
        defaultValue: 0.30,
      ),
      calibratedEarStdDev: await dataSource.getDouble(
        SettingsKeys.calibratedEarStdDev,
        defaultValue: 0.05,
      ),
      
      // Driver profile
      driverName: await dataSource.getString(SettingsKeys.driverName),
      totalDrivingTimeMinutes: await dataSource.getInt(
        SettingsKeys.totalDrivingTime,
        defaultValue: 0,
      ),
      totalAlerts: await dataSource.getInt(
        SettingsKeys.totalAlerts,
        defaultValue: 0,
      ),
      
      // UI settings
      showDebugInfo: await dataSource.getBool(
        SettingsKeys.showDebugInfo,
        defaultValue: false,
      ),
      showCameraPreview: await dataSource.getBool(
        SettingsKeys.showCameraPreview,
        defaultValue: true,
      ),
    );
  }
  
  @override
  Future<void> saveSettings(AppSettings settings) async {
    await dataSource.setDouble(SettingsKeys.sensitivityLevel, settings.sensitivityLevel);
    await dataSource.setDouble(SettingsKeys.earThreshold, settings.earThreshold);
    await dataSource.setBool(SettingsKeys.alertsEnabled, settings.alertsEnabled);
    await dataSource.setBool(SettingsKeys.audioAlertsEnabled, settings.audioAlertsEnabled);
    await dataSource.setBool(SettingsKeys.hapticAlertsEnabled, settings.hapticAlertsEnabled);
    await dataSource.setBool(SettingsKeys.emergencyContactEnabled, settings.emergencyContactEnabled);
    
    if (settings.emergencyContactNumber != null) {
      await dataSource.setString(SettingsKeys.emergencyContactNumber, settings.emergencyContactNumber!);
    }
    if (settings.emergencyContactName != null) {
      await dataSource.setString(SettingsKeys.emergencyContactName, settings.emergencyContactName!);
    }
    
    await dataSource.setBool(SettingsKeys.isCalibrated, settings.isCalibrated);
    await dataSource.setDouble(SettingsKeys.calibratedEarBaseline, settings.calibratedEarBaseline);
    await dataSource.setDouble(SettingsKeys.calibratedEarStdDev, settings.calibratedEarStdDev);
    
    if (settings.driverName != null) {
      await dataSource.setString(SettingsKeys.driverName, settings.driverName!);
    }
    await dataSource.setInt(SettingsKeys.totalDrivingTime, settings.totalDrivingTimeMinutes);
    await dataSource.setInt(SettingsKeys.totalAlerts, settings.totalAlerts);
    
    await dataSource.setBool(SettingsKeys.showDebugInfo, settings.showDebugInfo);
    await dataSource.setBool(SettingsKeys.showCameraPreview, settings.showCameraPreview);
  }
  
  @override
  Future<void> saveCalibration(CalibrationData calibration) async {
    await dataSource.setBool(SettingsKeys.isCalibrated, true);
    await dataSource.setDouble(SettingsKeys.calibratedEarBaseline, calibration.earBaseline);
    await dataSource.setDouble(SettingsKeys.calibratedEarStdDev, calibration.earStdDev);
    await dataSource.setInt(SettingsKeys.calibrationTimestamp, calibration.timestamp);
  }
  
  @override
  Future<CalibrationData?> loadCalibration() async {
    final isCalibrated = await dataSource.getBool(SettingsKeys.isCalibrated);
    
    if (!isCalibrated) return null;
    
    return CalibrationData(
      earBaseline: await dataSource.getDouble(
        SettingsKeys.calibratedEarBaseline,
        defaultValue: 0.30,
      ),
      earStdDev: await dataSource.getDouble(
        SettingsKeys.calibratedEarStdDev,
        defaultValue: 0.05,
      ),
      timestamp: await dataSource.getInt(SettingsKeys.calibrationTimestamp),
    );
  }
  
  @override
  Future<void> updateDrivingStats({
    required int additionalMinutes,
    required int additionalAlerts,
  }) async {
    final currentTime = await dataSource.getInt(SettingsKeys.totalDrivingTime);
    final currentAlerts = await dataSource.getInt(SettingsKeys.totalAlerts);
    
    await dataSource.setInt(
      SettingsKeys.totalDrivingTime,
      currentTime + additionalMinutes,
    );
    await dataSource.setInt(
      SettingsKeys.totalAlerts,
      currentAlerts + additionalAlerts,
    );
    await dataSource.setString(
      SettingsKeys.lastSessionDate,
      DateTime.now().toIso8601String(),
    );
  }
  
  @override
  Future<void> clearCalibration() async {
    await dataSource.setBool(SettingsKeys.isCalibrated, false);
    await dataSource.remove(SettingsKeys.calibratedEarBaseline);
    await dataSource.remove(SettingsKeys.calibratedEarStdDev);
    await dataSource.remove(SettingsKeys.calibrationTimestamp);
  }
  
  @override
  Future<void> resetAllSettings() async {
    await dataSource.clear();
  }
}
