import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';

class BookDoctorScreen extends StatefulWidget {
  const BookDoctorScreen({super.key});

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
  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  String? _doctorError;
  bool _isLoadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() { _isLoadingDoctors = true; _doctorError = null; });
    final result = await ServiceLocator.instance.bookings.getDoctors();
    switch (result) {
      case Success(data: final list):
        setState(() {
          _doctors = list;
          _selectedDoctorId = list.isNotEmpty ? list.first['name'] : null;
          _isLoadingDoctors = false;
        });
      case Failure(message: final msg):
        setState(() { _doctorError = msg; _isLoadingDoctors = false; });
    }
  }

  Future<void> _bookAppointment() async {
    setState(() { _isLoading = true; });
    final timeSlot = '${_selectedTimeOfDay.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay.minute.toString().padLeft(2, '0')}:00';
    final doctor = _doctors.firstWhere((d) => d['name'] == _selectedDoctorId, orElse: () => {});
    final result = await ServiceLocator.instance.bookings.bookDoctor(
      doctorType: doctor['department'] ?? 'General Physician',
      date: _selectedDateTime,
      timeSlot: timeSlot,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      practitioner: doctor['name'] ?? 'Dr. Omer',
      isVideoCall: _visitType == 'video',
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
    if (_isBooked) return _buildConfirmation(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Book Doctor'),
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
            const Text('Select Doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  TextButton(onPressed: _fetchDoctors, child: const Text('Retry')),
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
                    '${d['practitioner_name'] ?? d['name']} — ${d['department'] ?? 'General'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedDoctorId = v),
              ),
            const SizedBox(height: 24),
            const Text('Appointment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Reason for Visit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Required', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 250,
              decoration: const InputDecoration(
                hintText: 'Please describe your symptoms or reason for the visit...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                      const Text('Time Slot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
            const Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 4),
                Text('Showing available slots for today and next 7 days.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Visit Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Choose how you would like to consult.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.videocam,
                    label: 'Video Call',
                    subtitle: 'Consult from home',
                    isSelected: _visitType == 'video',
                    onTap: () => setState(() => _visitType = 'video'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisitTypeCard(
                    icon: Icons.location_on,
                    label: 'In-Person Visit',
                    subtitle: 'Visit at clinic',
                    isSelected: _visitType == 'inperson',
                    onTap: () => setState(() => _visitType = 'inperson'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Clinic Location (for in-person visit)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
                color: AppColors.inputBackground,
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hiraal Health Center, Main Branch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('123 Health Ave, City, Country', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.verified_user, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('Your appointment is secure and easy to manage.', style: TextStyle(fontSize: 12, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookAppointment,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Request Appointment'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text("You'll receive a confirmation shortly.", style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Appointment Confirmed')),
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
              const Text('Appointment Booked!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Your appointment is confirmed for ${DateFormat('MMM dd, yyyy').format(_selectedDateTime)} at ${_selectedTimeOfDay.format(context)}.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Services')),
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
