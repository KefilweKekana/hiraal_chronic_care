import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../services/patient_record_service.dart';
import '../../services/service_locator.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<MedicalRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await ServiceLocator.instance.records.getRecords('');
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _records = data;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  IconData _iconFor(String type) => switch (type) {
    'enrollment' => Icons.flag,
    'diagnosis' => Icons.favorite,
    'procedure' => Icons.vaccines,
    _ => Icons.check_circle,
  };

  Color _colorFor(String type) => switch (type) {
    'enrollment' => AppColors.primary,
    'diagnosis' => AppColors.error,
    'procedure' => AppColors.chartPurple,
    _ => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical History'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ))
              : _records.isEmpty
                  ? const Center(child: Text('No medical records yet', style: TextStyle(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (context, i) {
                          final r = _records[i];
                          return _HistoryItem(
                            date: r.date,
                            title: r.title,
                            subtitle: r.subtitle,
                            icon: _iconFor(r.type),
                            color: _colorFor(r.type),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HistoryItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
