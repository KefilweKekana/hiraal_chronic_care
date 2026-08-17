import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../services/biometric_service.dart';
import '../../services/service_locator.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometric = false;
  bool _twoFactor = true;
  bool _dataSharing = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _biometric = prefs.getBool('pref_biometric') ?? false;
      _twoFactor = prefs.getBool('pref_two_factor') ?? true;
      _dataSharing = prefs.getBool('pref_data_sharing') ?? true;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Fetch the patient's full data from the server, write it to a readable
  /// text file, and open the system share sheet so they can save or send it.
  Future<void> _exportMyData() async {
    final api = ServiceLocator.instance.apiClient;
    if (api == null) {
      _toast('Data export is only available when signed in online.');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await api.exportMyData();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner

    switch (result) {
      case Success(data: final data):
        try {
          final report = _formatExport(data);
          final dir = await getTemporaryDirectory();
          final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
          final file = File('${dir.path}/hiraal_my_data_$stamp.txt');
          await file.writeAsString(report);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'text/plain')],
            subject: 'My Hiraal Lifecare health data',
            text: 'A copy of my health data exported from Hiraal Lifecare.',
          );
        } catch (e) {
          if (mounted) _toast('Could not prepare your data file. Please try again.');
        }
      case Failure(message: final msg):
        _toast(msg);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  /// Build a human-readable health report from the server export payload.
  String _formatExport(Map<String, dynamic> d) {
    final b = StringBuffer();
    String s(dynamic v) => (v == null || '$v'.isEmpty) ? '—' : '$v';

    b.writeln('HIRAAL LIFECARE — MY HEALTH DATA');
    b.writeln('Generated: ${s(d['generated_at'])}');
    b.writeln('=' * 44);

    final p = (d['patient'] as Map?) ?? {};
    b.writeln('\nPATIENT');
    b.writeln('Name          : ${s(p['patient_name'])}');
    b.writeln('Mobile        : ${s(p['mobile'])}');
    b.writeln('Email         : ${s(p['email'])}');
    b.writeln('Gender        : ${s(p['sex'])}');
    b.writeln('Date of birth : ${s(p['dob'])}');
    b.writeln('Blood group   : ${s(p['blood_group'])}');
    b.writeln('Status        : ${s(p['status'])}');

    final sub = (d['subscription'] as Map?);
    b.writeln('\nSUBSCRIPTION');
    if (sub == null) {
      b.writeln('No subscription on record.');
    } else {
      b.writeln('Plan          : ${s(sub['plan'])}');
      b.writeln('Status        : ${s(sub['status'])}');
      b.writeln('Monthly fee   : \$${s(sub['monthly_fee'])}');
      b.writeln('Started       : ${s(sub['start_date'])}');
      b.writeln('Next billing  : ${s(sub['next_billing_date'])}');
    }

    final readings = (d['readings'] as List?) ?? [];
    b.writeln('\nREADINGS (${readings.length})');
    for (final r in readings) {
      final m = r as Map;
      final bp = (m['bp_systolic'] != null)
          ? '${m['bp_systolic']}/${m['bp_diastolic']} mmHg'
          : '';
      final sugar = (m['blood_sugar'] != null)
          ? 'sugar ${m['blood_sugar']} ${s(m['blood_sugar_unit'])}'
          : '';
      final wt = (m['weight'] != null) ? 'wt ${m['weight']}kg' : '';
      final parts = [bp, sugar, wt].where((x) => x.isNotEmpty).join(', ');
      b.writeln('${s(m['reading_date'])} ${s(m['reading_time'])}  '
          '$parts  [${s(m['risk_level'])}, ${s(m['source'])}]');
    }

    final orders = (d['medicine_orders'] as List?) ?? [];
    b.writeln('\nMEDICINE ORDERS (${orders.length})');
    for (final o in orders) {
      final m = o as Map;
      b.writeln('${s(m['name'])}  ${s(m['status'])}  '
          'pay=${s(m['payment_status'])}  total=\$${s(m['total'])}');
    }

    final pays = (d['subscription_payments'] as List?) ?? [];
    b.writeln('\nSUBSCRIPTION PAYMENTS (${pays.length})');
    for (final pay in pays) {
      final m = pay as Map;
      b.writeln('${s(m['payment_date'])}  \$${s(m['amount'])}  '
          '${s(m['payment_method'])}  ${s(m['status'])}');
    }

    b.writeln('\n${'=' * 44}');
    b.writeln('This file contains your personal health information. '
        'Keep it somewhere safe.');
    return b.toString();
  }

  /// Enabling biometric login requires a supported device with enrolled
  /// biometrics, confirmed by a successful prompt — otherwise the user could
  /// lock themselves into a setup that never authenticates.
  Future<void> _onBiometricToggle(bool value) async {
    if (!value) {
      setState(() => _biometric = false);
      await _setBool('pref_biometric', false);
      return;
    }

    final bio = BiometricService.instance;
    final supported = await bio.isDeviceSupported;
    final canCheck = await bio.canCheckBiometrics;
    if (!supported || !canCheck) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fingerprint or face unlock is set up on this device.'),
        ),
      );
      return;
    }

    final ok = await bio.authenticate();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric setup cancelled.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _biometric = true);
    await _setBool('pref_biometric', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric login enabled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToggleTile(
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID to log in',
            value: _biometric,
            onChanged: _onBiometricToggle,
          ),
          _ToggleTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Extra security for your account',
            value: _twoFactor,
            onChanged: (v) { setState(() => _twoFactor = v); _setBool('pref_two_factor', v); },
          ),
          _ToggleTile(
            title: 'Data Sharing with Care Team',
            subtitle: 'Allow your nurse to view readings',
            value: _dataSharing,
            onChanged: (v) { setState(() => _dataSharing = v); _setBool('pref_data_sharing', v); },
          ),
          const SizedBox(height: 16),
          const Text('Data Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _ActionTile(
            title: 'Export My Data',
            subtitle: 'Download a copy of your health data',
            icon: Icons.download,
            onTap: _exportMyData,
          ),
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

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.primary;
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c, size: 20),
          ],
        ),
      ),
    );
  }
}
