import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medicine_order.dart';
import '../../models/subscription.dart';
import '../../services/service_locator.dart';
import '../../widgets/skeleton.dart';

/// Unified payment history: care-subscription payments and paid medicine
/// orders, newest first. Tapping a payment opens a shareable receipt.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

/// One row in the unified payment list (subscription payment or paid order).
class _PaymentEntry {
  final String title;
  final double amount;
  final DateTime? date;
  final String status;
  final String? reference;

  const _PaymentEntry({
    required this.title,
    required this.amount,
    required this.status,
    this.date,
    this.reference,
  });
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<_PaymentEntry> _entries = [];
  bool _loading = true;
  String? _error;

  String get _cur => AppConstants.currencySymbol;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final subResult = await ServiceLocator.instance.payments.getSubscription();
    final ordResult = await ServiceLocator.instance.bookings.getMyOrders();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      switch (subResult) {
        case Success(data: final info):
          switch (ordResult) {
            case Success(data: final orders):
              _entries = _merge(l10n, info.history, orders);
            case Failure(message: final msg):
              _error = msg;
          }
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  /// Combine subscription payments and paid orders, newest first.
  List<_PaymentEntry> _merge(AppLocalizations l10n, List<SubscriptionPayment> history, List<MedicineOrder> orders) {
    final entries = <_PaymentEntry>[
      for (final p in history)
        _PaymentEntry(
          title: l10n.careSubscription,
          amount: p.amount,
          date: p.date,
          status: p.status ?? l10n.paid,
          reference: p.reference,
        ),
      for (final o in orders)
        if (o.isPaid)
          _PaymentEntry(
            title: l10n.orderTitle(o.id),
            amount: o.amountDue,
            date: o.createdAt,
            status: l10n.paid,
            reference: o.paymentReference,
          ),
    ];
    entries.sort((a, b) {
      final ad = a.date, bd = b.date;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1; // undated entries sink to the bottom
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.payments),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const SkeletonList(itemCount: 6)
          : _error != null
              ? _buildError(l10n)
              : _entries.isEmpty
                  ? _buildEmpty(l10n)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _paymentRow(l10n, _entries[i]),
                      ),
                    ),
    );
  }

  Widget _buildError(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );

  Widget _buildEmpty(AppLocalizations l10n) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.receipt_long, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Center(child: Text(l10n.noPaymentsYet, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            Center(child: Text(l10n.paymentsEmptyHint,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ],
        ),
      );

  Widget _paymentRow(AppLocalizations l10n, _PaymentEntry e) {
    return InkWell(
      onTap: () => _showReceipt(l10n, e),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    e.date != null ? DateFormat('MMM dd, yyyy').format(e.date!) : '—',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Text('$_cur${e.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: () => _showReceipt(l10n, e),
              icon: const Icon(Icons.ios_share, size: 18, color: AppColors.textTertiary),
              tooltip: l10n.paymentReceipt,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // ── receipt ────────────────────────────────────────────
  String _fmtDate(DateTime? d) => d != null ? DateFormat('MMM dd, yyyy').format(d) : '—';

  void _showReceipt(AppLocalizations l10n, _PaymentEntry e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.paymentReceipt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _receiptRow(l10n.item, e.title),
              _receiptRow(l10n.reference, e.reference ?? '—'),
              _receiptRow(l10n.date, _fmtDate(e.date)),
              _receiptRow(l10n.amount, '$_cur${e.amount.toStringAsFixed(2)}'),
              _receiptRow(l10n.status, e.status),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _shareReceipt(e),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(l10n.shareReceipt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Flexible(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Future<void> _shareReceipt(_PaymentEntry e) async {
    final text = StringBuffer()
      ..writeln('Hiraal Lifecare payment receipt')
      ..writeln('Item: ${e.title}')
      ..writeln('Reference: ${e.reference ?? '—'}')
      ..writeln('Date: ${_fmtDate(e.date)}')
      ..writeln('Amount: $_cur${e.amount.toStringAsFixed(2)}')
      ..writeln('Status: ${e.status}');
    try {
      await Share.share(text.toString(), subject: 'Hiraal Lifecare payment receipt');
    } catch (_) {
      // Sharing can fail on platforms without a share target (e.g. web).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is not available on this device.')),
        );
      }
    }
  }
}
