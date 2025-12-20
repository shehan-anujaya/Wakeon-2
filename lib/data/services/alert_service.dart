/// Alert Service
/// 
/// Manages audio and haptic alerts for driver safety warnings.
/// Implements multi-stage escalation system.

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

/// Service for managing driver alerts
class AlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  bool _hasVibrator = false;
  int _lastAlertTime = 0;
  AlertLevel _lastAlertLevel = AlertLevel.normal;
  String? _emergencyContact;
  
  bool get isInitialized => _isInitialized;
  
  /// Initialize alert service
  Future<void> initialize() async {
    try {
      // Check device capabilities
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      
      // Configure audio player
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Set emergency contact number
  void setEmergencyContact(String? phoneNumber) {
    _emergencyContact = phoneNumber;
  }
  
  /// Trigger alert based on level
  /// Returns true if alert was triggered, false if in cooldown
  Future<bool> triggerAlert(AlertLevel level, {double confidence = 1.0}) async {
    if (!_isInitialized) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check cooldown (unless escalating)
    if (level.index <= _lastAlertLevel.index &&
        now - _lastAlertTime < AlertConstants.alertCooldownMs) {
      return false;
    }
    
    // Check confidence threshold
    if (confidence < AlertConstants.alertConfidenceThreshold) {
      return false;
    }
    
    _lastAlertTime = now;
    _lastAlertLevel = level;
    
    switch (level) {
      case AlertLevel.normal:
        // No alert for normal state
        return false;
        
      case AlertLevel.warning:
        await triggerWarningAlert();
        return true;
        
      case AlertLevel.critical:
        await triggerCriticalAlert();
        return true;
    }
  }
  
  /// Trigger warning level alert (public method for BLoC)
  Future<void> triggerWarningAlert() async {
    // Haptic feedback
    if (_hasVibrator) {
      await Vibration.vibrate(
        pattern: AlertConstants.warningVibrationPattern,
      );
    }
    
    // Audio alert
    await _audioPlayer.setVolume(AlertConstants.warningVolume);
    await _audioPlayer.play(
      AssetSource('audio/warning_beep.mp3'),
    );
  }
  
  /// Trigger critical level alert (public method for BLoC)
  Future<void> triggerCriticalAlert() async {
    // Strong haptic feedback
    if (_hasVibrator) {
      await Vibration.vibrate(
        pattern: AlertConstants.criticalVibrationPattern,
      );
    }
    
    // Loud audio alert
    await _audioPlayer.setVolume(AlertConstants.criticalVolume);
    await _audioPlayer.play(
      AssetSource('audio/critical_alarm.mp3'),
    );
  }
  
  /// Stop all active alerts (alias for stopAlerts)
  Future<void> stopAlert() async {
    await stopAlerts();
  }
  
  /// Stop all active alerts
  Future<void> stopAlerts() async {
    await _audioPlayer.stop();
    if (_hasVibrator) {
      await Vibration.cancel();
    }
    _lastAlertLevel = AlertLevel.normal;
  }
  
  /// Trigger emergency - call/SMS emergency contact
  Future<void> triggerEmergency() async {
    if (_emergencyContact == null || _emergencyContact!.isEmpty) {
      return;
    }
    
    // Attempt to make phone call
    final phoneUri = Uri.parse('tel:$_emergencyContact');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
  
  /// Play acknowledgment sound when driver confirms alert
  Future<void> playAcknowledgment() async {
    await _audioPlayer.setVolume(0.3);
    await _audioPlayer.play(
      AssetSource('audio/acknowledgment.mp3'),
    );
  }
  
  /// Check if currently in alert cooldown
  bool isInCooldown() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - _lastAlertTime < AlertConstants.alertCooldownMs;
  }
  
  /// Get time remaining in cooldown (ms)
  int getCooldownRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastAlertTime;
    return (AlertConstants.alertCooldownMs - elapsed).clamp(0, AlertConstants.alertCooldownMs);
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isInitialized = false;
  }
}

/// Emergency contact service for critical situations
class EmergencyContactService {
  static const String _prefsKeyEmergencyContact = 'emergency_contact';
  static const String _prefsKeyEmergencyEnabled = 'emergency_enabled';
  
  String? _emergencyContact;
  bool _isEnabled = false;
  int _criticalStartTime = 0;
  bool _emergencyTriggered = false;
  
  bool get isEnabled => _isEnabled;
  bool get hasContact => _emergencyContact != null && _emergencyContact!.isNotEmpty;
  
  /// Configure emergency contact
  void configure({
    required String? phoneNumber,
    required bool enabled,
  }) {
    _emergencyContact = phoneNumber;
    _isEnabled = enabled;
  }
  
  /// Start critical state timer
  void startCriticalTimer() {
    if (_criticalStartTime == 0) {
      _criticalStartTime = DateTime.now().millisecondsSinceEpoch;
    }
  }
  
  /// Reset critical state timer
  void resetCriticalTimer() {
    _criticalStartTime = 0;
    _emergencyTriggered = false;
  }
  
  /// Check if emergency should be triggered
  /// Returns true if driver has been in critical state too long
  bool shouldTriggerEmergency() {
    if (!_isEnabled || !hasContact || _emergencyTriggered) {
      return false;
    }
    
    if (_criticalStartTime == 0) {
      return false;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = now - _criticalStartTime;
    
    return duration >= AlertConstants.emergencyEscalationDelayMs;
  }
  
  /// Get SMS message for emergency contact
  String getEmergencyMessage(String? driverName) {
    return 'ALERT: ${driverName ?? "Driver"} may be experiencing a drowsiness emergency. '
        'WakeOn app has detected prolonged critical fatigue. '
        'Please try to contact them immediately. '
        'Time: ${DateTime.now().toIso8601String()}';
  }
  
  /// Mark emergency as triggered
  void markEmergencyTriggered() {
    _emergencyTriggered = true;
  }
  
  /// Get emergency contact number
  String? get emergencyContact => _emergencyContact;
}

/// Alert severity levels
enum AlertLevel {
  /// Normal state, no alert needed
  normal,
  
  /// Warning level - moderate fatigue
  warning,
  
  /// Critical level - severe fatigue/microsleep
  critical,
}
