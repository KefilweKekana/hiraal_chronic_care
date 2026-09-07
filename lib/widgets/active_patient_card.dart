import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';

class ActivePatientCard extends StatelessWidget {
  final VoidCallback? onChange;

  const ActivePatientCard({super.key, this.onChange});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final person = provider.activeCarePerson;
    final people = provider.peopleICareFor;
    final name = person?.patientName ?? l10n.choosePerson;
    final rel = person?.relationship ?? '';
    final plan = person?.plan ?? '';
    final subtitle = [
      if (rel.isNotEmpty) rel,
      if (plan.isNotEmpty) plan,
    ].join(' • ');
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    if (people.length > 1) {
      return SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: people.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final p = people[i];
            final selected = provider.activeCarePerson?.patient == p.patient;
            final chipName = p.patientName;
            final chipInitials = chipName
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0])
                .take(2)
                .join()
                .toUpperCase();
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                provider.setActiveCarePerson(p);
                onChange?.call();
              },
              child: Container(
                width: 148,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySurface : AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border(context),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            chipInitials.isEmpty ? '?' : chipInitials,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        const Spacer(),
                        if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chipName.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      [p.relationship, p.plan].where((e) => (e ?? '').isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted(context)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                await _pickPerson(context, provider, l10n);
                onChange?.call();
              },
              child: Text(l10n.change),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPerson(
    BuildContext context,
    AppProvider provider,
    AppLocalizations l10n,
  ) async {
    final people = provider.peopleICareFor;
    if (people.isEmpty) {
      await provider.refreshPeopleICareFor();
    }
    if (!context.mounted) return;
    final list = provider.peopleICareFor;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.peopleICareFor,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Text(l10n.noPeopleYet, style: TextStyle(color: AppColors.textMuted(ctx))),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    minVerticalPadding: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: provider.activeCarePerson?.patient == p.patient
                            ? AppColors.primary
                            : AppColors.border(ctx),
                      ),
                    ),
                    title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [p.relationship, p.plan].where((e) => (e ?? '').isNotEmpty).join(' • '),
                    ),
                    onTap: () {
                      provider.setActiveCarePerson(p);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
