/// Settings Screen
/// 
/// Allows users to configure detection sensitivity,
/// alert preferences, and emergency contacts.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/settings.dart';

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
  bool _darkMode = true;
  bool _adaptiveThresholds = true;
  double _alertVolume = 0.8;
  int _warningDelay = 3;
  int _criticalDelay = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Detection Settings
          _buildSectionHeader('Detection'),
          _buildCard([
            _buildSliderTile(
              title: 'Sensitivity',
              subtitle: _getSensitivityLabel(_sensitivity),
              value: _sensitivity,
              onChanged: (v) => setState(() => _sensitivity = v),
              icon: Icons.tune,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Adaptive Thresholds',
              subtitle: 'Adjust detection based on driving conditions',
              value: _adaptiveThresholds,
              onChanged: (v) => setState(() => _adaptiveThresholds = v),
              icon: Icons.auto_fix_high,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Alert Settings
          _buildSectionHeader('Alerts'),
          _buildCard([
            _buildSwitchTile(
              title: 'Audio Alerts',
              subtitle: 'Play warning sounds',
              value: _audioAlerts,
              onChanged: (v) => setState(() => _audioAlerts = v),
              icon: Icons.volume_up,
            ),
            if (_audioAlerts) ...[
              const Divider(height: 1),
              _buildSliderTile(
                title: 'Alert Volume',
                subtitle: '${(_alertVolume * 100).round()}%',
                value: _alertVolume,
                onChanged: (v) => setState(() => _alertVolume = v),
                icon: Icons.speaker,
              ),
            ],
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Haptic Feedback',
              subtitle: 'Vibration alerts',
              value: _hapticFeedback,
              onChanged: (v) => setState(() => _hapticFeedback = v),
              icon: Icons.vibration,
            ),
            const Divider(height: 1),
            _buildNumberTile(
              title: 'Warning Delay',
              subtitle: 'Seconds before warning alert',
              value: _warningDelay,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _warningDelay = v),
              icon: Icons.timer,
            ),
            const Divider(height: 1),
            _buildNumberTile(
              title: 'Critical Delay',
              subtitle: 'Seconds before critical alert',
              value: _criticalDelay,
              min: 2,
              max: 15,
              onChanged: (v) => setState(() => _criticalDelay = v),
              icon: Icons.warning_amber,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Emergency Settings
          _buildSectionHeader('Emergency'),
          _buildCard([
            _buildSwitchTile(
              title: 'Emergency Contact',
              subtitle: 'Send SMS on critical alerts',
              value: _emergencyEnabled,
              onChanged: (v) => setState(() => _emergencyEnabled = v),
              icon: Icons.emergency,
            ),
            if (_emergencyEnabled) ...[
              const Divider(height: 1),
              _buildTextFieldTile(
                title: 'Phone Number',
                value: _emergencyContact,
                onChanged: (v) => setState(() => _emergencyContact = v),
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
            ],
          ]),
          
          const SizedBox(height: 24),
          
          // Appearance
          _buildSectionHeader('Appearance'),
          _buildCard([
            _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Optimized for night driving',
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
              icon: Icons.dark_mode,
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // About
          _buildSectionHeader('About'),
          _buildCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: AppTheme.primaryColor),
              ),
              title: const Text(
                'Version',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Text(
                '1.0.0',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: AppTheme.primaryColor),
              ),
              title: const Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                // Open privacy policy
              },
            ),
          ]),
          
          const SizedBox(height: 32),
          
          // Save button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            inactiveColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTile({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text(
            '${value}s',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
            onPressed: value < max ? () => onChanged(value + 1) : null,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: TextField(
        decoration: const InputDecoration(
          hintText: 'Enter phone number',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        onChanged: onChanged,
        controller: TextEditingController(text: value),
      ),
    );
  }

  String _getSensitivityLabel(double value) {
    if (value < 0.3) return 'Low - Fewer alerts, may miss drowsiness';
    if (value < 0.7) return 'Medium - Balanced detection';
    return 'High - More alerts, better safety';
  }

  void _saveSettings() {
    // Save settings to repository
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: AppTheme.safeColor,
      ),
    );
    Navigator.pop(context);
  }
}
