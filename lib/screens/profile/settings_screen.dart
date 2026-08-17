import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/local_reminder_service.dart';
import 'language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _medsEnabled = false;
  TimeOfDay _medsTime = LocalReminderService.defaultMedsTime;
  bool _readingEnabled = false;
  TimeOfDay _readingTime = LocalReminderService.defaultReadingTime;

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _medsEnabled = prefs.getBool(LocalReminderService.medsEnabledKey) ?? false;
      _medsTime = LocalReminderService.tryParseTime(
              prefs.getString(LocalReminderService.medsTimeKey)) ??
          LocalReminderService.defaultMedsTime;
      _readingEnabled =
          prefs.getBool(LocalReminderService.readingEnabledKey) ?? false;
      _readingTime = LocalReminderService.tryParseTime(
              prefs.getString(LocalReminderService.readingTimeKey)) ??
          LocalReminderService.defaultReadingTime;
    });
  }

  Future<void> _setMedsEnabled(bool value) async {
    setState(() => _medsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LocalReminderService.medsEnabledKey, value);
    unawaited(LocalReminderService.instance.syncFromPrefs());
  }

  Future<void> _setReadingEnabled(bool value) async {
    setState(() => _readingEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LocalReminderService.readingEnabledKey, value);
    unawaited(LocalReminderService.instance.syncFromPrefs());
  }

  Future<void> _pickMedsTime() async {
    final picked = await showTimePicker(context: context, initialTime: _medsTime);
    if (picked == null) return;
    setState(() => _medsTime = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        LocalReminderService.medsTimeKey, LocalReminderService.formatTime(picked));
    unawaited(LocalReminderService.instance.syncFromPrefs());
  }

  Future<void> _pickReadingTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _readingTime);
    if (picked == null) return;
    setState(() => _readingTime = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalReminderService.readingTimeKey,
        LocalReminderService.formatTime(picked));
    unawaited(LocalReminderService.instance.syncFromPrefs());
  }

  String _languageLabel(AppLocalizations l10n, String code) {
    return code == 'so' ? l10n.languageSomali : l10n.languageEnglish;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const sectionStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary);
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.language, style: sectionStyle),
          const SizedBox(height: 8),
          _NavRow(
            title: l10n.language,
            subtitle: _languageLabel(l10n, provider.locale.languageCode),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.reminders, style: sectionStyle),
          const SizedBox(height: 8),
          _SwitchTile(
            title: l10n.medicationReminder,
            subtitle: l10n.dailyAtTime(_medsTime.format(context)),
            value: _medsEnabled,
            onChanged: _setMedsEnabled,
            onTap: _medsEnabled ? _pickMedsTime : null,
          ),
          _SwitchTile(
            title: l10n.readingReminder,
            subtitle: l10n.dailyAtTime(_readingTime.format(context)),
            value: _readingEnabled,
            onChanged: _setReadingEnabled,
            onTap: _readingEnabled ? _pickReadingTime : null,
          ),
          const SizedBox(height: 16),
          Text(l10n.accessibility, style: sectionStyle),
          const SizedBox(height: 8),
          _SwitchTile(
            title: l10n.largeText,
            subtitle: l10n.largeTextSubtitle,
            value: provider.largeText,
            onChanged: provider.setLargeText,
          ),
          const SizedBox(height: 16),
          Text(l10n.about, style: sectionStyle),
          const SizedBox(height: 8),
          _InfoRow(title: l10n.appVersion, value: '1.0.0'),
          _InfoRow(title: l10n.build, value: l10n.buildDebug),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
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
