import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medicine_order.dart';
import '../../services/service_locator.dart';
import 'order_payment_screen.dart';

/// Live tracking for a single medicine order. Shows the real status timeline
/// from the server, refreshes on pull-down, and lets the patient cancel while
/// the order is still cancellable.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final MedicineOrder? initial;

  const OrderTrackingScreen({super.key, required this.orderId, this.initial});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  MedicineOrder? _order;
  bool _loading = true;
  bool _cancelling = false;
  bool _confirming = false;
  String? _error;

  String get _currency => AppConstants.currencySymbol;

  @override
  void initState() {
    super.initState();
    _order = widget.initial;
    _loading = _order == null;
    _load();
  }

  Future<void> _load() async {
    final result = await ServiceLocator.instance.bookings.getMyOrders();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final orders):
          final match = orders.where((o) => o.id == widget.orderId);
          if (match.isNotEmpty) {
            _order = match.first;
            _error = null;
          } else if (_order == null) {
            _error = l10n.orderNotFound;
          }
        case Failure(message: final msg):
          if (_order == null) _error = msg;
      }
    });
  }

  String _localizedStatus(AppLocalizations l10n, MedicineOrder o) {
    if (o.isCancelled) return l10n.cancelled;
    switch (o.status) {
      case 'Awaiting Payment':
        return l10n.paymentPendingShort;
      case 'Out for Delivery':
        return l10n.outForDelivery;
      case 'Delivered':
        return l10n.delivered;
      case 'Paid':
        return l10n.paid;
      case 'Received':
        return l10n.stagePrescriptionReceived;
      case 'Under Review':
        return l10n.stageUnderReview;
      case 'Preparing':
        return l10n.stagePreparing;
      default:
        return o.status;
    }
  }

  String _localizedStatusLabel(AppLocalizations l10n, MedicineOrder o) {
    if (o.isCancelled) return l10n.cancelled;
    final i = o.stageIndex;
    if (i >= 0) return _stageLabel(l10n, i);
    return o.status;
  }

  String _stageLabel(AppLocalizations l10n, int i) {
    switch (i) {
      case 0:
        return l10n.stagePrescriptionReceived;
      case 1:
        return l10n.stageUnderReview;
      case 2:
        return l10n.stageAwaitingPayment;
      case 3:
        return l10n.stagePaymentConfirmed;
      case 4:
        return l10n.stagePreparing;
      case 5:
        return l10n.stageOutForDelivery;
      case 6:
        return l10n.stageDelivered;
      default:
        return MedicineOrder.stageLabels[i];
    }
  }

  Future<void> _confirmCancel() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderQuestion),
        content: Text(l10n.cancelOrderMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keepOrder)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelOrder, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    final result = await ServiceLocator.instance.bookings.cancelMedicineOrder(widget.orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    switch (result) {
      case Success():
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).cancelled), backgroundColor: AppColors.textSecondary),
          );
        }
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  Future<void> _payNow() async {
    final order = _order;
    if (order == null) return;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderPaymentScreen(order: order)),
    );
    if (!mounted) return;
    if (paid == true) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _confirmReceived() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmReceiptQuestion),
        content: Text(l10n.confirmReceiptMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notYet)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yesReceived),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _confirming = true);
    final result = await ServiceLocator.instance.bookings.confirmOrderReceived(widget.orderId);
    if (!mounted) return;
    setState(() => _confirming = false);
    switch (result) {
      case Success():
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).receiptConfirmedThanks), backgroundColor: AppColors.success),
          );
        }
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  Color _statusColor(MedicineOrder o) {
    if (o.isCancelled) return AppColors.error;
    if (o.isDelivered) return AppColors.success;
    if (o.status == 'Awaiting Payment') return AppColors.error;
    if (o.status == 'Out for Delivery' || o.status == 'Paid') return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.trackOrder),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_order == null)
              ? _buildError(l10n)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildBody(l10n, _order!),
                  ),
                ),
    );
  }

  Widget _buildError(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? l10n.somethingWentWrong,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () { setState(() => _loading = true); _load(); }, child: Text(l10n.retry)),
          ],
        ),
      );

  List<Widget> _buildBody(AppLocalizations l10n, MedicineOrder o) {
    final color = _statusColor(o);
    return [
      // Status header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.orderNumber(o.id), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_localizedStatus(l10n, o),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_localizedStatusLabel(l10n, o), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            if (o.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.placedAt(DateFormat('MMM dd, yyyy • HH:mm').format(o.createdAt!)),
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Timeline or cancelled banner
      if (o.isCancelled)
        _cancelledBanner(l10n, o)
      else
        _timeline(l10n, o),
      const SizedBox(height: 16),

      // Prescription
      if ((o.prescription ?? '').isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.prescriptionAttached, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              const Icon(Icons.check_circle, size: 18, color: AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Items
      _card(l10n.itemsCount(o.medicines.length), [
        if (o.medicines.isEmpty)
          Text(l10n.awaitingPharmacistReview,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          ...o.medicines.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(m.inStock ? Icons.medication : Icons.error_outline,
                        size: 18, color: m.inStock ? AppColors.primary : AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.dosage != null && m.dosage!.isNotEmpty ? '${m.name} — ${m.dosage}' : m.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if ((m.frequency ?? '').isNotEmpty)
                            Text(m.frequency!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          if (!m.inStock)
                            Text(l10n.outOfStock, style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('x${m.quantity}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if ((m.totalPrice ?? 0) > 0)
                          Text('$_currency${m.totalPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              )),
      ]),
      const SizedBox(height: 16),

      // Payment summary (only meaningful once priced)
      if (o.amountDue > 0) ...[
        _card(l10n.paymentSection, [
          _amountRow(l10n.subtotal, o.amount),
          if ((o.deliveryFee ?? 0) > 0) _amountRow(l10n.deliveryFee, o.deliveryFee),
          if ((o.tax ?? 0) > 0) _amountRow(l10n.tax, o.tax),
          const Divider(height: 18),
          _amountRow(l10n.total, o.amountDue, bold: true),
          const SizedBox(height: 6),
          _row(l10n.status, '${o.paymentMethod ?? 'Mobile money'} • ${o.paymentStatus ?? 'Unpaid'}'),
          if ((o.paymentReference ?? '').isNotEmpty) _row(l10n.reference, o.paymentReference!),
        ]),
        const SizedBox(height: 16),
      ],

      // Delivery
      _card(l10n.deliverySection, [
        _row(l10n.typeLabel, o.deliveryType ?? '—'),
        if ((o.deliveryAddress ?? '').isNotEmpty) _row(l10n.addressLabel, o.deliveryAddress!),
        if (o.estimatedDelivery != null)
          _row(l10n.estimatedLabel, DateFormat('MMM dd, yyyy • HH:mm').format(o.estimatedDelivery!)),
        if (o.deliveredAt != null)
          _row(l10n.delivered, DateFormat('MMM dd, yyyy • HH:mm').format(o.deliveredAt!)),
        if (o.receivedConfirmed) _row('Receipt', 'Confirmed by you'),
        if ((o.pharmacistNote ?? '').isNotEmpty) _row('Pharmacy note', o.pharmacistNote!),
      ]),
      const SizedBox(height: 24),

      // Confirm & Pay (Awaiting Payment)
      if (o.payable)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _payNow,
            icon: const Icon(Icons.payment, size: 20),
            label: Text(l10n.confirmAndPayAmount('$_currency${o.amountDue.toStringAsFixed(2)}')),
          ),
        ),

      // Confirm received (Delivered, not yet confirmed)
      if (o.isDelivered && !o.receivedConfirmed)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _confirming ? null : _confirmReceived,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            icon: _confirming
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_confirming ? l10n.confirming : l10n.iReceivedMyOrder),
          ),
        ),

      if (o.payable || (o.isDelivered && !o.receivedConfirmed)) const SizedBox(height: 12),

      if (o.cancellable)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _cancelling ? null : _confirmCancel,
            icon: _cancelling
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.close, size: 18, color: AppColors.error),
            label: Text(_cancelling ? l10n.cancelling : l10n.cancelOrder,
                style: const TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ),
      const SizedBox(height: 32),
    ];
  }

  Widget _amountRow(String label, double? value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: bold ? 15 : 13,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                      color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
            ),
            Text('$_currency${(value ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: bold ? 16 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: bold ? AppColors.primary : AppColors.textPrimary)),
          ],
        ),
      );

  Widget _cancelledBanner(AppLocalizations l10n, MedicineOrder o) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.orderWasCancelled,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                  if ((o.cancellationReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(o.cancellationReason!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _timeline(AppLocalizations l10n, MedicineOrder o) {
    final current = o.stageIndex;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < MedicineOrder.stages.length; i++)
            _stageRow(
              label: _stageLabel(l10n, i),
              time: _stageTime(o, i),
              done: i < current,
              active: i == current,
              isLast: i == MedicineOrder.stages.length - 1,
            ),
        ],
      ),
    );
  }

  String? _stageTime(MedicineOrder o, int stageIndex) {
    // Stage order: Received(0), Under Review(1), Awaiting Payment(2),
    // Paid(3), Preparing(4), Out for Delivery(5), Delivered(6).
    DateTime? dt;
    switch (stageIndex) {
      case 0:
        dt = o.createdAt;
      case 4:
        dt = o.preparationStarted;
      case 5:
        dt = o.dispatchedAt;
      case 6:
        dt = o.deliveredAt;
    }
    return dt == null ? null : DateFormat('MMM dd • HH:mm').format(dt);
  }

  Widget _stageRow({
    required String label,
    String? time,
    required bool done,
    required bool active,
    required bool isLast,
  }) {
    final reached = done || active;
    final color = active ? AppColors.primary : (done ? AppColors.success : AppColors.cardBorder);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: reached ? color : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: AppColors.white)
                    : (active
                        ? const Center(
                            child: SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle))))
                        : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: done ? AppColors.success : AppColors.cardBorder),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: reached ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
                if (time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 96, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
