import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import 'video_visits_screen.dart';

class BookDoctorScreen extends StatefulWidget {
  /// Optional specialty filter (from the Services category chips): only
  /// doctors whose department contains one of [specialtyKeywords] are listed.
  /// Falls back to the full list when nothing matches.
  final String? specialtyLabel;
  final List<String>? specialtyKeywords;

  const BookDoctorScreen({super.key, this.specialtyLabel, this.specialtyKeywords});

  @override
  State<BookDoctorScreen> createState() => _BookDoctorScreenState();
}

class _BookDoctorScreenState extends State<BookDoctorScreen> {
  String _visitType = 'video';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTimeOfDay = const TimeOfDay(hour: 10, minute: 0);
  final _reasonController = TextEditingController();
  bool _isBooked = false;
  bool _isLoading = false;
  bool _isFavorite = false;
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  String? _doctorError;
  bool _filterFallback = false;
  bool _isLoadingDoctors = true;

  List<Map<String, dynamic>> _stations = [];
  String? _selectedStationId;
  bool _isLoadingStations = true;
  String? _stationError;

  bool get _filterActive =>
      widget.specialtyLabel != null && (widget.specialtyKeywords ?? []).isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _fetchStations();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() { _isLoadingDoctors = true; _doctorError = null; });
    final result = await ServiceLocator.instance.bookings.getDoctors();
    if (!mounted) return;
    switch (result) {
      case Success(data: final list):
        setState(() {
          _allDoctors = list;
          _applySpecialtyFilter();
          _isLoadingDoctors = false;
        });
      case Failure(message: final msg):
        setState(() { _doctorError = msg; _isLoadingDoctors = false; });
    }
  }

  /// Apply the category filter (if any) to the full doctor list. Falls back
  /// to the full list with an explanatory note when no department matches —
  /// an empty dropdown would be worse than a broad one.
  void _applySpecialtyFilter() {
    if (!_filterActive) {
      _doctors = _allDoctors;
      _filterFallback = false;
    } else {
      final keywords = widget.specialtyKeywords!;
      final matches = _allDoctors.where((d) {
        final dept = (d['department'] ?? '').toString().toLowerCase();
        return keywords.any((k) => dept.contains(k));
      }).toList();
      if (matches.isEmpty) {
        _doctors = _allDoctors;
        _filterFallback = true;
      } else {
        _doctors = matches;
        _filterFallback = false;
      }
    }
    _selectedDoctorId = _doctors.isNotEmpty ? _doctors.first['name'] : null;
  }

  void _clearSpecialtyFilter() {
    setState(() {
      _doctors = _allDoctors;
      _filterFallback = false;
      _selectedDoctorId = _doctors.isNotEmpty ? _doctors.first['name'] : null;
    });
  }

  Future<void> _fetchStations() async {
    setState(() {
      _isLoadingStations = true;
      _stationError = null;
    });
    final result = await ServiceLocator.instance.bookings.getCareStations();
    if (!mounted) return;
    switch (result) {
      case Success(data: final list):
        setState(() {
          _stations = list;
          _selectedStationId =
              list.isNotEmpty ? list.first['name']?.toString() : null;
          _isLoadingStations = false;
        });
      case Failure(message: final msg):
        setState(() {
          _stationError = msg;
          _isLoadingStations = false;
        });
    }
  }

  Future<void> _bookAppointment() async {
    final l10n = AppLocalizations.of(context);
    final doctor = _doctors.firstWhere((d) => d['name'] == _selectedDoctorId, orElse: () => {});
    final practitioner = doctor['name']?.toString() ?? '';
    if (practitioner.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectDoctor), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseDescribeReason), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_visitType == 'inperson') {
      if (_stations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noStationsAvailable), backgroundColor: AppColors.error),
        );
        return;
      }
      if (_selectedStationId == null || _selectedStationId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectStation), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    setState(() { _isLoading = true; });
    final timeSlot = '${_selectedTimeOfDay.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay.minute.toString().padLeft(2, '0')}:00';
    final result = await ServiceLocator.instance.bookings.bookDoctor(
      // Patient Appointment.appointment_type is a Link to Appointment Type —
      // department names aren't valid types, so use the server's default.
      doctorType: 'Chronic Care Follow Up',
      date: _selectedDateTime,
      timeSlot: timeSlot,
      reason: _reasonController.text.trim(),
      practitioner: practitioner,
      isVideoCall: _visitType == 'video',
      careStation: _visitType == 'inperson' ? _selectedStationId : null,
    );
    if (!mounted) return;
    setState(() { _isLoading = false; });
    switch (result) {
      case Success():
        setState(() { _isBooked = true; });
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isBooked) return _buildConfirmation(context, l10n);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(l10n.bookDoctor),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.error : null),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final count = context.watch<AppProvider>().unreadNotificationCount;
              return IconButton(
                icon: Stack(children: [
                  const Icon(Icons.notifications_outlined),
                  if (count > 0)
                    Positioned(right: 0, top: 0, child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
                ]),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
            // Doctor selection
            if (_filterActive && widget.specialtyLabel != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text(widget.specialtyLabel!),
                  onDeleted: _clearSpecialtyFilter,
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(l10n.selectDoctor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_filterFallback && widget.specialtyLabel != null) ...[
              const SizedBox(height: 4),
              Text(l10n.noSpecialistsShowingAll(widget.specialtyLabel!), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
            const SizedBox(height: 8),
            if (_isLoadingDoctors)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_doctorError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_doctorError!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  TextButton(onPressed: _fetchDoctors, child: Text(l10n.retry)),
                ]),
              )
            else if (_doctors.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.noDoctorsAvailable, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  TextButton(onPressed: _fetchDoctors, child: Text(l10n.refresh)),
                ]),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedDoctorId,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _doctors.map((d) => DropdownMenuItem<String>(
                  value: d['name'] as String?,
                  child: Text(
                    '${d['practitioner_name'] ?? d['name']} — ${d['department'] ?? l10n.departmentGeneral}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedDoctorId = v),
              ),
            const SizedBox(height: 24),
            Text(l10n.appointmentDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.reasonForVisit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(l10n.required, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: l10n.reasonVisitHint,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.selectDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _selectedDateTime = picked);
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
                              Text(DateFormat('MMM dd, yyyy').format(_selectedDateTime), style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.timeSlot, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTimeOfDay,
                          );
                          if (picked != null) setState(() => _selectedTimeOfDay = picked);
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
                              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(_selectedTimeOfDay.format(context), style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l10n.availableSlotsHint, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.visitType, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(l10n.chooseConsultHow, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.videocam,
                    label: l10n.videoCall,
                    subtitle: l10n.consultFromHome,
                    isSelected: _visitType == 'video',
                    onTap: () => setState(() => _visitType = 'video'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.location_on,
                    label: l10n.inPersonVisit,
                    subtitle: l10n.visitAtClinic,
                    isSelected: _visitType == 'inperson',
                    onTap: () => setState(() => _visitType = 'inperson'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_visitType == 'inperson') ...[
              Text(l10n.clinicLocationLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _buildStationPicker(l10n),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.verified_user, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l10n.appointmentSecureEasy, style: const TextStyle(fontSize: 12, color: AppColors.success)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedDoctorId == null) ? null : _bookAppointment,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.requestAppointment),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(l10n.confirmationShortly, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStationPicker(AppLocalizations l10n) {
    if (_isLoadingStations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_stationError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stationError!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
          TextButton(
            onPressed: _fetchStations,
            child: Text(l10n.retry),
          ),
        ],
      );
    }
    if (_stations.isEmpty) {
      return Text(
        l10n.noStationsAvailable,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
        color: AppColors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedStationId,
          hint: Text(l10n.selectClinic),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          items: _stations.map((s) {
            final id = s['name']?.toString() ?? '';
            final name = (s['station_name'] ?? s['name'] ?? '').toString();
            final city = (s['city'] ?? '').toString();
            final address = (s['address'] ?? '').toString();
            final subtitle = [
              if (city.isNotEmpty) city,
              if (address.isNotEmpty) address,
            ].join(' · ');
            return DropdownMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedStationId = v),
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: Text(l10n.appointmentConfirmedTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text(l10n.appointmentBooked, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                l10n.appointmentConfirmedFor(
                  DateFormat('MMM dd, yyyy').format(_selectedDateTime),
                  _selectedTimeOfDay.format(context),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              if (_visitType == 'video') ...[
                Text(
                  l10n.videoVisitJoinReady,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoVisitsScreen()),
                    ),
                    icon: const Icon(Icons.video_call),
                    label: Text(l10n.goToVideoVisit),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.backToServices)),
              ] else
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.backToServices)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisitTypeCard({
    required this.icon, required this.label, required this.subtitle,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.textTertiary),
                if (isSelected)
                  Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: AppColors.white, size: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
