import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../services/booking_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/skeleton.dart';
import 'lab_test_screen.dart';

/// The patient's lab tests (from get_my_lab_tests) — where the profile
/// "Lab Tests" activity card leads. Requesting a new one goes through
/// LabTestScreen.
class MyLabTestsScreen extends StatefulWidget {
  const MyLabTestsScreen({super.key});

  @override
  State<MyLabTestsScreen> createState() => _MyLabTestsScreenState();
}

class _MyLabTestsScreenState extends State<MyLabTestsScreen> {
  List<LabTestInfo> _tests = [];
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
    final result = await ServiceLocator.instance.bookings.getMyLabTests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final list):
          _tests = list;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  /// Chip label + color by Lab Test status. Draft/Approved/Sample Collected
  /// are all "scheduled" from the patient's point of view.
  (String, Color) _statusStyle(LabTestInfo t) {
    switch (t.status) {
      case 'Completed':
        return ('Completed', AppColors.success);
      case 'Cancelled':
      case 'Rejected':
        return (t.status, AppColors.error);
      case '':
        return ('Requested', AppColors.warning);
      default:
        return ('Scheduled', AppColors.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Lab Tests'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const SkeletonList(itemCount: 4)
          : _error != null
              ? _buildError()
              : _tests.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _tests.length,
                        itemBuilder: (context, i) => _testCard(_tests[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LabTestScreen()),
        ).then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text('Request Test'),
      ),
    );
  }

  Widget _testCard(LabTestInfo t) {
    final (label, color) = _statusStyle(t);
    return GestureDetector(
      onTap: () => _showDetails(t),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.template,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (t.created != null) 'Requested ${DateFormat('MMM d, yyyy').format(t.created!)}',
                    if (t.resultDate != null) 'Result ${DateFormat('MMM d, yyyy').format(t.resultDate!)}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// A lab test can be cancelled while the lab hasn't collected the sample
  /// (mirrors _LAB_TEST_CANCELLABLE server-side).
  bool _isCancellable(LabTestInfo t) =>
      !{'Completed', 'Cancelled', 'Rejected', 'Sample Collected'}.contains(t.status);

  Future<void> _showDetails(LabTestInfo t) async {
    final (label, color) = _statusStyle(t);
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(t.template,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (t.created != null)
                _detailRow('Requested', DateFormat('EEE, MMM d, yyyy').format(t.created!)),
              if (t.resultDate != null)
                _detailRow('Result', DateFormat('EEE, MMM d, yyyy').format(t.resultDate!)),
              _detailRow('Reference', t.id),
              if (_isCancellable(t)) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmCancel(t);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                    label: const Text('Cancel this test', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Future<void> _confirmCancel(LabTestInfo t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel lab test?'),
        content: Text('Cancel ${t.template}? The lab will stop processing it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel test', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ServiceLocator.instance.bookings.cancelMyLabTest(t.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.template} cancelled'), backgroundColor: AppColors.success),
        );
        _load();
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.science_outlined, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Center(
              child: Text('No lab tests yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            SizedBox(height: 4),
            Center(
              child: Text('Request a lab test and it will\nappear here with its status.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
            ),
          ],
        ),
      );
}
