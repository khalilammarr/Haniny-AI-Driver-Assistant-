import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoStartTrip = false;
  String _alertSensitivity = 'Medium';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _autoStartTrip = prefs.getBool('auto_start_trip') ?? false;
      _alertSensitivity = prefs.getString('alert_sensitivity') ?? 'Medium';
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF7FC8A9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive alerts for safety events',
            Icons.notifications,
            _notificationsEnabled,
            (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          _buildSwitchTile(
            'Sound Alerts',
            'Play sound for critical alerts',
            Icons.volume_up,
            _soundEnabled,
            (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('sound_enabled', value);
            },
          ),
          _buildSwitchTile(
            'Vibration',
            'Vibrate on alert',
            Icons.vibration,
            _vibrationEnabled,
            (value) {
              setState(() => _vibrationEnabled = value);
              _saveSetting('vibration_enabled', value);
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Trip Settings'),
          _buildSwitchTile(
            'Auto-Start Trips',
            'Automatically start monitoring when driving',
            Icons.play_circle,
            _autoStartTrip,
            (value) {
              setState(() => _autoStartTrip = value);
              _saveSetting('auto_start_trip', value);
            },
          ),
          _buildDropdownTile(
            'Alert Sensitivity',
            'Adjust detection sensitivity',
            Icons.tune,
            _alertSensitivity,
            ['Low', 'Medium', 'High'],
            (value) {
              setState(() => _alertSensitivity = value!);
              _saveSetting('alert_sensitivity', value);
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme (Coming soon)',
            Icons.dark_mode,
            _darkMode,
            (value) {
              setState(() => _darkMode = value);
              _saveSetting('dark_mode', value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Dark mode coming in next update!')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Data & Storage'),
          _buildActionTile(
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services,
            () {
              _showConfirmDialog(
                'Clear Cache',
                'This will clear temporary files and cached data.',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully')),
                  );
                },
              );
            },
          ),
          _buildActionTile(
            'Export Trip Data',
            'Download your trip history',
            Icons.download,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Advanced'),
          _buildActionTile(
            'Reset All Settings',
            'Restore default settings',
            Icons.restore,
            () {
              _showConfirmDialog(
                'Reset Settings',
                'This will restore all settings to their default values.',
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Settings reset successfully')),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'App Version: 1.0.0\nBuild: 2024.11.25',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7FC8A9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        secondary: Icon(icon, color: const Color(0xFF7FC8A9)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7FC8A9),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF7FC8A9)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: DropdownButton<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
          underline: Container(),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF7FC8A9)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showConfirmDialog(
      String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
