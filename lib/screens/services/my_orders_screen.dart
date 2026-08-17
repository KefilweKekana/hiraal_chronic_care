import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medicine_order.dart';
import '../../services/service_locator.dart';
import '../../widgets/skeleton.dart';
import 'medicine_order_screen.dart';
import 'order_tracking_screen.dart';

/// Lists the patient's medicine orders with their live status. Tap an order to
/// open full tracking.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<MedicineOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    final result = await ServiceLocator.instance.bookings.getMyOrders();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final orders):
          _orders = orders;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  Color _statusColor(MedicineOrder o) {
    if (o.isCancelled) return AppColors.error;
    if (o.isDelivered) return AppColors.success;
    if (o.status == 'Awaiting Payment') return AppColors.error;
    if (o.status == 'Out for Delivery' || o.status == 'Paid') return AppColors.primary;
    return AppColors.warning;
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

  Future<void> _openTracking(MedicineOrder o) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id, initial: o)),
    );
    _load(); // refresh in case the status changed / order was cancelled
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.myOrders),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MedicineOrderScreen()),
          );
          _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text(l10n.newOrder, style: const TextStyle(color: AppColors.white)),
      ),
      body: _loading
          ? const SkeletonList(itemCount: 5)
          : _error != null
              ? _buildError(l10n)
              : _orders.isEmpty
                  ? _buildEmpty(l10n)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _orderCard(l10n, _orders[i]),
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
            const Icon(Icons.medical_services_outlined, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Center(child: Text(l10n.noOrdersYet, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            Center(child: Text(l10n.tapNewOrderHint,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ],
        ),
      );

  Widget _orderCard(AppLocalizations l10n, MedicineOrder o) {
    final color = _statusColor(o);
    final first = o.medicines.isNotEmpty
        ? o.medicines.first.name
        : (o.totalItems > 0 ? '${o.totalItems} item(s)' : l10n.prescriptionOrder);
    final more = o.medicines.length > 1 ? ' ${l10n.plusMore(o.medicines.length - 1)}' : '';
    return InkWell(
      onTap: () => _openTracking(o),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_pharmacy, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#${o.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(_localizedStatus(l10n, o),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$first$more', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        o.createdAt != null ? DateFormat('MMM dd, yyyy').format(o.createdAt!) : _localizedStatus(l10n, o),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      if (o.payable) ...[
                        const Spacer(),
                        Text(l10n.tapToPay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                      ],
                    ],
                  ),
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
