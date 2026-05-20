import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../services/service_locator.dart';

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
    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one test'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() { _isLoading = true; });
    final result = await ServiceLocator.instance.bookings.requestLabTest(
      tests: _selectedTests.toList(),
      preferredDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      location: _collectionType == 'home' ? 'Home Sample Collection' : 'Visit Clinic',
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
    if (_isScheduled) return _buildScheduledView(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Request Lab Test'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Lab Test Info'),
                  content: const Text(
                    'Choose a test, describe your reason, and submit. The care team will review and confirm a time.\n\nResults appear in your History once available.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
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
            const Text('Why do you need a lab test?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'e.g. Doctor advised, feeling unwell, routine check',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _filterTemplates,
              decoration: const InputDecoration(
                hintText: 'Search lab tests...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingTemplates)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_templateError != null)
              Text(_templateError!, style: const TextStyle(color: AppColors.error))
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final t = _filteredTemplates[index];
                    final templateName = t['name'] as String? ?? '';
                    final displayName = t['lab_test_name'] as String? ?? templateName;
                    final group = t['lab_test_group'] as String? ?? '';
                    final isSelected = _selectedTests.contains(templateName);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: isSelected,
                      title: Text(displayName, style: const TextStyle(fontSize: 13)),
                      subtitle: group.isNotEmpty ? Text(group, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)) : null,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTests.add(templateName);
                          } else {
                            _selectedTests.remove(templateName);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedTests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTests.map((name) {
                    final t = _templates.firstWhere((t) => t['name'] == name, orElse: () => {});
                    final display = t['lab_test_name'] as String? ?? name;
                    return Chip(
                      label: Text(display, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setState(() => _selectedTests.remove(name)),
                      deleteIconColor: AppColors.textSecondary,
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Preferred date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                  color: AppColors.inputBackground,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(_selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Select date', style: TextStyle(color: _selectedDate != null ? AppColors.textPrimary : AppColors.textTertiary)),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Where do you want the test?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CollectionCard(
                    icon: Icons.local_hospital,
                    label: 'Visit Clinic',
                    subtitle: 'Go to a lab near you',
                    isSelected: _collectionType == 'clinic',
                    onTap: () => setState(() => _collectionType = 'clinic'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CollectionCard(
                    icon: Icons.home,
                    label: 'Home Sample Collection',
                    subtitle: "We'll come to you",
                    isSelected: _collectionType == 'home',
                    onTap: () => setState(() => _collectionType = 'home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                SizedBox(width: 4),
                Text("Fasting may be required for some tests. We'll let you know.", style: TextStyle(fontSize: 12, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestLabTest,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('Request Lab Test'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 4),
                Text('Your request is secure and private.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Lab Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Test Scheduled!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text("We've scheduled your request and scheduled your lab test.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appointment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _detailRow(Icons.science, 'Test Type', _selectedTests.map((name) {
                    final t = _templates.firstWhere((t) => t['name'] == name, orElse: () => {});
                    return t['lab_test_name'] as String? ?? name;
                  }).join(', ')),
                  _detailRow(Icons.calendar_today, 'Date', _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Next available'),
                  _detailRow(Icons.access_time, 'Time', '08:00 AM'),
                  _detailRow(Icons.location_on, 'Service', _collectionType == 'home' ? 'Home Sample Collection' : 'Visit Clinic'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('View All Bookings')),
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
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
          color: isSelected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
