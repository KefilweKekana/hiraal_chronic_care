import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../services/booking_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/skeleton.dart';
import 'book_doctor_screen.dart';

/// The patient's upcoming appointments (from get_my_appointments) — where the
/// profile "Appointments" activity card and the home "Next appointment" card
/// lead. Read-only for now; booking a new one goes through BookDoctorScreen.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentInfo> _appointments = [];
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
    final result = await ServiceLocator.instance.bookings.getMyAppointments();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final list):
          _appointments = list;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        title: Text(l10n.myAppointments),
        elevation: 0,
      ),
      body: _loading
          ? const SkeletonList(itemCount: 4)
          : _error != null
              ? _buildError(l10n)
              : _appointments.isEmpty
                  ? _buildEmpty(l10n)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, i) => _appointmentCard(_appointments[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookDoctorScreen()),
        ).then((_) => _load()),
        icon: Icon(Icons.add),
        label: Text(l10n.bookDoctor),
      ),
    );
  }

  Widget _appointmentCard(AppointmentInfo a) {
    final dateLabel = DateFormat('EEE, MMM d, yyyy').format(a.date);
    final timeLabel = a.time.length >= 5 ? a.time.substring(0, 5) : a.time;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.of(context).primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.practitionerName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '$dateLabel${timeLabel.isNotEmpty ? ' · $timeLabel' : ''}',
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
                ),
                if (a.type.isNotEmpty)
                  Text(a.type,
                      style: TextStyle(fontSize: 11, color: AppColors.of(context).textFaint)),
              ],
            ),
          ),
          if (a.status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.of(context).successSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                a.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.of(context).textMuted)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );

  Widget _buildEmpty(AppLocalizations l10n) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.event_available, size: 56, color: AppColors.of(context).textFaint),
            const SizedBox(height: 12),
            Center(
              child: Text(l10n.noUpcomingAppointments,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.of(context).textMuted)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(l10n.bookDoctorEmptyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint, height: 1.5)),
            ),
          ],
        ),
      );
}
