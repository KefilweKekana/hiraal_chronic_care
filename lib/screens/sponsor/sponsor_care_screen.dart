import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../services/service_locator.dart';
import 'sponsor_connection_active_screen.dart';
import 'sponsor_connection_sent_screen.dart';
import 'sponsor_patient_screen.dart';

class SponsorCareScreen extends StatefulWidget {
  const SponsorCareScreen({super.key});

  @override
  State<SponsorCareScreen> createState() => _SponsorCareScreenState();
}

class _SponsorCareScreenState extends State<SponsorCareScreen> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);

  final _queryCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _connectionCountryCtrl = TextEditingController(text: '+252');
  final _connectionNumberCtrl = TextEditingController();

  bool _searching = false;
  bool _redeeming = false;
  bool _requesting = false;
  String _relationship = 'Mother';
  List<SponsorPatientMatch> _matches = const [];

  @override
  void dispose() {
    _controller.dispose();
    _queryCtrl.dispose();
    _codeCtrl.dispose();
    _connectionCountryCtrl.dispose();
    _connectionNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context);
    if (_queryCtrl.text.trim().isEmpty) {
      _snack(l10n.enterSearchTerm, error: true);
      return;
    }
    setState(() => _searching = true);
    final result = await ServiceLocator.instance.caregivers.findPatientForSponsor(_queryCtrl.text.trim());
    if (!mounted) return;
    setState(() => _searching = false);
    switch (result) {
      case Success(data: final data):
        setState(() => _matches = data);
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  Future<void> _redeem() async {
    final l10n = AppLocalizations.of(context);
    if (_codeCtrl.text.trim().isEmpty) {
      _snack(l10n.enterInvitationCode, error: true);
      return;
    }
    setState(() => _redeeming = true);
    final result = await ServiceLocator.instance.caregivers.redeemInvitationCode(_codeCtrl.text.trim());
    if (!mounted) return;
    setState(() => _redeeming = false);
    switch (result) {
      case Success(data: final link):
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SponsorConnectionActiveScreen(link: link)),
        );
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  Future<void> _requestConnection() async {
    final l10n = AppLocalizations.of(context);
    if (_connectionNumberCtrl.text.trim().length < 7) {
      _snack(l10n.whatsappRequired, error: true);
      return;
    }
    setState(() => _requesting = true);
    final result = await ServiceLocator.instance.caregivers.requestSponsorConnection(
      countryCode: _connectionCountryCtrl.text.trim(),
      whatsappNumber: _connectionNumberCtrl.text.trim(),
      relationship: _relationship,
    );
    if (!mounted) return;
    setState(() => _requesting = false);
    switch (result) {
      case Success():
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SponsorConnectionSentScreen(
              whatsappNumber:
                  '${_connectionCountryCtrl.text.trim()} ${_connectionNumberCtrl.text.trim()}'.trim(),
            ),
          ),
        );
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final relationships = <String>[
      l10n.relationshipMother,
      l10n.relationshipFather,
      l10n.relationshipBrother,
      l10n.relationshipSister,
      l10n.relationshipSpouse,
      l10n.relationshipChild,
      l10n.relationshipFriend,
      l10n.relationshipOther,
    ];
    if (!relationships.contains(_relationship)) {
      _relationship = relationships.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sponsorCareTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _controller,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.findPatientTab),
            Tab(text: l10n.connectByWhatsappTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(
                title: l10n.findPatientTitle,
                body: l10n.findPatientHint,
                icon: Icons.favorite_outline,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _queryCtrl,
                decoration: InputDecoration(
                  labelText: l10n.phoneOrMemberId,
                  hintText: l10n.phoneOrMemberIdHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: _searching ? null : _search,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searching ? null : _search,
                  child: Text(l10n.findPatientButton),
                ),
              ),
              const SizedBox(height: 18),
              Text(l10n.redeemInvitationCodeTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.invitationCode,
                  hintText: l10n.invitationCodeHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _redeeming ? null : _redeem,
                  child: _redeeming
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.redeemCodeButton),
                ),
              ),
              const SizedBox(height: 18),
              if (_matches.isNotEmpty)
                ..._matches.map(
                  (match) => _PatientMatchCard(
                    match: match,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SponsorPatientScreen(match: match)),
                      );
                    },
                  ),
                )
              else
                _EmptyCard(
                  title: l10n.noPatientsFound,
                  subtitle: l10n.noPatientsFoundHint,
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(
                title: l10n.connectByWhatsappTitle,
                body: l10n.connectByWhatsappHint,
                icon: Icons.chat_bubble_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _connectionCountryCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.countryCode,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _connectionNumberCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.whatsappNumber,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: InputDecoration(
                  labelText: l10n.relationship,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: relationships
                    .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _relationship = value);
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _requestConnection,
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(l10n.sendConnectionRequest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientMatchCard extends StatelessWidget {
  final SponsorPatientMatch match;
  final VoidCallback onTap;

  const _PatientMatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                match.patientName.isNotEmpty ? match.patientName[0] : 'P',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l10n.memberId(match.patientId), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(match.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
