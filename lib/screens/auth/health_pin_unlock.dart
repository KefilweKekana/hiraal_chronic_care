import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/otp_wait.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/health_pin_controller.dart';
import '../../services/service_locator.dart';
import 'create_health_pin_screen.dart';

/// Unlock, forgot-PIN (OTP reset), and caregiver "ask the patient" flows.
class HealthPinUnlockPage extends StatefulWidget {
  final String patientId;
  final bool isCaregiverView;
  final bool patientHasPin;

  const HealthPinUnlockPage({
    super.key,
    required this.patientId,
    this.isCaregiverView = false,
    this.patientHasPin = true,
  });

  @override
  State<HealthPinUnlockPage> createState() => _HealthPinUnlockPageState();
}

class _HealthPinUnlockPageState extends State<HealthPinUnlockPage> {
  final _pinController = TextEditingController();
  String _code = '';
  bool _busy = false;
  String? _error;
  int _lockSeconds = 0;
  Timer? _lockTicker;

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  void _startLock(int seconds) {
    _lockTicker?.cancel();
    setState(() => _lockSeconds = seconds);
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_lockSeconds <= 1) {
        t.cancel();
        setState(() => _lockSeconds = 0);
      } else {
        setState(() => _lockSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length != AppConstants.healthPinLength || _busy || _lockSeconds > 0) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.healthPin.verifyHealthPin(
      _code,
      patient: widget.patientId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final data):
        if (data.ok) {
          context.read<HealthPinController>().markUnlocked(widget.patientId);
          Navigator.of(context).pop(true);
          return;
        }
        if (data.locked && data.retryAfter > 0) {
          _startLock(data.retryAfter);
        }
        if (data.hasPin == false && !widget.isCaregiverView) {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreateHealthPinScreen(
                allowBack: true,
                onCreated: () {
                  context.read<HealthPinController>().markUnlocked(widget.patientId);
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          );
          if (created == true && mounted) Navigator.of(context).pop(true);
          return;
        }
        setState(() => _error = data.message ?? AppLocalizations.of(context).healthPinWrong);
        _pinController.clear();
        _code = '';
      case Failure(message: final msg):
        final wait = parseOtpRetryAfterSeconds(msg);
        if (wait != null) _startLock(wait);
        setState(() => _error = msg);
        _pinController.clear();
        _code = '';
    }
  }

  Future<void> _forgot() async {
    if (widget.isCaregiverView) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ForgotHealthPinScreen(patientId: widget.patientId),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.isCaregiverView && !widget.patientHasPin) {
      return _AskPatientScaffold(l10n: l10n);
    }

    final locked = _lockSeconds > 0;
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        title: Text(l10n.enterHealthPinTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.enterHealthPinHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.of(context).textMuted, height: 1.45),
              ),
              if (widget.isCaregiverView) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.healthPinAskPatient,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.of(context).text),
                ),
              ],
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                controller: _pinController,
                length: AppConstants.healthPinLength,
                obscureText: true,
                enabled: !locked && !_busy,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                autoFocus: true,
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).text,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeFillColor: AppColors.of(context).card,
                  inactiveFillColor: AppColors.of(context).inputFill,
                  selectedFillColor: AppColors.of(context).primarySoft,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.of(context).inputBorder,
                  selectedColor: AppColors.primary,
                  borderWidth: 1.5,
                ),
                enableActiveFill: true,
                onChanged: (value) => setState(() => _code = value),
                onCompleted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              if (locked) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.healthPinLocked(formatOtpCountdown(_lockSeconds)),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.warning, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy || locked || _code.length != AppConstants.healthPinLength
                      ? null
                      : _verify,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(l10n.healthPinUnlock),
                ),
              ),
              if (!widget.isCaregiverView)
                TextButton(
                  onPressed: _busy ? null : _forgot,
                  child: Text(l10n.healthPinForgot),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.healthPinAskPatientHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskPatientScaffold extends StatelessWidget {
  final AppLocalizations l10n;

  const _AskPatientScaffold({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(title: Text(l10n.healthPinTitle), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.lock_person_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              l10n.healthPinAskPatient,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).text),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.healthPinNoPinYet,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.of(context).textMuted, height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OTP to the patient's phone, then a new 4-digit PIN.
class ForgotHealthPinScreen extends StatefulWidget {
  final String patientId;

  const ForgotHealthPinScreen({super.key, required this.patientId});

  @override
  State<ForgotHealthPinScreen> createState() => _ForgotHealthPinScreenState();
}

class _ForgotHealthPinScreenState extends State<ForgotHealthPinScreen> {
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String _otp = '';
  String _pin = '';
  String _confirm = '';
  bool _codeSent = false;
  bool _busy = false;
  int _resend = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _phone {
    final p = context.read<AppProvider>();
    return p.phoneNumber.isNotEmpty ? p.phoneNumber : (p.patient?.phone ?? '');
  }

  void _tickResend(int seconds) {
    _ticker?.cancel();
    setState(() => _resend = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resend <= 1) {
        t.cancel();
        setState(() => _resend = 0);
      } else {
        setState(() => _resend--);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.auth.requestOtp(_phone);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        setState(() => _codeSent = true);
        _tickResend(AppConstants.otpResendSeconds);
      case Failure(message: final msg):
        final wait = parseOtpRetryAfterSeconds(msg);
        if (wait != null) _tickResend(wait);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_otp.length != AppConstants.otpLength) return;
    if (_pin.length != AppConstants.healthPinLength || _pin != _confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.healthPinMismatch), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.healthPin.resetHealthPin(
      otp: _otp,
      newPin: _pin,
      mobile: _phone,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        context.read<HealthPinController>().markUnlocked(widget.patientId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.healthPinResetSuccess)),
        );
        Navigator.of(context).pop(true);
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(title: Text(l10n.healthPinResetTitle), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.healthPinResetHint, style: TextStyle(color: AppColors.of(context).textMuted, height: 1.45)),
              const SizedBox(height: 20),
              if (!_codeSent)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _sendCode,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(l10n.healthPinResetSendCode),
                  ),
                )
              else ...[
                Text(l10n.enterSixDigitCode, style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                PinCodeTextField(
                  appContext: context,
                  controller: _otpController,
                  length: AppConstants.otpLength,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  enableActiveFill: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 48,
                    fieldWidth: 42,
                    activeFillColor: AppColors.of(context).card,
                    inactiveFillColor: AppColors.of(context).inputFill,
                    selectedFillColor: AppColors.of(context).primarySoft,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.of(context).inputBorder,
                    selectedColor: AppColors.primary,
                  ),
                  onChanged: (v) => setState(() => _otp = v),
                ),
                if (_resend > 0)
                  Text(l10n.pleaseWaitBeforeAnotherCode(formatOtpCountdown(_resend)))
                else
                  TextButton(onPressed: _busy ? null : _sendCode, child: Text(l10n.resend)),
                const SizedBox(height: 12),
                Text(l10n.createHealthPinTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                PinCodeTextField(
                  appContext: context,
                  controller: _pinController,
                  length: AppConstants.healthPinLength,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  enableActiveFill: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 52,
                    fieldWidth: 52,
                    activeFillColor: AppColors.of(context).card,
                    inactiveFillColor: AppColors.of(context).inputFill,
                    selectedFillColor: AppColors.of(context).primarySoft,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.of(context).inputBorder,
                    selectedColor: AppColors.primary,
                  ),
                  onChanged: (v) => setState(() => _pin = v),
                ),
                Text(l10n.confirmHealthPinTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                PinCodeTextField(
                  appContext: context,
                  controller: _confirmController,
                  length: AppConstants.healthPinLength,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  enableActiveFill: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 52,
                    fieldWidth: 52,
                    activeFillColor: AppColors.of(context).card,
                    inactiveFillColor: AppColors.of(context).inputFill,
                    selectedFillColor: AppColors.of(context).primarySoft,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.of(context).inputBorder,
                    selectedColor: AppColors.primary,
                  ),
                  onChanged: (v) => setState(() => _confirm = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(l10n.healthPinSave),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
