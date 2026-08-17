import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ContactCareTeamScreen extends StatelessWidget {
  const ContactCareTeamScreen({super.key});

  Future<void> _openComposer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      // Dispose the controller once the sheet closes, however it closes.
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(l10n.messageCareTeam, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.describeYourConcern,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(l10n.sendMessage),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageSentSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(l10n.careTeamCall),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.support_agent, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 12),
            Text(l10n.youreCalling, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(l10n.careTeamNurse, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(l10n.wereHereToHelp, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            // Info rows
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.expectedWaitTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(l10n.lessThan2Minutes, style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 18, color: AppColors.success),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.availableHours, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(l10n.availableHoursValue, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.careTeamCanSeeReadings,
                      style: const TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Recent concern
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recentConcern, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.highBloodPressureTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const Text('Today, 8:30 AM • 162/98 mmHg', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      Text(l10n.viewAction, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Call controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: const Icon(Icons.call_end, color: AppColors.white, size: 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.endCall, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                Column(
                  children: [
                    Text(l10n.callingStatus, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(3, (_) => Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.speakerToggled), duration: const Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.volume_up, color: AppColors.textPrimary, size: 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.speaker, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: GestureDetector(
                onTap: () => _openComposer(context),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(l10n.preferToMessage, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(l10n.sendMessageArrow, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
