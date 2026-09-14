import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/age_dob.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/health_pin_controller.dart';
import '../../services/service_locator.dart';
import '../../widgets/health_pin_gate.dart';
import 'medical_records_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;
  String _gender = 'Male';
  bool _saving = false;
  int _labCount = 0;

  @override
  void initState() {
    super.initState();
    final patient = context.read<AppProvider>().patient;
    _nameCtrl = TextEditingController(text: patient?.name ?? '');
    _phoneCtrl = TextEditingController(text: patient?.phone ?? '');
    _ageCtrl = TextEditingController(
      text: patient?.ageYears != null ? '${patient!.ageYears}' : '',
    );
    final sex = (patient?.sex ?? '').trim();
    if (sex == 'Female' || sex == 'Male' || sex == 'Other') {
      _gender = sex;
    }
    _loadLabCount();
  }

  Future<void> _loadLabCount() async {
    final result = await ServiceLocator.instance.bookings.getMyLabTests();
    if (!mounted) return;
    if (result case Success(data: final labs)) {
      setState(() => _labCount = labs.length);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fullNameHint)),
      );
      return;
    }
    final age = AgeDob.parseAge(_ageCtrl.text);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidAge)),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await ServiceLocator.instance.bookings.updateMyProfile(
      fullName: name,
      sex: _gender,
      age: age,
      mobile: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        final provider = context.read<AppProvider>();
        final current = provider.patient;
        if (current != null) {
          await provider.applyLocalPatient(
            current.copyWith(
              name: name,
              phone: _phoneCtrl.text.trim(),
              sex: _gender,
              dob: AgeDob.isoFromAge(age),
            ),
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.changesSaved)),
        );
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openMedicalRecords() async {
    final id = healthPinPatientId(context);
    await pushAfterHealthPin(context, const MedicalRecordsScreen());
    if (!mounted) return;
    context.read<HealthPinController>().lockPatient(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final patient = context.watch<AppProvider>().patient;
    final palette = AppColors.of(context);
    final unread = context.watch<AppProvider>().unreadNotificationCount;
    final memberId = (patient != null && patient.patientId.isNotEmpty)
        ? patient.patientId
        : '–';

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Text(l10n.personalInformation),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: unread > 0
                ? Badge.count(
                    count: unread,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.white,
                    child: Icon(Icons.notifications_outlined, color: palette.text),
                  )
                : Icon(Icons.notifications_outlined, color: palette.text),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: palette.primarySoft,
              child: Text(
                patient?.initials ?? '?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.memberIdLabel,
                  style: TextStyle(fontSize: 13, color: palette.textFaint),
                ),
                const SizedBox(height: 4),
                Text(
                  memberId,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.memberIdUnchangeable,
                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(label: l10n.fullName, controller: _nameCtrl),
          _LabeledField(
            label: l10n.phoneLabel,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          _LabeledField(
            label: l10n.age,
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
          ),
          Text(l10n.genderLabel, style: TextStyle(fontSize: 13, color: palette.textFaint)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _gender,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'Male', child: Text(l10n.maleLabel)),
              DropdownMenuItem(value: 'Female', child: Text(l10n.femaleLabel)),
              DropdownMenuItem(value: 'Other', child: Text(l10n.otherLabel)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _gender = v);
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(l10n.saveChanges),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.medicalRecordsTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openMedicalRecords,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF7E57C2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labResultsAndNurseNotes,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.medicalRecordsCardSubtitle(_labCount),
                            style: TextStyle(fontSize: 13, color: palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline, color: palette.textFaint, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: palette.textFaint)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
