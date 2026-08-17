import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../models/telemedicine_session.dart';
import '../../services/service_locator.dart';
import 'book_doctor_screen.dart';

/// Lists the patient's telemedicine (video) visits and lets them join the live
/// call. The call opens in the Jitsi Meet app / browser via the session link.
class VideoVisitsScreen extends StatefulWidget {
  const VideoVisitsScreen({super.key});

  @override
  State<VideoVisitsScreen> createState() => _VideoVisitsScreenState();
}

class _VideoVisitsScreenState extends State<VideoVisitsScreen> {
  List<TelemedicineSession> _sessions = [];
  bool _loading = true;
  String? _error;
  String? _joiningId;
  String? _endingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    final result = await ServiceLocator.instance.bookings.getMyVideoVisits();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final s):
          _sessions = s;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  Future<void> _join(TelemedicineSession s) async {
    final url = s.meetingUrl;
    if (url == null || url.isEmpty) return;

    // Alert the assigned doctor that the patient is joining (best-effort — we
    // still open the call even if this fails, so the patient is never stranded).
    setState(() => _joiningId = s.id);
    await ServiceLocator.instance.bookings.notifyJoiningVideoVisit(s.id);
    if (!mounted) return;
    setState(() => _joiningId = null);

    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _snack('Could not open the video call. Please try again.');
      }
    } catch (_) {
      if (mounted) _snack('Could not open the video call. Please try again.');
    }
    // Refresh so the status (now "In Progress") reflects on the list.
    if (mounted) _load();
  }

  Future<void> _end(TelemedicineSession s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End video visit?'),
        content: const Text('Mark this visit as finished?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, finished')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _endingId = s.id);
    final result = await ServiceLocator.instance.bookings.endVideoVisit(s.id);
    if (!mounted) return;
    setState(() => _endingId = null);
    switch (result) {
      case Success():
        _load();
      case Failure(message: final msg):
        _snack(msg);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: AppColors.error),
      );

  Color _statusColor(TelemedicineSession s) {
    if (s.isCancelled) return AppColors.error;
    if (s.isCompleted) return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Video Visits'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookDoctorScreen()),
          );
          _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.video_call, color: AppColors.white),
        label: const Text('Book Video Visit', style: TextStyle(color: AppColors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _sessions.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _sessionCard(_sessions[i]),
                      ),
                    ),
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );

  Widget _emptyView() => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.video_camera_front_outlined, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Center(child: Text('No video visits yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            SizedBox(height: 4),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Book an appointment and choose “Video Call” to set up a live consultation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sessionCard(TelemedicineSession s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.videocam, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.doctorLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      s.startTime != null
                          ? DateFormat('MMM dd, yyyy • HH:mm').format(s.startTime!)
                          : 'Time to be confirmed',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(s.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          if (s.isCompleted && s.durationMinutes != null) ...[
            const SizedBox(height: 8),
            Text('Call duration: ${s.durationMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (s.isJoinable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _joiningId == s.id ? null : () => _join(s),
                icon: _joiningId == s.id
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.video_call, size: 20),
                label: Text(_joiningId == s.id ? 'Connecting…' : 'Join Video Call'),
              ),
            ),
            if (s.status == 'In Progress')
              TextButton.icon(
                onPressed: _endingId == s.id ? null : () => _end(s),
                icon: _endingId == s.id
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.call_end, size: 18, color: AppColors.error),
                label: Text(_endingId == s.id ? 'Ending…' : 'Mark visit as finished',
                    style: const TextStyle(color: AppColors.error)),
              ),
          ],
        ],
      ),
    );
  }
}
