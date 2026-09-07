import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/service_coverage.dart';
import '../screens/services/service_payment_screen.dart';
import 'coverage_outcome.dart';

/// Shows the spec's FREE confirmation or payment step, then the real
/// Zaad / eDahab charge when the plan does not cover the service.
Future<bool> presentServiceCoverage({
  required BuildContext context,
  required ServiceCoverage coverage,
  required String title,
  required String patient,
  required String serviceType,
}) async {
  final l10n = AppLocalizations.of(context);
  final acknowledged = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CoverageOutcomePage(
        coverage: coverage,
        title: coverage.covered ? l10n.confirm : title,
        onContinue: () => Navigator.pop(context, true),
        onPay: () => Navigator.pop(context, true),
      ),
    ),
  );
  if (acknowledged != true || !context.mounted) return false;
  if (coverage.covered || !coverage.paymentRequired || coverage.amount <= 0) {
    return true;
  }
  if (patient.isEmpty) return false;
  final paid = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => ServicePaymentScreen(
        patient: patient,
        serviceType: serviceType,
        amount: coverage.amount,
        currency: coverage.currency,
      ),
    ),
  );
  return paid == true;
}

String actingPatientId({required String? carePatient, required String? selfPatient}) {
  if (carePatient != null && carePatient.isNotEmpty) return carePatient;
  return selfPatient ?? '';
}
