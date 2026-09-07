import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_coverage.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/coverage_gate.dart';
import '../../widgets/coverage_outcome.dart';
import 'appointments_screen.dart';
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
  final _reasonController = TextEditingController();
  bool _isBooked = false;
  bool _isLoading = false;
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

  SlotAvailability? _slots;
  bool _loadingSlots = false;
  String? _slotError;
  String? _selectedDay;
  AppointmentSlot? _selectedSlot;
  bool _pickingSlot = false;

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
    if (_selectedDoctorId != null &&
        !_doctors.any((d) => d['name'] == _selectedDoctorId)) {
      _selectedDoctorId = null;
    }
    if (_selectedDoctorId != null) {
      _fetchSlots();
    }
  }

  void _clearSpecialtyFilter() {
    setState(() {
      _doctors = _allDoctors;
      _filterFallback = false;
      _selectedDoctorId = _doctors.isNotEmpty ? _doctors.first['name'] : null;
    });
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final practitioner = _selectedDoctorId;
    if (practitioner == null || practitioner.isEmpty) {
      setState(() {
        _slots = null;
        _selectedDay = null;
        _selectedSlot = null;
      });
      return;
    }
    setState(() {
      _loadingSlots = true;
      _slotError = null;
    });
    final result = await ServiceLocator.instance.bookings.getAvailableSlots(
      practitioner: practitioner,
    );
    if (!mounted) return;
    switch (result) {
      case Success(data: final data):
        setState(() {
          _slots = data;
          _loadingSlots = false;
          _selectedDay = data.days.isNotEmpty ? data.days.first.date : null;
          _selectedSlot = null;
        });
      case Failure(message: final msg):
        setState(() {
          _slotError = msg;
          _loadingSlots = false;
        });
    }
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
    if (_selectedSlot == null || _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chooseDateTime), backgroundColor: AppColors.error),
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
    final serviceType = _visitType == 'video' ? 'video_consultation' : 'consultation';
    final provider = context.read<AppProvider>();
    final patient = actingPatientId(
      carePatient: provider.activeCarePerson?.patient,
      selfPatient: provider.patient?.id,
    );
    final coverageResult = await ServiceLocator.instance.bookings.checkServiceCoverage(
      serviceType: serviceType,
      patient: patient,
      appointmentType: 'Chronic Care Follow Up',
    );
    if (!mounted) return;
    late final ServiceCoverage coverage;
    switch (coverageResult) {
      case Success(data: final c):
        coverage = c;
      case Failure(message: final msg):
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
        return;
    }
    setState(() { _isLoading = false; });
    final proceed = await presentServiceCoverage(
      context: context,
      coverage: coverage,
      title: l10n.completePayment,
      patient: patient,
      serviceType: serviceType,
    );
    if (proceed != true || !mounted) return;
    setState(() { _isLoading = true; });
    final date = DateTime.tryParse(_selectedDay!) ?? DateTime.now();
    final timeSlot = _selectedSlot!.time;
    final result = await ServiceLocator.instance.bookings.bookDoctor(
      // Patient Appointment.appointment_type is a Link to Appointment Type —
      // department names aren't valid types, so use the server's default.
      doctorType: 'Chronic Care Follow Up',
      date: date,
      timeSlot: timeSlot,
      reason: _reasonController.text.trim().isEmpty
          ? 'Chronic care follow-up'
          : _reasonController.text.trim(),
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
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(_pickingSlot ? l10n.chooseDateTime : l10n.chooseDoctorTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pickingSlot) {
              setState(() => _pickingSlot = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
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
        child: _pickingSlot ? _buildSlotStep(context, l10n) : _buildDoctorStep(context, l10n),
      ),
    );
  }

  Widget _forBanner(BuildContext context, AppLocalizations l10n) {
    final provider = context.watch<AppProvider>();
    if (!provider.isCaregiverMode) return const SizedBox.shrink();
    final name = provider.activeCarePerson?.patientName ?? provider.patient?.name ?? '';
    if (name.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.bookingOnBehalf(name),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorStep(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _forBanner(context, l10n),
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
        Text(l10n.onlineDoctorsHint, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4)),
        if (_filterFallback && widget.specialtyLabel != null) ...[
          const SizedBox(height: 4),
          Text(l10n.noSpecialistsShowingAll(widget.specialtyLabel!), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
        const SizedBox(height: 16),
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
          ..._doctors.map((d) {
            final id = d['name'] as String?;
            final name = '${d['practitioner_name'] ?? d['name']}';
            final dept = '${d['department'] ?? l10n.departmentGeneral}';
            final initials = name
                .replaceAll(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
                .split(' ')
                .where((p) => p.isNotEmpty)
                .map((p) => p[0])
                .take(2)
                .join()
                .toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedDoctorId = id;
                      _pickingSlot = true;
                    });
                    _fetchSlots();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.infoLight,
                          child: Text(
                            initials.isEmpty ? 'DR' : initials,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.info, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(dept, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.success, size: 26),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
          icon: const Icon(Icons.event_available_outlined),
          label: Text(l10n.appointments),
        ),
      ],
    );
  }

  Widget _buildSlotStep(BuildContext context, AppLocalizations l10n) {
    final doctor = _doctors.firstWhere((d) => d['name'] == _selectedDoctorId, orElse: () => {});
    final name = '${doctor['practitioner_name'] ?? doctor['name'] ?? ''}';
    final dept = '${doctor['department'] ?? l10n.departmentGeneral}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _forBanner(context, l10n),
        if (name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.infoLight,
                  child: Text(
                    name.replaceAll(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.info),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(dept, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Text(l10n.visitType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
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
        if (_visitType == 'inperson') ...[
          const SizedBox(height: 16),
          Text(l10n.clinicLocationLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _buildStationPicker(l10n),
        ],
        const SizedBox(height: 20),
        Text(l10n.selectADate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_loadingSlots)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_slotError != null)
          Text(_slotError!, style: const TextStyle(color: AppColors.error))
        else if (_slots == null || _slots!.empty)
          Text(l10n.noSlotsYet, style: TextStyle(color: AppColors.textMuted(context), fontSize: 15))
        else ...[
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _slots!.days.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = _slots!.days[i];
                final selected = _selectedDay == day.date;
                return BigChoiceButton(
                  label: day.dayLabel,
                  selected: selected,
                  onTap: () => setState(() {
                    _selectedDay = day.date;
                    _selectedSlot = null;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.selectATime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in (_slots!.days.firstWhere(
                (d) => d.date == _selectedDay,
                orElse: () => _slots!.days.first,
              ).slots))
                BigChoiceButton(
                  label: slot.label,
                  selected: _selectedSlot?.time == slot.time,
                  enabled: slot.available,
                  onTap: slot.available ? () => setState(() => _selectedSlot = slot) : null,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(l10n.reasonOptional, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 2,
          maxLength: 250,
          decoration: InputDecoration(hintText: l10n.reasonVisitHint),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isLoading || _selectedDoctorId == null || _selectedSlot == null) ? null : _bookAppointment,
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : Text(l10n.continueLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 24),
      ],
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _stations.map((s) {
        final id = s['name']?.toString() ?? '';
        final name = (s['station_name'] ?? s['name'] ?? '').toString();
        final city = (s['city'] ?? '').toString();
        return BigChoiceButton(
          label: name,
          subtitle: city,
          icon: Icons.location_on_outlined,
          selected: _selectedStationId == id,
          onTap: () => setState(() => _selectedStationId = id),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmation(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
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
                  _selectedDay ?? '',
                  _selectedSlot?.label ?? '',
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
          color: isSelected
              ? (AppColors.isDark(context) ? AppColors.darkPrimaryLight : AppColors.primaryLight)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(context),
            width: isSelected ? 2 : 1,
          ),
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
