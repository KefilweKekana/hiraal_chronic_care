import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String phoneNumber) onSendCode;
  final VoidCallback onBack;

  const RegisterScreen({
    super.key,
    required this.onSendCode,
    required this.onBack,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  bool _isValid = false;
  String _selectedCountryCode = '+252';
  String _selectedFlag = '🇸🇴';

  static const List<Map<String, String>> _countryCodes = [
    {'code': '+252', 'flag': '🇸🇴', 'name': 'Somalia'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
    {'code': '+253', 'flag': '🇩🇯', 'name': 'Djibouti'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italy'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Spain'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Egypt'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+880', 'flag': '🇧🇩', 'name': 'Bangladesh'},
    {'code': '+62', 'flag': '🇮🇩', 'name': 'Indonesia'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brazil'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Russia'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+82', 'flag': '🇰🇷', 'name': 'South Korea'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'Mexico'},
    {'code': '+60', 'flag': '🇲🇾', 'name': 'Malaysia'},
    {'code': '+63', 'flag': '🇵🇭', 'name': 'Philippines'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'Sudan'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'Lebanon'},
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+98', 'flag': '🇮🇷', 'name': 'Iran'},
    {'code': '+93', 'flag': '🇦🇫', 'name': 'Afghanistan'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Morocco'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisia'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algeria'},
    {'code': '+218', 'flag': '🇱🇾', 'name': 'Libya'},
    {'code': '+967', 'flag': '🇾🇪', 'name': 'Yemen'},
    {'code': '+46', 'flag': '🇸🇪', 'name': 'Sweden'},
    {'code': '+47', 'flag': '🇳🇴', 'name': 'Norway'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone(String value) {
    setState(() {
      _isValid = value.replaceAll(' ', '').length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(child: HiraalLogo(size: 60)),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    "Let's get started",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Enter the mobile number linked to your\npatient record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                    color: AppColors.inputBackground,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _countryCodes.indexWhere((c) =>
                                c['code'] == _selectedCountryCode &&
                                c['flag'] == _selectedFlag),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            isDense: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            borderRadius: BorderRadius.circular(12),
                            menuMaxHeight: 350,
                            selectedItemBuilder: (context) {
                              return _countryCodes.asMap().entries.map((entry) {
                                final country = entry.value;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(country['flag']!, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text(
                                      country['code']!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                            items: _countryCodes.asMap().entries.map((entry) {
                              final i = entry.key;
                              final country = entry.value;
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Row(
                                  children: [
                                    Text(country['flag']!, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      country['code']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        country['name']!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (index) {
                              if (index != null) {
                                setState(() {
                                  _selectedCountryCode = _countryCodes[index]['code']!;
                                  _selectedFlag = _countryCodes[index]['flag']!;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.inputBorder,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: _validatePhone,
                          decoration: const InputDecoration(
                            hintText: 'Enter phone number',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            filled: false,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'We will look up your record in the hospital system',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (provider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      final isLoading = provider.isLoading;
                      return ElevatedButton(
                        onPressed: _isValid && !isLoading
                            ? () => widget.onSendCode(
                                '$_selectedCountryCode${_phoneController.text}')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isValid && !isLoading
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.5),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Code'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    const Text(
                      'Your information is safe with us',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
