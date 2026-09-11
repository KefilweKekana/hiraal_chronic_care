import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/age_dob.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../services/service_locator.dart';
import '../../widgets/age_input_field.dart';
import '../../widgets/coverage_outcome.dart';
import '../../widgets/relationship_choices.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();
  String _relationship = 'Parent';
  String? _sex;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().length < 2 || _phone.text.length < 8) {
      setState(() => _error = l10n.whatsappRequired);
      return;
    }
    if (_age.text.trim().isNotEmpty && AgeDob.parseAge(_age.text) == null) {
      setState(() => _error = l10n.ageInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.caregivers.addFamilyMember(
      fullName: _name.text.trim(),
      relationship: _relationship,
      phone: _phone.text.trim(),
      countryCode: '+252',
      sex: _sex,
      dob: AgeDob.isoFromInput(_age.text),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        Navigator.pop(context, true);
      case Failure(message: final msg):
        setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.addFamilyMember)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.addFamilyMemberHint, style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.familyMemberName),
          ),
          const SizedBox(height: 16),
          Text(l10n.relationship, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          Text(l10n.genderLabel, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BigChoiceButton(
                  label: l10n.maleLabel,
                  selected: _sex == 'Male',
                  onTap: () => setState(() => _sex = 'Male'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BigChoiceButton(
                  label: l10n.femaleLabel,
                  selected: _sex == 'Female',
                  onTap: () => setState(() => _sex = 'Female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AgeInputField(
            controller: _age,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(
              labelText: l10n.mobileNumber,
              prefixText: '+252  ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.emailAddress),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.addFamilyMember),
            ),
          ),
        ],
      ),
    );
  }
}
