import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/age_dob.dart';
import '../l10n/app_localizations.dart';

/// Integer age field. The corresponding DOB (1 January of year − age) is
/// derived on submit via [AgeDob] and is not shown to the user.
class AgeInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// When true, uses the signup boxed field (no Material label).
  /// When false, uses the themed labelled field (family-member forms).
  final bool boxed;

  const AgeInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.boxed = false,
  });

  String? _errorText(AppLocalizations l10n) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    if (AgeDob.parseAge(raw) == null) return l10n.ageInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _errorText(l10n);
    final field = TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onChanged: onChanged,
      decoration: boxed
          ? InputDecoration(
              hintText: l10n.ageHint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            )
          : InputDecoration(
              labelText: l10n.age,
              hintText: l10n.ageHint,
              errorText: error,
            ),
      style: TextStyle(
        fontSize: 16,
        color: boxed ? AppColors.of(context).text : AppColors.text(context),
      ),
    );

    if (!boxed) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 18),
          child: Text(
            l10n.age,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.of(context).inputBorder,
            ),
            color: AppColors.of(context).inputFill,
          ),
          child: field,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error,
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
