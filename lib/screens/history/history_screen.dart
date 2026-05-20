import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../models/vital_reading.dart';
import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _filterDays; // null = all time
  bool _isChartView = false; // toggle for readings tab

  static const _filterOptions = <int?, String>{
    null: 'All time',
    7: 'Last 7 days',
    30: 'Last 30 days',
    90: 'Last 90 days',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allReadings = provider.readings;
    final readings = _filterDays == null
        ? allReadings
        : allReadings.where((r) {
            final cutoff = DateTime.now().subtract(Duration(days: _filterDays!));
            return r.date.isAfter(cutoff);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      PopupMenuButton<int?>(
                        tooltip: 'Filter readings',
                        initialValue: _filterDays,
                        onSelected: (v) => setState(() => _filterDays = v),
                        icon: const Icon(Icons.filter_list, color: AppColors.primary),
                        itemBuilder: (_) => _filterOptions.entries
                            .map((e) => PopupMenuItem<int?>(value: e.key, child: Text(e.value)))
                            .toList(),
                      ),
                      Text(
                        _filterOptions[_filterDays] ?? 'Filter',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: '📈 Readings'),
                  Tab(text: '📝 Notes'),
                  Tab(text: '⚠️ Alerts'),
                ],
                dividerColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 12),
            // Summary stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.calendar_today,
                        color: AppColors.primary,
                        value: '${provider.totalSubmissions}',
                        label: 'Submissions\nTotal',
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.favorite,
                        color: AppColors.error,
                        value: provider.avgSystolic.toStringAsFixed(0),
                        label: 'Avg. Systolic\nmonthly',
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.water_drop,
                        color: AppColors.warning,
                        value: provider.avgSugar.toStringAsFixed(0),
                        label: 'Avg. Sugar\nmg/dL',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Reading info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Text(
                      'Your past readings and care team feedback appear here.',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Readings list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReadingsTab(readings),
                  _buildNotesTab(readings),
                  _buildAlertsTab(readings),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Care team feedback will appear after they review your readings.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsTab(List<VitalReading> readings) {
    return Column(
      children: [
        // List / Chart toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('List View'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Chart View'),
                      icon: Icon(Icons.show_chart),
                    ),
                  ],
                  selected: <bool>{_isChartView},
                  onSelectionChanged: (value) {
                    setState(() => _isChartView = value.first);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isChartView
              ? _buildChartView(readings)
              : _buildReadingsList(readings),
        ),
      ],
    );
  }

  Widget _buildReadingsList(List<VitalReading> readings) {
    // Group by date
    final grouped = <String, List<VitalReading>>{};
    for (final r in readings) {
      final key = DateFormat('MMMM dd, yyyy').format(r.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(r);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayReadings = grouped[dateKey]!;
        final now = DateTime.now();
        final readingDate = dayReadings.first.date;
        String dateLabel;
        if (DateFormat('yyyy-MM-dd').format(readingDate) == DateFormat('yyyy-MM-dd').format(now)) {
          dateLabel = 'Today, $dateKey';
        } else if (DateFormat('yyyy-MM-dd').format(readingDate) ==
            DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)))) {
          dateLabel = 'Yesterday, $dateKey';
        } else {
          dateLabel = dateKey;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...dayReadings.map((r) => _ReadingListItem(reading: r)),
          ],
        );
      },
    );
  }

  Widget _buildChartView(List<VitalReading> readings) {
    if (readings.length < 2) {
      return const Center(
        child: Text('Not enough data for chart', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    // Sort oldest first for the chart
    final sorted = List<VitalReading>.from(readings)
      ..sort((a, b) => a.date.compareTo(b.date));

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    final sugarSpots = <FlSpot>[];

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final x = i.toDouble();
      if (r.systolic != null) systolicSpots.add(FlSpot(x, r.systolic!.toDouble()));
      if (r.diastolic != null) diastolicSpots.add(FlSpot(x, r.diastolic!.toDouble()));
      if (r.bloodSugar != null) sugarSpots.add(FlSpot(x, r.bloodSugar!));
    }

    final maxY = [
      if (systolicSpots.isNotEmpty) systolicSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b),
      if (sugarSpots.isNotEmpty) sugarSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    final minY = [
      if (diastolicSpots.isNotEmpty) diastolicSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b),
      if (sugarSpots.isNotEmpty) sugarSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b),
    ].fold<double>(double.infinity, (a, b) => a < b ? a : b);

    final yPadding = ((maxY - minY) * 0.2).clamp(10.0, 50.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendItem(color: AppColors.error, label: 'Systolic'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: AppColors.chartBlue, label: 'Diastolic'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: AppColors.warning, label: 'Sugar'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: (minY - yPadding).clamp(0, double.infinity),
                maxY: maxY + yPadding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (sorted.length / 5).ceil().toDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MM/dd').format(sorted[idx].date),
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (systolicSpots.isNotEmpty)
                    _buildLineBarData(systolicSpots, AppColors.error),
                  if (diastolicSpots.isNotEmpty)
                    _buildLineBarData(diastolicSpots, AppColors.chartBlue),
                  if (sugarSpots.isNotEmpty)
                    _buildLineBarData(sugarSpots, AppColors.warning),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label;
                        if (spot.bar.color == AppColors.error) {
                          label = 'Systolic';
                        } else if (spot.bar.color == AppColors.chartBlue) {
                          label = 'Diastolic';
                        } else {
                          label = 'Sugar';
                        }
                        return LineTooltipItem(
                          '$label: ${spot.y.toStringAsFixed(0)}',
                          const TextStyle(color: AppColors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2.5,
      isCurved: true,
      curveSmoothness: 0.3,
      dotData: FlDotData(show: spots.length < 15),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildNotesTab(List<VitalReading> readings) {
    final notes = readings.where((r) => r.note != null && r.note!.isNotEmpty).toList();
    if (notes.isEmpty) {
      return const Center(
        child: Text('No notes yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final r = notes[i];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.note, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(r.date),
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.note!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(List<VitalReading> readings) {
    final alerts = readings.where((r) {
      if (r.systolic == null) return false;
      return r.systolic! >= 140 || (r.bloodSugar ?? 0) >= 200;
    }).toList();
    if (alerts.isEmpty) {
      return const Center(
        child: Text('No alerts', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        final r = alerts[i];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, size: 20, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High Reading - ${r.bpString} mmHg',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                    Text(
                      DateFormat('MMM dd, h:mm a').format(r.date),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.error),
            ],
          ),
        );
      },
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _ReadingListItem extends StatelessWidget {
  final VitalReading reading;

  const _ReadingListItem({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Time and ref
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(reading.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(reading.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (reading.referenceId != null)
                  Text(
                    'Reference: ${reading.referenceId}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // BP
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BP', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text(
                reading.bpString,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: reading.systolic != null && reading.systolic! >= 140
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const Text('mmHg', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(width: 16),
          // Sugar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sugar', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text(
                reading.sugarString,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: (reading.bloodSugar ?? 0) >= 200
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const Text('mg/dL', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
            ],
          ),
          const Spacer(),
          // Status badge
          StatusBadge(
            text: reading.status ?? 'Pending',
            color: reading.status == 'Sent' ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
