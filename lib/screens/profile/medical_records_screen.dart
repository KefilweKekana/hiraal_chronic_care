import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/booking_service.dart';
import '../../services/service_locator.dart';
import 'lab_result_detail_screen.dart';

/// PIN-gated hub: lab results list + nurse notes.
class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  MedicalRecordsBundle? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.bookings.getMyMedicalRecords();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _data = data;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  String _shortDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('EEE, MMM d, yyyy', 'en').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final unread = context.watch<AppProvider>().unreadNotificationCount;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Text(l10n.medicalRecordsTitle),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _load, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: palette.successSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_open, size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.medicalRecordsUnlockedBanner,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.labResultsSection,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if ((_data?.labs ?? []).isEmpty)
                        _EmptyHint(text: l10n.noLabResultsYet)
                      else
                        ..._data!.labs.map(_labCard),
                      const SizedBox(height: 22),
                      Text(
                        l10n.nurseNotesSection,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if ((_data?.nurseNotes ?? []).isEmpty)
                        _EmptyHint(text: l10n.noNurseNotesYet)
                      else
                        ..._data!.nurseNotes.map(_noteCard),
                    ],
                  ),
                ),
    );
  }

  Widget _labCard(LabTestInfo lab) {
    final palette = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final date = lab.resultDate ?? lab.created;
    final watch = lab.watchCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LabResultDetailScreen(labTestId: lab.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF7E57C2), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lab.template.isNotEmpty ? lab.template : lab.id,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                      if (date != null || watch > 0) ...[
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              if (date != null)
                                TextSpan(
                                  text: _shortDate(date),
                                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                                ),
                              if (date != null && watch > 0)
                                TextSpan(
                                  text: ' · ',
                                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                                ),
                              if (watch > 0)
                                TextSpan(
                                  text: l10n.toWatchCount(watch),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC47A2C),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteCard(NurseNoteInfo note) {
    final palette = AppColors.of(context);
    final header = [
      if (note.completedAt != null) _shortDate(note.completedAt),
      if (note.nurseName.isNotEmpty) note.nurseName,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Text(
              header,
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          if (header.isNotEmpty) const SizedBox(height: 6),
          Text(
            note.note,
            style: TextStyle(fontSize: 14, height: 1.4, color: palette.text),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: AppColors.of(context).textMuted),
      ),
    );
  }
}
