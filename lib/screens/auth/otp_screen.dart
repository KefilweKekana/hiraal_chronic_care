import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final ValueChanged<String> onVerified;
  final VoidCallback onBack;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
    required this.onBack,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _currentCode = '';
  int _resendTimer = AppConstants.otpResendSeconds;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (_currentCode.length != AppConstants.otpLength || _isVerifying) return;
    setState(() => _isVerifying = true);

    final result = await ServiceLocator.instance.auth.verifyOtp(
      widget.phoneNumber,
      _currentCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.isSuccess) {
      widget.onVerified(_currentCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'OTP verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resendTimer = AppConstants.otpResendSeconds;
      _canResend = false;
    });
    _startResendTimer();

    final result = await ServiceLocator.instance.auth.resendOtp(widget.phoneNumber);
    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to resend OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const HiraalLogo(size: 50),
              const SizedBox(height: 24),
              const Text(
                'Verify your phone number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We've sent a 6-digit code to",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter 6-digit code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PinCodeTextField(
                appContext: context,
                length: AppConstants.otpLength,
                animationType: AnimationType.fade,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.inputBackground,
                  selectedFillColor: AppColors.primaryLight,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.inputBorder,
                  selectedColor: AppColors.primary,
                  borderWidth: 1.5,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _currentCode = value;
                  });
                },
                onCompleted: (value) {
                  setState(() {
                    _currentCode = value;
                  });
                  _verifyOtp();
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canResend ? _resendOtp : null,
                    child: Text(
                      _canResend
                          ? 'Resend'
                          : 'Resend in ${_resendTimer.toString().padLeft(2, '0')}:${00.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _canResend
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'For your security, this code will expire in ${AppConstants.otpExpiryMinutes} minutes',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _currentCode.length == AppConstants.otpLength && !_isVerifying
                      ? _verifyOtp
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentCode.length == AppConstants.otpLength && !_isVerifying
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify & Continue'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
