import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';

/// First-time (or legacy) 4-digit health PIN create + confirm.
class CreateHealthPinScreen extends StatefulWidget {
  final VoidCallback? onCreated;
  final bool allowBack;
  final bool changingExisting;

  const CreateHealthPinScreen({
    super.key,
    this.onCreated,
    this.allowBack = false,
    this.changingExisting = false,
  });

  @override
  State<CreateHealthPinScreen> createState() => _CreateHealthPinScreenState();
}

class _CreateHealthPinScreenState extends State<CreateHealthPinScreen> {
  final _first = TextEditingController();
  final _confirm = TextEditingController();
  final _current = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  String _currentPin = '';
  bool _confirming = false;
  bool _saving = false;
  bool _needCurrent = false;

  @override
  void initState() {
    super.initState();
    _needCurrent = widget.changingExisting;
  }

  @override
  void dispose() {
    // PinCodeTextField disposes the controllers it is given.
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_pin.length != AppConstants.healthPinLength ||
        _confirmPin.length != AppConstants.healthPinLength) {
      return;
    }
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.healthPinMismatch), backgroundColor: AppColors.error),
      );
      setState(() {
        _confirming = false;
        _confirmPin = '';
        _pin = '';
      });
      _first.clear();
      _confirm.clear();
      return;
    }
    setState(() => _saving = true);
    final result = await ServiceLocator.instance.healthPin.setHealthPin(
      _pin,
      currentPin: widget.changingExisting ? _currentPin : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        if (widget.onCreated != null) {
          widget.onCreated!();
        } else if (widget.allowBack) {
          Navigator.of(context).maybePop(true);
        } else {
          await context.read<AppProvider>().finishHealthPinSetup();
        }
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _needCurrent
        ? l10n.enterHealthPinTitle
        : _confirming
            ? l10n.confirmHealthPinTitle
            : l10n.createHealthPinTitle;
    final hint = _needCurrent
        ? l10n.enterHealthPinHint
        : _confirming
            ? l10n.confirmHealthPinHint
            : l10n.createHealthPinHint;
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: widget.allowBack
          ? AppBar(title: Text(l10n.healthPinTitle), elevation: 0)
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: widget.allowBack ? 16 : 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.of(context).textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                key: ValueKey(_needCurrent ? 'current' : (_confirming ? 'confirm' : 'create')),
                appContext: context,
                controller: _needCurrent ? _current : (_confirming ? _confirm : _first),
                length: AppConstants.healthPinLength,
                obscureText: true,
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
                onChanged: (value) {
                  setState(() {
                    if (_needCurrent) {
                      _currentPin = value;
                    } else if (_confirming) {
                      _confirmPin = value;
                    } else {
                      _pin = value;
                    }
                  });
                },
                onCompleted: (value) {
                  if (_needCurrent) {
                    setState(() {
                      _currentPin = value;
                      _needCurrent = false;
                    });
                    return;
                  }
                  if (_confirming) {
                    _confirmPin = value;
                    _save();
                  } else {
                    setState(() {
                      _pin = value;
                      _confirming = true;
                      _confirmPin = '';
                    });
                    _confirm.clear();
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                l10n.healthPinProtects,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (!_confirming && _pin.length == AppConstants.healthPinLength) {
                            setState(() => _confirming = true);
                            return;
                          }
                          _save();
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_confirming ? l10n.healthPinSave : l10n.continueLabel),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
