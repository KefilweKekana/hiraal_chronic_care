import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/network/sync_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = true;
  bool _upToDate = false;
  double _progress = 0.0;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final pending = provider.readings.where((r) => r.syncStatus == 'Pending').toList();
    _items = pending.map((r) {
      return {
        'key': r.referenceId ?? r.date.toIso8601String(),
        'type': r.systolic != null ? 'Blood Pressure' : 'Blood Sugar',
        'detail': '${DateFormat('MMM dd, h:mm a').format(r.date)} • ${r.systolic != null ? '${r.systolic}/${r.diastolic} mmHg' : '${r.bloodSugar} mg/dL'}',
        'icon': r.systolic != null ? Icons.favorite : Icons.water_drop,
        'sent': false,
      };
    }).toList();
    if (_items.isEmpty) {
      // Nothing is waiting to sync — show the up-to-date state instead of
      // pretending to send already-synced readings.
      _isSyncing = false;
      _upToDate = true;
    } else {
      _sync();
    }
  }

  Future<void> _sync() async {
    int synced = 0;
    try {
      synced = await SyncManager().syncAll();
    } catch (_) {
      synced = 0;
    }
    if (!mounted) return;
    // Reload readings so the list and the pending badge reflect the outcome.
    await context.read<AppProvider>().refreshReadings();
    if (!mounted) return;
    final stillPending = context
        .read<AppProvider>()
        .readings
        .where((r) => r.syncStatus == 'Pending')
        .map((r) => r.referenceId ?? r.date.toIso8601String())
        .toSet();
    setState(() {
      for (final item in _items) {
        item['sent'] = synced >= _items.length || !stillPending.contains(item['key']);
      }
      _progress = 1.0;
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSyncing) {
      return _upToDate ? _buildUpToDateView(context) : _buildCompleteView(context);
    }

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

  Widget _buildUpToDateView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Sync'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_done, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text("You're Up to Date", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('No saved readings are waiting to sync.\nEverything is already on your health record.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
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

  Widget _buildCompleteView(BuildContext context) {
    final sentCount = _items.where((i) => i['sent'] == true).length;
    final allSent = sentCount == _items.length;
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
              decoration: BoxDecoration(color: allSent ? AppColors.success : AppColors.warning, shape: BoxShape.circle),
              child: Icon(allSent ? Icons.check : Icons.cloud_off, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(allSent ? "You're All Set!" : 'Sync Incomplete', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              allSent
                  ? 'All your saved data has been sent\nto your health record.'
                  : '${_items.length - sentCount} reading(s) could not be sent.\nThey are saved on this phone and will\nsync automatically later.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: allSent ? AppColors.infoLight : AppColors.warningLight, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(allSent ? Icons.info_outline : Icons.error_outline, size: 16, color: allSent ? AppColors.info : AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allSent
                          ? 'Your care team can now view your latest\nreadings and notes.'
                          : 'Your data is safe. Unsent readings stay on\nthis phone and will retry automatically.',
                      style: TextStyle(fontSize: 12, color: allSent ? AppColors.info : AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(allSent ? 'What Was Synced' : 'Sync Results', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('$sentCount of ${_items.length} Items', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                    Icon(sent ? Icons.check_circle : Icons.error, color: sent ? AppColors.success : AppColors.error, size: 18),
                    const SizedBox(width: 4),
                    Text(sent ? 'Sent' : 'Not sent', style: TextStyle(fontSize: 11, color: sent ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: allSent ? AppColors.successLight : AppColors.warningLight, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(allSent ? Icons.check_circle : Icons.sync_problem, size: 16, color: allSent ? AppColors.success : AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allSent
                          ? 'Your data is safe and up to date.\nThank you for staying on top of your health.'
                          : 'Some readings are still waiting to sync.\nThey will be sent automatically when you\'re back online.',
                      style: TextStyle(fontSize: 12, color: allSent ? AppColors.success : AppColors.warning),
                    ),
                  ),
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
