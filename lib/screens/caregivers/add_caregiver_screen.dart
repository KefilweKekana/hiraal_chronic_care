import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../services/service_locator.dart';

class AddCaregiverScreen extends StatefulWidget {
  const AddCaregiverScreen({super.key});

  @override
  State<AddCaregiverScreen> createState() => _AddCaregiverScreenState();
}

class _AddCaregiverScreenState extends State<AddCaregiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeCtrl = TextEditingController(text: '+252');
  final _numberCtrl = TextEditingController();
  final _familyMemberCtrl = TextEditingController();

  String _relationship = 'Mother';
  bool _busy = false;
  final Map<String, bool> _permissions = {
    'view_readings': true,
    'view_medicines': true,
    'view_appointments': true,
    'view_subscription': false,
  };

  @override
  void dispose() {
    _countryCodeCtrl.dispose();
    _numberCtrl.dispose();
    _familyMemberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final result = await ServiceLocator.instance.caregivers.inviteCaregiver(
      countryCode: _countryCodeCtrl.text.trim(),
      whatsappNumber: _numberCtrl.text.trim(),
      relationship: _relationship,
      familyMemberName: _familyMemberCtrl.text.trim().isEmpty ? null : _familyMemberCtrl.text.trim(),
      permissions: _permissions,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success(data: final invite):
        final uri = Uri.tryParse(invite.whatsappUrl);
        if (uri != null) {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          if (!launched) {
            _snack(l10n.couldNotOpenWhatsapp, error: true);
            return;
          }
          _snack(l10n.invitationReady);
          Navigator.pop(context, true);
        } else {
          _snack(l10n.couldNotOpenWhatsapp, error: true);
        }
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
    final relationships = <String>[
      l10n.relationshipMother,
      l10n.relationshipFather,
      l10n.relationshipBrother,
      l10n.relationshipSister,
      l10n.relationshipSpouse,
      l10n.relationshipChild,
      l10n.relationshipFriend,
      l10n.relationshipOther,
    ];
    if (!relationships.contains(_relationship)) {
      _relationship = relationships.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.addCaregiver),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addCaregiverIntro, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _countryCodeCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.countryCode,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? l10n.countryCodeRequired : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _numberCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappNumber,
                        hintText: '612345678',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => (value == null || value.trim().length < 7) ? l10n.whatsappRequired : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: InputDecoration(
                  labelText: l10n.relationship,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: relationships
                    .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _relationship = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _familyMemberCtrl,
                decoration: InputDecoration(
                  labelText: l10n.familyMemberName,
                  hintText: l10n.familyMemberHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.whatsappInviteNote,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(l10n.sendInvitationWhatsapp),
                ),
              ),
            ],
          ),
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
