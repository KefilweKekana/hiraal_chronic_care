import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = true;
  double _progress = 0.0;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final pending = provider.readings.where((r) => r.status == 'Pending').toList();
    if (pending.isNotEmpty) {
      _items = pending.map((r) {
        return {
          'type': r.systolic != null ? 'Blood Pressure' : 'Blood Sugar',
          'detail': '${DateFormat('MMM dd, h:mm a').format(r.date)} • ${r.systolic != null ? '${r.systolic}/${r.diastolic} mmHg' : '${r.bloodSugar} mg/dL'}',
          'icon': r.systolic != null ? Icons.favorite : Icons.water_drop,
          'sent': false,
        };
      }).toList();
    } else {
      _items = provider.readings.take(4).map((r) {
        return {
          'type': r.systolic != null ? 'Blood Pressure' : 'Blood Sugar',
          'detail': '${DateFormat('MMM dd, h:mm a').format(r.date)} • ${r.systolic != null ? '${r.systolic}/${r.diastolic} mmHg' : '${r.bloodSugar} mg/dL'}',
          'icon': r.systolic != null ? Icons.favorite : Icons.water_drop,
          'sent': false,
        };
      }).toList();
    }
    _simulateSync();
  }

  Future<void> _simulateSync() async {
    for (int i = 0; i < _items.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _items[i]['sent'] = true;
        _progress = (i + 1) / _items.length;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSyncing) return _buildCompleteView(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Sync in Progress'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.cloud_upload, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Sending Your Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text("We're syncing your saved readings to\nyour health record.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sync Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_items.where((i) => i['sent'] == true).length} of ${_items.length} Items', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: _progress, minHeight: 8, backgroundColor: AppColors.inputBackground, color: AppColors.primary),
            ),
            Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            const SizedBox(height: 20),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final sent = item['sent'] as bool;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['type'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(item['detail'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    if (sent) const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                    else const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    const SizedBox(width: 4),
                    Text(sent ? 'Sent' : 'Sending...', style: TextStyle(fontSize: 11, color: sent ? AppColors.success : AppColors.textTertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Your data is secure\nAll data is encrypted and protected\nduring syncing.', style: TextStyle(fontSize: 11, color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Sync Complete'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text("You're All Set!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('All your saved data has been sent\nto your health record.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('Your care team can now view your latest\nreadings and notes.', style: TextStyle(fontSize: 12, color: AppColors.info)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('What Was Synced', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_items.length} of ${_items.length} Items', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['type'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(item['detail'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 4),
                    const Text('Sent', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Your data is safe and up to date.\nThank you for staying on top of your health.', style: TextStyle(fontSize: 12, color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
              child: Row(
                children: const [
                  Icon(Icons.sync, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(child: Text("Next sync\nWe'll automatically sync new data\nwhen you go offline again.", style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  Text('Auto Sync\nON', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
