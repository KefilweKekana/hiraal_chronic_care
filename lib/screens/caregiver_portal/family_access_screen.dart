import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/active_patient_card.dart';
import '../../widgets/coverage_outcome.dart';
import '../../widgets/relationship_choices.dart';
import '../caregivers/caregivers_screen.dart';

class FamilyAccessScreen extends StatefulWidget {
  const FamilyAccessScreen({super.key});

  @override
  State<FamilyAccessScreen> createState() => _FamilyAccessScreenState();
}

class _FamilyAccessScreenState extends State<FamilyAccessScreen> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  String _relationship = 'Sibling';
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _grant() async {
    final patient = context.read<AppProvider>().activeCarePerson?.patient;
    if (patient == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await ServiceLocator.instance.caregivers.grantFamilyAccess(
      patient: patient,
      countryCode: '+252',
      whatsappNumber: _phone.text.trim(),
      relationship: _relationship,
      familyMemberName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      permissions: const {
        'view_readings': true,
        'view_medicines': true,
        'view_appointments': true,
        'view_subscription': false,
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final inv):
        setState(() => _message = inv.message.isNotEmpty ? inv.message : inv.invitationCode);
      case Failure(message: final msg):
        setState(() => _message = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.familyAccess)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.familyAccessHint, style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
          const SizedBox(height: 16),
          const ActivePatientCard(),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.familyMemberName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.whatsappNumber, prefixText: '+252  '),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final r in RelationshipChoices.familyMemberKeys)
                BigChoiceButton(
                  label: RelationshipChoices.label(l10n, r),
                  selected: _relationship == r,
                  onTap: () => setState(() => _relationship = r),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _grant,
              child: Text(l10n.addCaregiver),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(fontSize: 15)),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaregiversScreen()),
            ),
            child: Text(l10n.caregiversTitle),
          ),
        ],
      ),
    );
  }
}
