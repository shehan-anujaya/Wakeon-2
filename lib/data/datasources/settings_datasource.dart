/// Settings Data Source
/// 
/// Handles persistent storage of user preferences and calibration data.

import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for settings data source
abstract class SettingsDataSource {
  /// Get a boolean setting
  Future<bool> getBool(String key, {bool defaultValue = false});
  
  /// Set a boolean setting
  Future<void> setBool(String key, bool value);
  
  /// Get a double setting
  Future<double> getDouble(String key, {double defaultValue = 0.0});
  
  /// Set a double setting
  Future<void> setDouble(String key, double value);
  
  /// Get an integer setting
  Future<int> getInt(String key, {int defaultValue = 0});
  
  /// Set an integer setting
  Future<void> setInt(String key, int value);
  
  /// Get a string setting
  Future<String?> getString(String key);
  
  /// Set a string setting
  Future<void> setString(String key, String value);
  
  /// Get a list of strings
  Future<List<String>> getStringList(String key);
  
  /// Set a list of strings
  Future<void> setStringList(String key, List<String> value);
  
  /// Remove a setting
  Future<void> remove(String key);
  
  /// Clear all settings
  Future<void> clear();
}

/// Implementation using SharedPreferences
class SettingsDataSourceImpl implements SettingsDataSource {
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _preferences;
    return prefs.getBool(key) ?? defaultValue;
  }
  
  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }
  
  @override
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final prefs = await _preferences;
    return prefs.getDouble(key) ?? defaultValue;
  }
  
  @override
  Future<void> setDouble(String key, double value) async {
    final prefs = await _preferences;
    await prefs.setDouble(key, value);
  }
  
  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await _preferences;
    return prefs.getInt(key) ?? defaultValue;
  }
  
  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }
  
  @override
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }
  
  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }
  
  @override
  Future<List<String>> getStringList(String key) async {
    final prefs = await _preferences;
    return prefs.getStringList(key) ?? [];
  }
  
  @override
  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _preferences;
    await prefs.setStringList(key, value);
  }
  
  @override
  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }
  
  @override
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}

/// Settings keys constants
class SettingsKeys {
  SettingsKeys._();
  
  // Detection settings
  static const String sensitivityLevel = 'sensitivity_level';
  static const String earThreshold = 'ear_threshold';
  static const String alertsEnabled = 'alerts_enabled';
  static const String audioAlertsEnabled = 'audio_alerts_enabled';
  static const String hapticAlertsEnabled = 'haptic_alerts_enabled';
  
  // Emergency settings
  static const String emergencyContactEnabled = 'emergency_contact_enabled';
  static const String emergencyContactNumber = 'emergency_contact_number';
  static const String emergencyContactName = 'emergency_contact_name';
  
  // Calibration data
  static const String isCalibrated = 'is_calibrated';
  static const String calibratedEarBaseline = 'calibrated_ear_baseline';
  static const String calibratedEarStdDev = 'calibrated_ear_std_dev';
  static const String calibrationTimestamp = 'calibration_timestamp';
  
  // Driver profile
  static const String driverName = 'driver_name';
  static const String totalDrivingTime = 'total_driving_time';
  static const String totalAlerts = 'total_alerts';
  static const String lastSessionDate = 'last_session_date';
  
  // Performance settings
  static const String performanceMode = 'performance_mode';
  static const String targetFps = 'target_fps';
  
  // UI settings
  static const String showDebugInfo = 'show_debug_info';
  static const String showCameraPreview = 'show_camera_preview';
}
