import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _readingReminders = true;
  bool _appointmentAlerts = true;
  String _language = 'English';
  String _sugarUnit = 'mg/dL';
  String _bpUnit = 'mmHg';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('pref_push_notifications') ?? true;
      _readingReminders = prefs.getBool('pref_reading_reminders') ?? true;
      _appointmentAlerts = prefs.getBool('pref_appointment_alerts') ?? true;
      _language = prefs.getString('pref_language') ?? 'English';
      _sugarUnit = prefs.getString('pref_sugar_unit') ?? 'mg/dL';
      _bpUnit = prefs.getString('pref_bp_unit') ?? 'mmHg';
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _showPicker(String title, List<String> options, String current, String prefKey) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...options.map((opt) => ListTile(
              title: Text(opt),
              trailing: opt == current ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  switch (prefKey) {
                    case 'pref_language': _language = opt;
                    case 'pref_sugar_unit': _sugarUnit = opt;
                    case 'pref_bp_unit': _bpUnit = opt;
                  }
                });
                _setString(prefKey, opt);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _ToggleTile(
            title: 'Push Notifications',
            subtitle: 'Receive reminders and alerts',
            value: _pushNotifications,
            onChanged: (v) { setState(() => _pushNotifications = v); _setBool('pref_push_notifications', v); },
          ),
          _ToggleTile(
            title: 'Reading Reminders',
            subtitle: 'Daily reminder to submit vitals',
            value: _readingReminders,
            onChanged: (v) { setState(() => _readingReminders = v); _setBool('pref_reading_reminders', v); },
          ),
          _ToggleTile(
            title: 'Appointment Alerts',
            subtitle: 'Notify before appointments',
            value: _appointmentAlerts,
            onChanged: (v) { setState(() => _appointmentAlerts = v); _setBool('pref_appointment_alerts', v); },
          ),
          const SizedBox(height: 16),
          const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _SelectTile(title: 'Language', value: _language, onTap: () => _showPicker('Language', ['English', 'Somali', 'Arabic'], _language, 'pref_language')),
          _SelectTile(title: 'Blood Sugar Unit', value: _sugarUnit, onTap: () => _showPicker('Blood Sugar Unit', ['mg/dL', 'mmol/L'], _sugarUnit, 'pref_sugar_unit')),
          _SelectTile(title: 'Blood Pressure Unit', value: _bpUnit, onTap: () => _showPicker('Blood Pressure Unit', ['mmHg', 'kPa'], _bpUnit, 'pref_bp_unit')),
          const SizedBox(height: 16),
          const Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _InfoRow(title: 'App Version', value: '1.0.0'),
          _InfoRow(title: 'Build', value: 'Debug'),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  const _SelectTile({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
