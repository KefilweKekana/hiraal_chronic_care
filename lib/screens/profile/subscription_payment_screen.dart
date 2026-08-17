import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../services/payment_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/payment_views.dart';

/// Pay the care subscription with mobile money (WaafiPay / eDahab).
/// Pick a method → enter wallet number → approve the prompt on the phone.
class SubscriptionPaymentScreen extends StatefulWidget {
  /// The amount to display (the subscription's monthly fee). The server always
  /// charges the real fee; this is for accurate on-screen text.
  final double? amount;
  final String? planName;

  const SubscriptionPaymentScreen({super.key, this.amount, this.planName});

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

enum _Stage { form, waiting, success, failed }

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  List<PaymentMethodOption> _methods = [];
  PaymentMethodOption? _selected;
  bool _loadingMethods = true;
  String? _methodsError;

  _Stage _stage = _Stage.form;
  bool _busy = false;
  String? _txn;

  double get _amount => widget.amount ?? AppConstants.standardPlanPrice;
  String _message = '';
  Timer? _pollTimer;
  int _polls = 0;
  bool _pollInFlight = false;
  StreamSubscription? _pushSub;

  /// Matches the 80-poll × 3s budget in [_pollOnce] (~4 minutes).
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
    _pushSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    setState(() { _loadingMethods = true; _methodsError = null; });
    final result = await ServiceLocator.instance.payments.getMethods();
    if (!mounted) return;
    // Wallet remembered from the last payment (best-effort pre-fill).
    String? savedPhone, savedProvider, savedMethod;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedPhone = prefs.getString('wallet_phone');
      savedProvider = prefs.getString('wallet_provider');
      savedMethod = prefs.getString('wallet_method');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loadingMethods = false;
      switch (result) {
        case Success(data: final m):
          _methods = m;
          _selected = m.isNotEmpty ? m.first : null;
          if (savedPhone != null && savedPhone.isNotEmpty) {
            _phoneCtrl.text = savedPhone;
          }
          if (savedProvider != null && savedMethod != null) {
            for (final option in m) {
              if (option.provider == savedProvider && option.method == savedMethod) {
                _selected = option;
                break;
              }
            }
          }
          if (m.isEmpty) _methodsError = 'Mobile payments are not available yet.';
        case Failure(message: final msg):
          _methodsError = msg;
      }
    });
  }

  /// Remember the wallet so the patient never retypes their number.
  Future<void> _rememberWallet(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_phone', phone);
      await prefs.setString('wallet_provider', _selected!.provider);
      await prefs.setString('wallet_method', _selected!.method);
    } catch (_) {
      // Best-effort only — never block or break the pay flow on storage.
    }
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (_selected == null) { _snack('Choose a payment method.'); return; }
    if (phone.replaceAll(' ', '').length < 7) { _snack('Enter your mobile-money number.'); return; }

    await _rememberWallet(phone);
    if (!mounted) return;

    // The wallet gateway holds the pay request open until the customer
    // approves or declines on their phone — so the waiting view starts NOW,
    // not after the server answers.
    setState(() {
      _busy = true;
      _stage = _Stage.waiting;
      _message = 'Taking longer than usual. If you approved the request, '
          'your payment will be confirmed automatically within a few '
          'minutes — you can close this screen and check back later.';
    });
    _startCountdown();
    _pulse.repeat();

    final result = await ServiceLocator.instance.payments.paySubscription(
      provider: _selected!.provider, method: _selected!.method, phone: phone,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    // The user may have cancelled while the request was in flight.
    if (_stage != _Stage.waiting) return;
    switch (result) {
      case Success(data: final txn):
        _txn = txn;
        _listenForPushCompletion();
        _startPolling();
      case Failure(message: final msg):
        _stopWaiting();
        setState(() { _stage = _Stage.failed; _message = msg; });
    }
  }

  void _listenForPushCompletion() {
    try {
      _pushSub?.cancel();
      _pushSub = PushNotificationService.instance.paymentCompleteStream.listen((data) {
        final type = data['type'];
        if (type == 'subscription_payment_complete' && mounted) {
          _stopWaiting();
          setState(() => _stage = _Stage.success);
        }
      });
    } catch (e) {
      // Push isn't available (web build / no Play Services): the singleton
      // touches FirebaseMessaging and throws. Polling still covers us.
      log.w('Push completion listener unavailable', error: e);
    }
  }

  void _startPolling() {
    _polls = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      // A slow network can outlast the 3s tick — skip while a poll is running.
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

  /// Stop everything that drives the waiting view: status polling, the
  /// countdown, and the pulse animation.
  void _stopWaiting() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulse.stop();
  }

  Future<void> _pollOnce(Timer t) async {
    _polls++;
    final txn = _txn;
    if (txn == null) { t.cancel(); return; }
    final result = await ServiceLocator.instance.payments.checkStatus(txn);
    if (!mounted) { t.cancel(); return; }
    if (result case Success(data: final status)) {
      if (status == 'Completed') {
        _stopWaiting();
        setState(() { _stage = _Stage.success; });
      } else if (status == 'Failed') {
        _stopWaiting();
        setState(() { _stage = _Stage.failed; _message = 'The payment was declined or cancelled.'; });
      }
    }
    // Wallet approvals can outlast this screen: after ~4 minutes stop
    // polling and reassure — the server reconciles the payment automatically
    // once it completes, even with the app closed.
    if (_polls >= 80) {
      t.cancel();
      if (mounted) {
        setState(() {
          _message = 'Taking longer than usual. If you approved the request, '
              'your payment will be confirmed automatically within a few '
              'minutes — you can close this screen and check back later.';
        });
      }
    }
  }

  Future<void> _checkOnce() async {
    final txn = _txn;
    if (txn == null) return;
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.payments.checkStatus(txn);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Success(data: final status)) {
      if (status == 'Completed') {
        _stopWaiting();
        setState(() => _stage = _Stage.success);
      } else if (status == 'Failed') {
        _stopWaiting();
        setState(() { _stage = _Stage.failed; _message = 'The payment was declined or cancelled.'; });
      } else {
        _snack('Still pending — approve the prompt on your phone.');
      }
    }
  }

  void _snack(String m, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: error ? AppColors.error : AppColors.textSecondary),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription Payment'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: switch (_stage) {
        _Stage.waiting => PaymentWaitingView(
            pulse: _pulse,
            amountText: '${AppConstants.currencySymbol}${_amount.toStringAsFixed(2)}',
            methodLabel: _selected?.label ?? 'your mobile money app',
            phone: _phoneCtrl.text.trim(),
            secondsLeft: _secondsLeft,
            expiredMessage: _message,
            busy: _busy,
            onCheckNow: _checkOnce,
            onCancel: () {
              _stopWaiting();
              _pushSub?.cancel();
              setState(() {
                _stage = _Stage.form;
                _txn = null;
              });
            },
          ),
        _Stage.success => PaymentResultView.success(
            subtitle: 'Your subscription is active. Thank you!',
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
        _ => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _formView(),
          ),
      },
    );
  }

  Widget _amountCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.planName ?? 'Care subscription', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('${AppConstants.currencySymbol}${_amount.toStringAsFixed(2)} / month',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      );

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _amountCard(),
        const SizedBox(height: 20),
        const Text('Pay with', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_loadingMethods)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (_methodsError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.inputBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.inputBorder)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(_methodsError!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              TextButton(onPressed: _loadMethods, child: const Text('Retry')),
            ]),
          )
        else
          ..._methods.map((m) => RadioListTile<PaymentMethodOption>(
                value: m,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
                title: Text(m.label),
                subtitle: Text(m.provider, style: const TextStyle(fontSize: 12)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        const SizedBox(height: 12),
        const Text('Mobile-money number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
          decoration: InputDecoration(
            hintText: 'e.g. 252612345678',
            prefixIcon: const Icon(Icons.phone_iphone, color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_busy || _selected == null) ? null : _pay,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : Text('Pay ${AppConstants.currencySymbol}${_amount.toStringAsFixed(2)}'),
          ),
        ),

      ],
    );
  }
}
