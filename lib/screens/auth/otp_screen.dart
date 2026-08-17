import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/otp_delivery.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  /// Where the initial code was delivered (SMS, or email fallback).
  final OtpDelivery delivery;

  /// The delivery channel the user chose ('sms' or 'email'); reused on resend.
  final String channel;

  /// Verifies [code] with the backend. Returns null on success, or an error
  /// message to display on failure. The parent owns the single verification so
  /// the one-time code is never consumed twice.
  final Future<String?> Function(String code) onVerified;
  final VoidCallback onBack;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.delivery = const OtpDelivery(),
    this.channel = 'sms',
    required this.onVerified,
    required this.onBack,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _currentCode = '';
  final TextEditingController _pinController = TextEditingController();
  int _resendTimer = AppConstants.otpResendSeconds;
  bool _canResend = false;
  bool _isVerifying = false;
  late OtpDelivery _delivery;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    _startResendTimer();
  }

  // Note: _pinController is passed to PinCodeTextField, which disposes it
  // itself. Disposing it here too would double-dispose, so we don't.

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) _resendTimer--;
        // Enable resend the moment the counter reaches zero. (Previously the
        // loop exited on reaching 0 before _canResend was ever set, so it stuck
        // at "Resend in 0s".)
        if (_resendTimer == 0) _canResend = true;
      });
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (_currentCode.length != AppConstants.otpLength || _isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      // The parent performs the single backend verification. Verifying here
      // as well would consume the one-time code and make the real attempt
      // fail with "Invalid or expired OTP".
      final error = await widget.onVerified(_currentCode);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verificationFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Always release the spinner, even if the callback threw.
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resendTimer = AppConstants.otpResendSeconds;
      _canResend = false;
      // Clear the previously entered code so the user can type the new one.
      _pinController.clear();
      _currentCode = '';
    });
    _startResendTimer();

    final result = await ServiceLocator.instance.auth.resendOtp(widget.phoneNumber, channel: widget.channel);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    if (result case Success(data: final delivery)) {
      setState(() => _delivery = delivery);
    }

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? l10n.failedToResendOtp),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_delivery.isEmail
              ? l10n.codeResentEmail
              : l10n.otpResentSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - bottomInset),
                child: IntrinsicHeight(
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
                      Text(
                        l10n.verifyYourAccount,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _delivery.isEmail
                            ? l10n.otpSentEmail
                            : l10n.otpSentSms,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _delivery.isEmail
                                  ? (_delivery.sentTo ?? l10n.yourEmailFallback)
                                  : widget.phoneNumber,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onBack,
                            child: Text(
                              l10n.edit,
                              style: const TextStyle(
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.enterSixDigitCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PinCodeTextField(
                        appContext: context,
                        controller: _pinController,
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
                          Text(
                            '${l10n.didntReceiveCode} ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendOtp : null,
                            child: Text(
                              _canResend
                                  ? l10n.resend
                                  : l10n.resendInSeconds(_resendTimer),
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
                          Flexible(
                            child: Text(
                              l10n.otpExpiresInMinutes(AppConstants.otpExpiryMinutes),
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
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
                              : Text(l10n.verifyAndContinue),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
