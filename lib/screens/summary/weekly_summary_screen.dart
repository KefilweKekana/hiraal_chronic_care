import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';

class WeeklySummaryScreen extends StatelessWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final readings = provider.readings;
    final hasData = readings.isNotEmpty;
    final avgSys = provider.avgSystolic.round();
    final diaReadings = readings.where((r) => r.diastolic != null).toList();
    final avgDia = diaReadings.isEmpty ? 0 : (diaReadings.map((r) => r.diastolic!).reduce((a, b) => a + b) / diaReadings.length).round();
    final avgSugar = provider.avgSugar.toStringAsFixed(1);
    final bpCount = readings.where((r) => r.systolic != null).length;
    final sugarCount = readings.where((r) => r.bloodSugar != null).length;
    final medTaken = readings.where((r) => r.medicineTaken == true).length;
    final medTotal = readings.length;
    final medPct = medTotal > 0 ? (medTaken / medTotal * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(title: const Text('Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.of(context).primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.bar_chart, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasData ? 'Great job staying consistent!' : 'No data yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(hasData ? 'Based on your ${readings.length} readings.' : 'Log your first reading to see your summary.', style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Your Averages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _AverageCard(icon: Icons.favorite, label: 'Blood Pressure', value: hasData ? '$avgSys/$avgDia' : '--', unit: 'mmHg', status: !hasData ? 'No data' : (avgSys < 140 ? 'Good' : 'High'), statusColor: !hasData ? AppColors.of(context).textFaint : (avgSys < 140 ? AppColors.success : AppColors.warning))),
                const SizedBox(width: 8),
                Expanded(child: _AverageCard(icon: Icons.water_drop, label: 'Blood Sugar', value: hasData ? avgSugar : '--', unit: 'mg/dL', status: !hasData ? 'No data' : (provider.avgSugar < 180 ? 'Good' : 'High'), statusColor: !hasData ? AppColors.of(context).textFaint : (provider.avgSugar < 180 ? AppColors.success : AppColors.warning))),
                const SizedBox(width: 8),
                Expanded(child: _AverageCard(icon: Icons.medication, label: 'Medications', value: hasData ? '$medTaken/$medTotal' : '--', unit: 'Taken', status: !hasData ? 'No data' : (medTaken == medTotal ? 'Great' : 'Partial'), statusColor: !hasData ? AppColors.of(context).textFaint : (medTaken == medTotal ? AppColors.success : AppColors.warning))),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('This Week at a Glance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            _WeekItem(icon: Icons.favorite, color: AppColors.error, title: 'Blood Pressure', subtitle: '$bpCount readings', status: !hasData ? 'No data' : (avgSys < 140 ? 'Stable' : 'Elevated'), statusDetail: !hasData ? 'Log a reading' : (avgSys < 140 ? 'No concerns' : 'Monitor closely'), statusColor: !hasData ? AppColors.of(context).textFaint : (avgSys < 140 ? AppColors.success : AppColors.warning)),
            _WeekItem(icon: Icons.water_drop, color: AppColors.primary, title: 'Blood Sugar', subtitle: '$sugarCount readings', status: !hasData ? 'No data' : (provider.avgSugar < 180 ? 'Stable' : 'Elevated'), statusDetail: !hasData ? 'Log a reading' : (provider.avgSugar < 180 ? 'Keep it up' : 'Consult team'), statusColor: !hasData ? AppColors.of(context).textFaint : (provider.avgSugar < 180 ? AppColors.success : AppColors.warning)),
            _WeekItem(icon: Icons.medication, color: AppColors.success, title: 'Medications', subtitle: '$medTaken taken', status: hasData ? '$medPct%' : 'No data', statusDetail: !hasData ? 'Log a reading' : (medTaken == medTotal ? 'Excellent' : 'Missed some'), statusColor: !hasData ? AppColors.of(context).textFaint : (medTaken == medTotal ? AppColors.success : AppColors.warning)),
            const SizedBox(height: 16),
            if (hasData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("You're doing well!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                          Text('Keep taking your medication and\ntracking your readings.', style: TextStyle(fontSize: 12, color: AppColors.success)),
                        ],
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: AppColors.success, size: 28),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.of(context).inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.of(context).textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('No readings yet. Log your blood pressure,\nblood sugar, and medications to see your summary.', style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.history, size: 18),
                label: const Text('View Full History'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;

  const _AverageCard({required this.icon, required this.label, required this.value, required this.unit, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.of(context).textFaint), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(unit, style: TextStyle(fontSize: 10, color: AppColors.of(context).textFaint)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _WeekItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;
  final String statusDetail;
  final Color statusColor;

  const _WeekItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.status, required this.statusDetail, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
              Text(statusDetail, style: TextStyle(fontSize: 11, color: AppColors.of(context).textFaint)),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: AppColors.of(context).textFaint, size: 18),
        ],
      ),
    );
  }
}
