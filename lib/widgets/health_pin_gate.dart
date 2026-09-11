import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/result.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/health_pin_controller.dart';
import '../screens/auth/create_health_pin_screen.dart';
import '../screens/auth/health_pin_unlock.dart';
import '../services/service_locator.dart';

/// Patient whose PIN is required for the current surface.
String healthPinPatientId(BuildContext context, {String? patientId}) {
  if (patientId != null && patientId.isNotEmpty) return patientId;
  final provider = context.read<AppProvider>();
  if (provider.isCaregiverMode) {
    final loved = provider.activeCarePerson?.patient ?? '';
    if (loved.isNotEmpty) return loved;
  }
  return provider.patient?.id ?? '';
}

/// Prompt for the health PIN (or create / ask-patient) before opening a screen.
Future<bool> ensureHealthPinUnlocked(
  BuildContext context, {
  String? patientId,
}) async {
  final id = healthPinPatientId(context, patientId: patientId);
  if (id.isEmpty) return false;
  final session = context.read<HealthPinController>();
  if (session.isUnlocked(id)) return true;

  final provider = context.read<AppProvider>();
  final caregiver = provider.isCaregiverMode && id != (provider.patient?.id ?? '');

  final has = await ServiceLocator.instance.healthPin.hasHealthPin(patient: id);
  var hasPin = true;
  if (has case Success(data: final flag)) {
    hasPin = flag;
  }

  if (!context.mounted) return false;

  if (!hasPin && !caregiver) {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateHealthPinScreen(
          allowBack: true,
          onCreated: () {
            session.markUnlocked(id);
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
    return created == true;
  }

  final unlocked = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => HealthPinUnlockPage(
        patientId: id,
        isCaregiverView: caregiver,
        patientHasPin: hasPin,
      ),
    ),
  );
  return unlocked == true;
}

Future<void> pushAfterHealthPin(
  BuildContext context,
  Widget screen, {
  String? patientId,
}) async {
  final ok = await ensureHealthPinUnlocked(context, patientId: patientId);
  if (!ok || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

Future<bool> openHealthHistoryTab(BuildContext context, {String? patientId}) async {
  final ok = await ensureHealthPinUnlocked(context, patientId: patientId);
  if (!ok || !context.mounted) return false;
  context.read<AppProvider>().setTab(2);
  return true;
}

/// Hides clinical content in an IndexedStack tab until the PIN session is open.
class HealthPinLockedPane extends StatelessWidget {
  final Widget child;
  final String? patientId;

  const HealthPinLockedPane({super.key, required this.child, this.patientId});

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final id = healthPinPatientId(context, patientId: patientId);
    final unlocked = context.watch<HealthPinController>().isUnlocked(id);
    if (unlocked) return child;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.healthPinRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.of(context).text),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => ensureHealthPinUnlocked(context, patientId: id),
                    child: Text(l10n.healthPinUnlock),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Named-route wrapper: unlock first, pop if the user cancels.
class HealthPinRoute extends StatefulWidget {
  final Widget child;

  const HealthPinRoute({super.key, required this.child});

  @override
  State<HealthPinRoute> createState() => _HealthPinRouteState();
}

class _HealthPinRouteState extends State<HealthPinRoute> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await ensureHealthPinUnlocked(context);
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).maybePop();
        return;
      }
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
