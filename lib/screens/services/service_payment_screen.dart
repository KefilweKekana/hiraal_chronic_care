import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_number.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../services/payment_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/coverage_outcome.dart';
import '../../widgets/payment_views.dart';

/// Real Zaad / eDahab charge for a service that is not in the care plan.
class ServicePaymentScreen extends StatefulWidget {
  final String patient;
  final String serviceType;
  final double amount;
  final String currency;

  const ServicePaymentScreen({
    super.key,
    required this.patient,
    required this.serviceType,
    required this.amount,
    this.currency = 'USD',
  });

  @override
  State<ServicePaymentScreen> createState() => _ServicePaymentScreenState();
}

enum _Stage { form, waiting, success, failed }

class _ServicePaymentScreenState extends State<ServicePaymentScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  List<PaymentMethodOption> _methods = [];
  PaymentMethodOption? _selected;
  bool _loadingMethods = true;
  String? _methodsError;

  _Stage _stage = _Stage.form;
  bool _busy = false;
  String? _txn;
  String _message = '';
  Timer? _pollTimer;
  int _polls = 0;
  bool _pollInFlight = false;
  static const int _waitSeconds = 240;
  Timer? _countdownTimer;
  int _secondsLeft = _waitSeconds;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _loadingMethods = true;
      _methodsError = null;
    });
    final result = await ServiceLocator.instance.payments.getMethods();
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('hiraal_last_wallet_phone');
      if (saved != null && saved.isNotEmpty && _phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = saved;
      }
    } catch (_) {}
    setState(() {
      _loadingMethods = false;
      switch (result) {
        case Success(data: final list):
          _methods = list;
          _selected = list.isNotEmpty ? list.first : null;
        case Failure(message: final msg):
          _methodsError = msg;
      }
    });
  }

  Future<void> _pay() async {
    final method = _selected;
    if (method == null) return;
    final phone = PhoneNumber.normalize(_phoneCtrl.text);
    if (phone.length < 9) return;
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.payments.payOutOfPlan(
      patient: widget.patient,
      serviceType: widget.serviceType,
      provider: method.provider,
      method: method.method,
      phone: phone,
      amount: widget.amount,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final txn):
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hiraal_last_wallet_phone', phone);
        } catch (_) {}
        if (txn == 'COVERED') {
          setState(() => _stage = _Stage.success);
          return;
        }
        _txn = txn;
        _pulse.repeat();
        _startCountdown();
        _startPoll();
        setState(() => _stage = _Stage.waiting);
      case Failure(message: final msg):
        setState(() {
          _stage = _Stage.failed;
          _message = msg;
        });
    }
  }

  void _startPoll() {
    _polls = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_pollInFlight) return;
      _pollInFlight = true;
      try {
        await _pollOnce(t);
      } finally {
        _pollInFlight = false;
      }
    });
  }

  void _startCountdown() {
    _secondsLeft = _waitSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        if (_secondsLeft == 0) t.cancel();
      });
    });
  }

  void _stopWaiting() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulse.stop();
  }

  Future<void> _pollOnce(Timer t) async {
    _polls++;
    final txn = _txn;
    if (txn == null) {
      t.cancel();
      return;
    }
    final result = await ServiceLocator.instance.payments.checkOutOfPlanStatus(txn);
    if (!mounted) {
      t.cancel();
      return;
    }
    if (result case Success(data: final status)) {
      if (status == 'Completed') {
        _stopWaiting();
        setState(() => _stage = _Stage.success);
      } else if (status == 'Failed') {
        _stopWaiting();
        setState(() {
          _stage = _Stage.failed;
          _message = 'The payment was declined or cancelled.';
        });
      }
    }
    if (_polls >= 80) {
      t.cancel();
      if (mounted) {
        setState(() {
          _message =
              'Taking longer than usual. If you approved the request, your payment will be confirmed automatically – you can close this screen and check back later.';
        });
      }
    }
  }

  Future<void> _checkOnce() async {
    final txn = _txn;
    if (txn == null) return;
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.payments.checkOutOfPlanStatus(txn);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Success(data: final status)) {
      if (status == 'Completed') {
        _stopWaiting();
        setState(() => _stage = _Stage.success);
      } else if (status == 'Failed') {
        _stopWaiting();
        setState(() {
          _stage = _Stage.failed;
          _message = 'The payment was declined or cancelled.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.outOfPlanPaymentTitle)),
      body: switch (_stage) {
        _Stage.waiting => PaymentWaitingView(
            pulse: _pulse,
            amountText: '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            methodLabel: _selected?.label ?? '',
            phone: _phoneCtrl.text.trim(),
            secondsLeft: _secondsLeft,
            expiredMessage: _message,
            busy: _busy,
            onCheckNow: _checkOnce,
            onCancel: () {
              _stopWaiting();
              setState(() {
                _stage = _Stage.form;
                _txn = null;
              });
            },
          ),
        _Stage.success => PaymentResultView.success(
            subtitle: l10n.paymentSuccessful,
            onDone: () => Navigator.pop(context, true),
          ),
        _Stage.failed => PaymentResultView.failure(
            reason: _message,
            onTryAgain: () => setState(() {
              _stage = _Stage.form;
              _txn = null;
            }),
            onBack: () => Navigator.pop(context, false),
          ),
        _ => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(l10n.payWith, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_loadingMethods)
                const Center(child: CircularProgressIndicator())
              else if (_methodsError != null)
                Text(_methodsError!, style: const TextStyle(color: AppColors.error))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _methods)
                      BigChoiceButton(
                        label: m.label,
                        subtitle: m.provider,
                        selected: _selected?.method == m.method && _selected?.provider == m.provider,
                        onTap: () => setState(() => _selected = m),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Text(l10n.mobileMoneyNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 252636197117',
                  prefixText: '',
                  prefixIcon: const Icon(Icons.phone_iphone),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_busy || _selected == null || widget.amount <= 0) ? null : _pay,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('${l10n.completePayment}  ${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}'),
                ),
              ),
            ],
          ),
      },
    );
  }
}
