/// Settings Screen
/// 
/// Allows users to configure detection sensitivity,
/// alert preferences, and emergency contacts with
/// modern glass-morphism design.

import 'dart:ui';

import 'package:flutter/material.dart';

/// Settings configuration screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings values
  double _sensitivity = 0.5;
  bool _audioAlerts = true;
  bool _hapticFeedback = true;
  bool _emergencyEnabled = false;
  String _emergencyContact = '';
  bool _adaptiveThresholds = true;
  double _alertVolume = 0.8;
  int _warningDelay = 3;
  int _criticalDelay = 5;

  // Design colors
  static const Color _primaryColor = Color(0xFF6C63FF);
  static const Color _backgroundColor = Color(0xFF0A0A1E);
  static const Color _surfaceColor = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                // Settings List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      const SizedBox(height: 8),
                      
                      // Detection Settings
                      _buildSectionHeader('Detection', Icons.radar_rounded),
                      _buildGlassCard([
                        _buildSliderTile(
                          title: 'Sensitivity',
                          subtitle: _getSensitivityLabel(_sensitivity),
                          value: _sensitivity,
                          onChanged: (v) => setState(() => _sensitivity = v),
                          icon: Icons.tune_rounded,
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          title: 'Adaptive Thresholds',
                          subtitle: 'Adjust detection based on conditions',
                          value: _adaptiveThresholds,
                          onChanged: (v) => setState(() => _adaptiveThresholds = v),
                          icon: Icons.auto_fix_high_rounded,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Alert Settings
                      _buildSectionHeader('Alerts', Icons.notifications_rounded),
                      _buildGlassCard([
                        _buildSwitchTile(
                          title: 'Audio Alerts',
                          subtitle: 'Play warning sounds',
                          value: _audioAlerts,
                          onChanged: (v) => setState(() => _audioAlerts = v),
                          icon: Icons.volume_up_rounded,
                        ),
                        if (_audioAlerts) ...[
                          _buildDivider(),
                          _buildSliderTile(
                            title: 'Alert Volume',
                            subtitle: '${(_alertVolume * 100).round()}%',
                            value: _alertVolume,
                            onChanged: (v) => setState(() => _alertVolume = v),
                            icon: Icons.speaker_rounded,
                          ),
                        ],
                        _buildDivider(),
                        _buildSwitchTile(
                          title: 'Haptic Feedback',
                          subtitle: 'Vibration alerts',
                          value: _hapticFeedback,
                          onChanged: (v) => setState(() => _hapticFeedback = v),
                          icon: Icons.vibration_rounded,
                        ),
                        _buildDivider(),
                        _buildStepperTile(
                          title: 'Warning Delay',
                          subtitle: 'Seconds before warning',
                          value: _warningDelay,
                          min: 1,
                          max: 10,
                          onChanged: (v) => setState(() => _warningDelay = v),
                          icon: Icons.timer_rounded,
                        ),
                        _buildDivider(),
                        _buildStepperTile(
                          title: 'Critical Delay',
                          subtitle: 'Seconds before critical',
                          value: _criticalDelay,
                          min: 2,
                          max: 15,
                          onChanged: (v) => setState(() => _criticalDelay = v),
                          icon: Icons.warning_amber_rounded,
                        ),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Emergency Settings
                      _buildSectionHeader('Emergency', Icons.emergency_rounded),
                      _buildGlassCard([
                        _buildSwitchTile(
                          title: 'Emergency Contact',
                          subtitle: 'Send SMS on critical alerts',
                          value: _emergencyEnabled,
                          onChanged: (v) => setState(() => _emergencyEnabled = v),
                          icon: Icons.sos_rounded,
                        ),
                        if (_emergencyEnabled) ...[
                          _buildDivider(),
                          _buildTextFieldTile(
                            title: 'Phone Number',
                            value: _emergencyContact,
                            onChanged: (v) => setState(() => _emergencyContact = v),
                            icon: Icons.phone_rounded,
                          ),
                        ],
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // About
                      _buildSectionHeader('About', Icons.info_rounded),
                      _buildGlassCard([
                        _buildInfoTile(
                          title: 'Version',
                          value: '1.0.0',
                          icon: Icons.tag_rounded,
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          title: 'Privacy Policy',
                          icon: Icons.privacy_tip_rounded,
                          onTap: () {},
                        ),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      // Save button
                      _buildSaveButton(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Top gradient blob
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.3),
                  _primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient blob
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E676).withValues(alpha: 0.2),
                  const Color(0xFF00E676).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 56), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _primaryColor,
            activeTrackColor: _primaryColor.withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: _primaryColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: _primaryColor.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperTile({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.remove_rounded,
                      color: value > min 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 36),
                  child: Text(
                    '${value}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.add_rounded,
                      color: value < max 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryColor,
              _primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Save Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSensitivityLabel(double value) {
    if (value < 0.3) return 'Low - Fewer alerts';
    if (value < 0.7) return 'Medium - Balanced';
    return 'High - Better safety';
  }

  void _saveSettings() {
    // Save settings to repository
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
    Navigator.pop(context);
  }
}
