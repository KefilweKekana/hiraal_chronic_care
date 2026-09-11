import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/coverage_gate.dart';

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final _reasonController = TextEditingController();
  final Set<String> _selectedTests = {};
  String _collectionType = 'clinic';
  bool _isScheduled = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  // Real lab test templates from ERPNext
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  bool _isLoadingTemplates = true;
  String? _templateError;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final result = await ServiceLocator.instance.bookings.getLabTestTemplates();
    if (!mounted) return;
    switch (result) {
      case Success(data: final list):
        setState(() {
          _templates = list;
          _filteredTemplates = list;
          _isLoadingTemplates = false;
        });
      case Failure(message: final msg):
        setState(() { _templateError = msg; _isLoadingTemplates = false; });
    }
  }

  void _filterTemplates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTemplates = _templates;
      } else {
        _filteredTemplates = _templates.where((t) {
          final name = (t['lab_test_name'] ?? t['name'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _requestLabTest() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAtLeastOneTest), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() { _isLoading = true; });
    final provider = context.read<AppProvider>();
    final patient = actingPatientId(
      carePatient: provider.activeCarePerson?.patient,
      selfPatient: provider.patient?.id,
    );
    final serviceType = _collectionType == 'home' ? 'home_sample' : 'lab_test';
    final coverageResult = await ServiceLocator.instance.bookings.checkServiceCoverage(
      serviceType: serviceType,
      patient: patient,
      template: _selectedTests.first,
    );
    if (!mounted) return;
    switch (coverageResult) {
      case Success(data: final coverage):
        setState(() { _isLoading = false; });
        final proceed = await presentServiceCoverage(
          context: context,
          coverage: coverage,
          title: l10n.labTest,
          patient: patient,
          serviceType: serviceType,
        );
        if (proceed != true || !mounted) return;
        setState(() { _isLoading = true; });
      case Failure(message: final msg):
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        return;
    }
    final result = await ServiceLocator.instance.bookings.requestLabTest(
      tests: _selectedTests.toList(),
      preferredDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      location: _collectionType == 'home' ? l10n.homeSampleCollection : l10n.visitClinic,
    );
    if (!mounted) return;
    setState(() { _isLoading = false; });
    switch (result) {
      case Success():
        setState(() { _isScheduled = true; });
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isScheduled) return _buildScheduledView(context, l10n);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(l10n.requestLabTest),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.labTestInfoTitle),
                  content: Text(l10n.labTestInfoBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gotIt)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectTest, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: _filterTemplates,
              decoration: InputDecoration(
                hintText: l10n.searchLabTestsHint,
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingTemplates)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_templateError != null)
              Text(_templateError!, style: TextStyle(color: AppColors.error))
            else
              ..._filteredTemplates.take(12).map((t) {
                final templateName = t['name'] as String? ?? '';
                final displayName = t['lab_test_name'] as String? ?? templateName;
                final group = t['lab_test_group'] as String? ?? '';
                final isSelected = _selectedTests.contains(templateName);
                final colors = [
                  (AppColors.info, AppColors.of(context).infoSoft),
                  (AppColors.success, AppColors.of(context).successSoft),
                  (AppColors.chartPurple, const Color(0xFFF0EAFD)),
                  (AppColors.warning, AppColors.of(context).warningSoft),
                ];
                final pair = colors[_filteredTemplates.indexOf(t) % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isSelected ? pair.$2 : AppColors.of(context).card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTests.remove(templateName);
                          } else {
                            _selectedTests.add(templateName);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? pair.$1 : AppColors.of(context).border, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: pair.$2, shape: BoxShape.circle),
                              child: Icon(Icons.science, color: pair.$1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  if (group.isNotEmpty)
                                    Text(group, style: TextStyle(fontSize: 13, color: AppColors.of(context).textMuted)),
                                ],
                              ),
                            ),
                            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? pair.$1 : AppColors.of(context).textFaint),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            Text(l10n.selectADate, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = DateTime.now().add(Duration(days: i));
                  final selected = _selectedDate != null &&
                      _selectedDate!.year == day.year &&
                      _selectedDate!.month == day.month &&
                      _selectedDate!.day == day.day;
                  return InkWell(
                    onTap: () => setState(() => _selectedDate = day),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.of(context).successSoft : AppColors.of(context).card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.success : AppColors.of(context).border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            i == 0 ? l10n.todayLabel : DateFormat('E').format(day),
                            style: TextStyle(fontSize: 13, color: selected ? AppColors.success : AppColors.of(context).textMuted),
                          ),
                          Text(
                            '${day.day}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: selected ? AppColors.success : AppColors.of(context).text),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.whereWantTest, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CollectionCard(
                    icon: Icons.local_hospital,
                    label: l10n.visitClinic,
                    subtitle: l10n.visitClinicSubtitle,
                    isSelected: _collectionType == 'clinic',
                    onTap: () => setState(() => _collectionType = 'clinic'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CollectionCard(
                    icon: Icons.home,
                    label: l10n.homeSampleCollection,
                    subtitle: l10n.homeSampleSubtitle,
                    isSelected: _collectionType == 'home',
                    onTap: () => setState(() => _collectionType = 'home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l10n.fastingMayBeRequired, style: TextStyle(fontSize: 12, color: AppColors.warning)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.reasonOptional, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(hintText: l10n.labTestReasonHint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestLabTest,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(l10n.requestLabTest), const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.of(context).textFaint),
                const SizedBox(width: 4),
                Text(l10n.requestSecurePrivate, style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledView(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.labTestShortTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: Icon(Icons.check, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(l10n.testScheduled, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.testScheduledBody, textAlign: TextAlign.center, style: TextStyle(color: AppColors.of(context).textMuted)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.of(context).border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appointmentDetails, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _detailRow(Icons.science, l10n.testType, _selectedTests.map((name) {
                    final t = _templates.firstWhere((t) => t['name'] == name, orElse: () => {});
                    return t['lab_test_name'] as String? ?? name;
                  }).join(', ')),
                  _detailRow(Icons.calendar_today, l10n.date, _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : l10n.nextAvailable),
                  _detailRow(Icons.access_time, l10n.timeLabel, '08:00 AM'),
                  _detailRow(Icons.location_on, l10n.service, _collectionType == 'home' ? l10n.homeSampleCollection : l10n.visitClinic),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.viewAllBookings)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CollectionCard({required this.icon, required this.label, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.of(context).primarySoft : AppColors.of(context).card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.of(context).border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppColors.primary : AppColors.of(context).textFaint),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.of(context).text)),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : AppColors.of(context).textFaint)),
          ],
        ),
      ),
    );
  }
}
