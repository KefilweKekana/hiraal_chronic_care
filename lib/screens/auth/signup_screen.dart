import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';

/// New-patient self-registration. Collects the details the server needs to
/// create a Patient (name, gender, date of birth, phone), sends an SMS OTP to
/// verify the phone, then hands off to the OTP screen via [onCreateAccount].
class SignUpScreen extends StatefulWidget {
  /// Called with the collected details. dob is ISO 'yyyy-MM-dd'.
  final Function(
    String fullName,
    String phone,
    String sex,
    String dob,
    String? email,
  ) onCreateAccount;

  /// Called when the user already has an account and wants to sign in instead.
  final VoidCallback onBack;

  const SignUpScreen({
    super.key,
    required this.onCreateAccount,
    required this.onBack,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _sex;
  DateTime? _dob;

  String _selectedCountryCode = '+252';
  String _selectedFlag = 'SL';

  static const List<Map<String, String>> _countryCodes = [
    {'code': '+252', 'flag': 'SL', 'name': 'Somaliland', 'asset': 'assets/flags/somaliland.svg'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
    {'code': '+253', 'flag': '🇩🇯', 'name': 'Djibouti'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Egypt'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'Sudan'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+46', 'flag': '🇸🇪', 'name': 'Sweden'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
  ];

  bool get _isValid =>
      _nameController.text.trim().length >= 2 &&
      _sex != null &&
      _dob != null &&
      _phoneController.text.replaceAll(' ', '').length >= 8;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Widget _flagWidget(Map<String, String> country) {
    final asset = country['asset'];
    if (asset != null) {
      return SvgPicture.asset(asset, width: 24, height: 16, semanticsLabel: '${country['name']} flag');
    }
    return Text(country['flag']!, style: const TextStyle(fontSize: 18));
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 18),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      );

  BoxDecoration get _fieldDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
        color: AppColors.inputBackground,
      );

  Widget _genderChip(String value, IconData icon) {
    final selected = _sex == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _sex = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
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
                Row(children: [
                  IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_ios, size: 20)),
                  const Spacer(),
                ]),
                const SizedBox(height: 8),
                const Center(child: HiraalLogo(size: 56)),
                const SizedBox(height: 20),
                const Center(
                  child: Text('Create your account',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Sign up to get started. You can choose a plan\nright after verifying your number.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                ),

                _label('Full Name'),
                Container(
                  decoration: _fieldDecoration,
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),

                _label('Gender'),
                Row(children: [
                  _genderChip('Male', Icons.male),
                  const SizedBox(width: 12),
                  _genderChip('Female', Icons.female),
                ]),

                _label('Date of Birth'),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: _fieldDecoration,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _dob == null ? 'Select your date of birth' : DateFormat('d MMMM yyyy').format(_dob!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _dob == null ? AppColors.textTertiary : AppColors.textPrimary,
                        ),
                      ),
                    ]),
                  ),
                ),

                _label('Mobile Number'),
                Container(
                  decoration: _fieldDecoration,
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _countryCodes
                              .indexWhere((c) => c['code'] == _selectedCountryCode && c['flag'] == _selectedFlag),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
                          isDense: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          borderRadius: BorderRadius.circular(12),
                          menuMaxHeight: 350,
                          selectedItemBuilder: (context) => _countryCodes.map((country) {
                            return Row(mainAxisSize: MainAxisSize.min, children: [
                              _flagWidget(country),
                              const SizedBox(width: 6),
                              Text(country['code']!,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ]);
                          }).toList(),
                          items: _countryCodes.asMap().entries.map((entry) {
                            final country = entry.value;
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Row(children: [
                                _flagWidget(country),
                                const SizedBox(width: 8),
                                Text(country['code']!,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(country['name']!,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
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
                    Container(width: 1, height: 30, color: AppColors.inputBorder),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ]),
                ),

                _label('Email (optional)'),
                Container(
                  decoration: _fieldDecoration,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 24),
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (provider.errorMessage == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(provider.errorMessage!,
                                style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                          ),
                        ]),
                      ),
                    );
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
                            ? () => widget.onCreateAccount(
                                  _nameController.text.trim(),
                                  '$_selectedCountryCode${_phoneController.text}',
                                  _sex!,
                                  DateFormat('yyyy-MM-dd').format(_dob!),
                                  _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isValid && !isLoading ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Create Account'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: widget.onBack,
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account?  ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
