import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medicine_order.dart';
import '../../models/vital_reading.dart';
import '../../providers/app_provider.dart';
import '../../services/bluetooth_service.dart';
import '../../services/booking_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/skeleton.dart';
import '../alerts/high_bp_alert_screen.dart';
import '../devices/device_pairing_screen.dart';
import '../services/appointments_screen.dart';
import '../services/order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _sugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  bool? _medicineTaken;
  bool _isSending = false;
  bool _isSent = false;
  MedicineOrder? _pendingOrder;
  AppointmentInfo? _nextAppointment;
  final BluetoothHealthService _bleService = BluetoothHealthService.instance;

  @override
  void initState() {
    super.initState();
    // The device indicator reflects live BLE state, which lives in the
    // singleton BluetoothHealthService (a ChangeNotifier), not AppProvider.
    _bleService.addListener(_onBleStateChanged);
    _loadPendingPayment();
    _loadNextAppointment();
  }

  void _onBleStateChanged() {
    if (mounted) setState(() {});
  }

  /// Surface a "payment pending" banner when an order is Awaiting Payment.
  Future<void> _loadPendingPayment() async {
    final result = await ServiceLocator.instance.bookings.getMyOrders();
    if (!mounted) return;
    if (result case Success(data: final orders)) {
      final payable = orders.where((o) => o.payable);
      setState(() => _pendingOrder = payable.isNotEmpty ? payable.first : null);
    }
  }

  /// Fetch the patient's next upcoming appointment for the home card. Fail
  /// closed: no appointment, an error, or still loading all hide the card.
  Future<void> _loadNextAppointment() async {
    final result = await ServiceLocator.instance.bookings.getMyAppointments();
    if (!mounted) return;
    if (result case Success(data: final appointments)) {
      setState(() =>
          _nextAppointment = appointments.isNotEmpty ? appointments.first : null);
    }
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleStateChanged);
    _systolicController.dispose();
    _diastolicController.dispose();
    _sugarController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _systolicController.text.isNotEmpty &&
      _diastolicController.text.isNotEmpty &&
      _sugarController.text.isNotEmpty &&
      _weightController.text.isNotEmpty;

  // Time-of-day greeting shared by the home header and the success view.
  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    return hour < 12
        ? l10n.greetingMorning
        : hour < 17
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
  }

  Widget _pendingPaymentBanner() {
    final o = _pendingOrder;
    if (o == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id, initial: o)),
          );
          _loadPendingPayment();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.payments_outlined, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.paymentPending, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      l10n.orderPayToContinue(
                        o.id,
                        '${AppConstants.currencySymbol}${o.amountDue.toStringAsFixed(2)}',
                      ),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact 'Next appointment' card shown under the header when the patient
  /// has an upcoming appointment. Hidden when there is none.
  Widget _nextAppointmentCard() {
    final a = _nextAppointment;
    if (a == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    // appointment_time arrives as "H:mm:ss" — trim the seconds for display.
    final time = a.time.length > 5 ? a.time.substring(0, 5) : a.time;
    final practitioner =
        a.practitionerName.isNotEmpty ? a.practitionerName : l10n.yourDoctor;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nextAppointment, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '$practitioner — ${DateFormat('EEE, MMM d').format(a.date)}${time.isNotEmpty ? ' · $time' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer placeholders standing in for the reading form while the
  /// provider's first readings load is in flight (avoids the empty flash).
  Widget _readingFormSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 160, height: 18),
        SizedBox(height: 8),
        SkeletonCard(),
        SkeletonCard(),
        SkeletonCard(),
        SkeletonCard(),
      ],
    );
  }

  Future<void> _submitReading() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    
    final systolic = int.tryParse(_systolicController.text) ?? 0;
    final diastolic = int.tryParse(_diastolicController.text) ?? 0;
    final sugar = double.tryParse(_sugarController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    
    final reading = VitalReading(
      // Millisecond suffix keeps the id unique even for same-minute submissions
      // (the server dedupes retries by this reference).
      referenceId:
          'SUB-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}-${DateTime.now().millisecond}',
      date: DateTime.now(),
      systolic: systolic,
      diastolic: diastolic,
      bloodSugar: sugar,
      weight: weight,
      medicineTaken: _medicineTaken,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      status: 'Sent',
      // Queued for upload: the provider flips this to Synced once the server
      // accepts it; SyncManager retries anything still Pending.
      syncStatus: 'Pending',
    );

    if (mounted) {
      final success = await context.read<AppProvider>().submitReading(reading);
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _isSent = success;
      });

      if (!success) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppProvider>().errorMessage ?? l10n.failedToSubmitReading),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Tactile confirmation that the reading went through (no-op on web).
      HapticFeedback.mediumImpact();

      // Check if alert needed
      if (systolic >= 160 || diastolic >= 100) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HighBpAlertScreen(reading: reading),
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isSent = false;
      _systolicController.clear();
      _diastolicController.clear();
      _sugarController.clear();
      _weightController.clear();
      _noteController.clear();
      _medicineTaken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);

    if (_isSent) {
      return _buildSuccessView(provider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Greeting header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          patient?.name.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join() ?? 'AA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(l10n),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              patient?.name ?? l10n.patientFallback,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Badge.count(
                        count: provider.unreadNotificationCount,
                        isLabelVisible: provider.unreadNotificationCount > 0,
                        backgroundColor: AppColors.error,
                        textColor: AppColors.white,
                        child: IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/notifications'),
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _pendingPaymentBanner(),
                  _nextAppointmentCard(),
                  const SizedBox(height: 20),
                  // Date and last submitted
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.todaysDate,
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(now),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE').format(now),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.lastSubmitted,
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              ),
                              Text(
                                provider.readings.isNotEmpty
                                    ? DateFormat('MMM dd, yyyy').format(provider.readings.first.date)
                                    : '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                provider.readings.isNotEmpty
                                    ? DateFormat('h:mm a').format(provider.readings.first.date)
                                    : l10n.noReadingYetToday,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.enterReadingsInfo,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // While the provider's first readings load is in flight,
                  // show shimmer placeholders instead of the reading form.
                  if (provider.isLoading && provider.readings.isEmpty)
                    _readingFormSkeleton()
                  else ...[
                  // Today's Reading header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.todaysReading,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      StatusBadge(text: l10n.required, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Blood Pressure
                  _buildVitalSection(
                    icon: Icons.favorite,
                    iconColor: AppColors.error,
                    title: l10n.bloodPressure,
                    subtitle: l10n.unitMmHg,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: l10n.systolicTop,
                            hint: l10n.hintSystolic,
                            controller: _systolicController,
                            validator: Validators.systolic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: l10n.diastolicBottom,
                            hint: l10n.hintDiastolic,
                            controller: _diastolicController,
                            validator: Validators.diastolic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Blood Sugar
                  _buildVitalSection(
                    icon: Icons.water_drop,
                    iconColor: AppColors.primary,
                    title: l10n.bloodSugar,
                    subtitle: l10n.unitMgDl,
                    child: _buildInputField(
                      label: '',
                      hint: l10n.hintBloodSugar,
                      controller: _sugarController,
                      validator: Validators.bloodSugar,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weight
                  _buildVitalSection(
                    icon: Icons.monitor_weight,
                    iconColor: AppColors.chartPurple,
                    title: l10n.weight,
                    subtitle: l10n.unitKg,
                    child: _buildInputField(
                      label: '',
                      hint: l10n.hintWeight,
                      controller: _weightController,
                      validator: Validators.weight,
                      allowDecimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medicine Taken
                  _buildVitalSection(
                    icon: Icons.medication,
                    iconColor: AppColors.success,
                    title: l10n.medicineTaken,
                    subtitle: l10n.medicineTakenPrompt,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMedicineButton(
                            label: l10n.yesTaken,
                            icon: Icons.check_circle_outline,
                            isSelected: _medicineTaken == true,
                            color: AppColors.success,
                            onTap: () => setState(() => _medicineTaken = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMedicineButton(
                            label: l10n.noMissed,
                            icon: Icons.cancel_outlined,
                            isSelected: _medicineTaken == false,
                            color: AppColors.error,
                            onTap: () => setState(() => _medicineTaken = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Note
                  Text(
                    l10n.addNoteOptional,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.howFeelingHint,
                      prefixIcon: const Icon(Icons.edit_note, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Connect Device
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
                      );
                    },
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: _bleService.isConnected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.connectDevice,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.importReadingsFromDevice,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_bleService.isConnected) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.connected,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 20),
                  // Save & Send button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isFormValid ? _submitReading : null,
                      icon: const Icon(Icons.send, size: 20),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.saveAndSend, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(l10n.sendReadingToCareTeam, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            ),
            // Sending overlay
            if (_isSending)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text(
                          l10n.submittingReading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.dontCloseWhileSending,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              l10n.dataSecureProtected,
                              style: const TextStyle(fontSize: 12, color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppProvider provider) {
    final lastReading = provider.readings.first;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      provider.patient?.name.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_greeting(l10n), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(provider.patient?.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppColors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.allSet,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.readingSavedSent,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    l10n.careTeamNotified,
                    style: const TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.submissionSummary,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _summaryRow(Icons.calendar_today, l10n.date, DateFormat('MMM dd, yyyy (EEEE)').format(lastReading.date)),
                    _summaryRow(Icons.access_time, l10n.time, DateFormat('h:mm a').format(lastReading.date)),
                    _summaryRow(Icons.people, l10n.sentTo, l10n.yourCareTeam),
                    _summaryRow(Icons.tag, l10n.referenceId, lastReading.referenceId ?? l10n.notAvailable),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      l10n.notifiedWhenReviewed,
                      style: const TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.home, size: 20),
                  label: Text(l10n.goToHome),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _resetForm();
                    context.read<AppProvider>().setTab(2);
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(l10n.viewHistory),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool allowDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          // Weight is a Float (Validators.weight accepts doubles), so allow
          // one decimal point there; BP/sugar stay digits-only.
          inputFormatters: [
            allowDecimal
                ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
                : FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (_) => setState(() {}),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMedicineButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
