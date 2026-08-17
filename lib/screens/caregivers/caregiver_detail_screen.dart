import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../services/service_locator.dart';

class CaregiverDetailScreen extends StatefulWidget {
  final CaregiverLink link;

  const CaregiverDetailScreen({super.key, required this.link});

  @override
  State<CaregiverDetailScreen> createState() => _CaregiverDetailScreenState();
}

class _CaregiverDetailScreenState extends State<CaregiverDetailScreen> {
  late final Map<String, bool> _permissions = Map<String, bool>.from(widget.link.permissions);
  bool _saving = false;
  bool _revoking = false;
  bool _sendingInvite = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ServiceLocator.instance.caregivers.updateCaregiverPermissions(
      name: widget.link.name,
      permissions: _permissions,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(data: final message):
        _snack(message);
        Navigator.pop(context, true);
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  Future<void> _resendInvite() async {
    setState(() => _sendingInvite = true);
    final result = await ServiceLocator.instance.caregivers.getCaregiverWhatsappInvite(widget.link.name);
    if (!mounted) return;
    setState(() => _sendingInvite = false);
    switch (result) {
      case Success(data: final url):
        final uri = Uri.tryParse(url);
        if (uri == null) {
          _snack(AppLocalizations.of(context).couldNotOpenWhatsapp, error: true);
          return;
        }
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        if (!launched) {
          _snack(AppLocalizations.of(context).couldNotOpenWhatsapp, error: true);
        }
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeCaregiverTitle),
        content: Text(l10n.revokeCaregiverMessage(widget.link.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancelAction)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.revokeCaregiver)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _revoking = true);
    final result = await ServiceLocator.instance.caregivers.revokeCaregiver(widget.link.name);
    if (!mounted) return;
    setState(() => _revoking = false);
    switch (result) {
      case Success(data: final message):
        _snack(message);
        Navigator.pop(context, true);
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.link.displayName),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.link.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${widget.link.relationship} • ${widget.link.fullWhatsappNumber}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  if ((widget.link.familyMemberName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.familyMemberName}: ${widget.link.familyMemberName}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.permissionsTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _PermissionTile(
              title: l10n.viewReadings,
              value: _permissions['view_readings'] ?? false,
              onChanged: (value) => setState(() => _permissions['view_readings'] = value),
            ),
            _PermissionTile(
              title: l10n.viewMedicines,
              value: _permissions['view_medicines'] ?? false,
              onChanged: (value) => setState(() => _permissions['view_medicines'] = value),
            ),
            _PermissionTile(
              title: l10n.viewAppointments,
              value: _permissions['view_appointments'] ?? false,
              onChanged: (value) => setState(() => _permissions['view_appointments'] = value),
            ),
            _PermissionTile(
              title: l10n.viewSubscription,
              value: _permissions['view_subscription'] ?? false,
              onChanged: (value) => setState(() => _permissions['view_subscription'] = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sendingInvite ? null : _resendInvite,
                icon: const Icon(Icons.send_outlined),
                label: Text(l10n.sendInvitationAgain),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_saving || _revoking) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(l10n.savePermissions),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: (_saving || _revoking) ? null : _revoke,
                child: _revoking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : Text(
                        l10n.revokeCaregiver,
                        style: const TextStyle(color: AppColors.error),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        activeColor: AppColors.primary,
        title: Text(title),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
