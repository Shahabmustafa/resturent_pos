import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../provider/rider_provider.dart';
import '../widget/rider_actions.dart';
import '../widget/rider_order_card.dart';
import 'package:resturent_application/core/constants/currency.dart';

final _clock = DateFormat('h:mm a');

/// Full view of one delivery. Reads it from the live list, so status changes
/// made here or in the POS show up straight away.
class RiderOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const RiderOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(riderProvider.select((s) => s.order(orderId)));
    final busy = ref.watch(riderProvider.select((s) => s.working.contains(orderId)));
    final charge = ref.watch(riderProvider.select((s) => s.me?.chargePerDelivery ?? 0));

    if (order == null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          surfaceTintColor: kBg,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const SvgIcon(AppIcons.arrowBackRounded, size: 22, color: kText),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: kMuted.withValues(alpha: 0.12), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const SvgIcon(AppIcons.deliveryDiningRounded, size: 40, color: kMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delivery not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This delivery is no longer assigned to you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: kSub, height: 1.5),
                ),
                const SizedBox(height: 18),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to deliveries')),
              ],
            ),
          ),
        ),
      );
    }

    final status = order.status;
    final active = isActiveDelivery(order);
    final items = order.items.split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: kBg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const SvgIcon(AppIcons.arrowBackRounded, size: 22, color: kText),
        ),
        title: Text(
          order.orderNum,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
        ),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: _StatusChip(status))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Progress ──
          _Card(
            title: 'Progress',
            child: status == DeliveryOrderStatus.cancelled
                ? const Row(
                    children: [
                      SvgIcon(AppIcons.cancelOutlined, size: 20, color: kRed),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The restaurant cancelled this delivery.',
                          style: TextStyle(fontSize: 14, color: kRed, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _Step(title: 'Assigned to you', time: order.assignedAt, done: true, isLast: false),
                      _Step(
                        title: 'Picked up — on the way',
                        done: status == DeliveryOrderStatus.onTheWay || status == DeliveryOrderStatus.delivered,
                        current: status == DeliveryOrderStatus.assigned,
                        isLast: false,
                      ),
                      _Step(
                        title: 'Delivered',
                        time: order.deliveredAt,
                        done: status == DeliveryOrderStatus.delivered,
                        current: status == DeliveryOrderStatus.onTheWay,
                        isLast: true,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // ── Customer ──
          _Card(
            title: 'Customer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoRow(AppIcons.personRounded, order.customerName, bold: true),
                const SizedBox(height: 12),
                _InfoRow(AppIcons.phoneRounded, order.phone.isEmpty ? 'No phone number' : order.phone),
                const SizedBox(height: 12),
                _InfoRow(AppIcons.locationOnOutlined, order.address.isEmpty ? 'No address given' : order.address),
                if (active) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _BigButton(
                          icon: AppIcons.phoneRounded,
                          label: 'Call',
                          color: kGreen,
                          onTap: order.phone.isEmpty
                              ? null
                              : () => openExternal(context, Uri(scheme: 'tel', path: order.phone)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BigButton(
                          icon: AppIcons.locationOnOutlined,
                          label: 'Directions',
                          color: kBlue,
                          onTap: order.address.isEmpty
                              ? null
                              : () => openExternal(
                                  context,
                                  Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': order.address}),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Items ──
          _Card(
            title: 'Order items',
            child: items.isEmpty
                ? const Text('No items listed', style: TextStyle(fontSize: 14, color: kMuted))
                : Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 7),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item, style: const TextStyle(fontSize: 14.5, color: kText, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              title: 'Notes from the restaurant',
              child: Text(order.notes, style: const TextStyle(fontSize: 14.5, color: kText, height: 1.5)),
            ),
          ],
          const SizedBox(height: 12),

          // ── Money ──
          _Card(
            title: 'Payment',
            child: Column(
              children: [
                _MoneyRow('Collect from customer', order.amount, big: true),
                const Divider(color: kBorder, height: 24),
                _MoneyRow('Your charge for this delivery', charge, color: kGreen),
              ],
            ),
          ),
        ],
      ),

      // ── Next step ──
      // White bar reaches the screen edge; SafeArea only pads the button above the home indicator.
      bottomNavigationBar: active
          ? Container(
              decoration: const BoxDecoration(
                color: kCard,
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _NextStepButton(
                    onTheWay: status == DeliveryOrderStatus.onTheWay,
                    busy: busy,
                    onPressed: () => status == DeliveryOrderStatus.onTheWay
                        ? markDelivered(context, ref, order)
                        : startTrip(context, ref, order),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Same look as the button on the delivery card: icon + label, faded while saving.
class _NextStepButton extends StatelessWidget {
  final bool onTheWay;
  final bool busy;
  final VoidCallback onPressed;
  const _NextStepButton({required this.onTheWay, required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = onTheWay ? kGreen : kPrimary;
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : SvgIcon(
                onTheWay ? AppIcons.checkCircleRounded : AppIcons.directionsBikeRounded,
                size: 22,
                color: Colors.white,
              ),
        label: Text(
          onTheWay ? 'Mark Delivered' : 'Picked Up — Start Trip',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DeliveryOrderStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DeliveryOrderStatus.pending => ('Pending', kMuted),
      DeliveryOrderStatus.assigned => ('To pick up', kBlue),
      DeliveryOrderStatus.onTheWay => ('On the way', kPurple),
      DeliveryOrderStatus.delivered => ('Delivered', kGreen),
      DeliveryOrderStatus.cancelled => ('Cancelled', kRed),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// One row of the progress timeline: a dot, a connecting line and the label.
class _Step extends StatelessWidget {
  final String title;
  final DateTime? time;
  final bool done;
  final bool current;
  final bool isLast;

  const _Step({required this.title, this.time, required this.done, this.current = false, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = done ? kGreen : (current ? kPrimary : kBorder);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? kGreen : kCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: done ? const SvgIcon(AppIcons.checkRounded, size: 14, color: Colors.white) : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: done ? kGreen.withValues(alpha: 0.5) : kBorder)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: done || current ? FontWeight.w700 : FontWeight.w500,
                        color: done || current ? kText : kMuted,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(_clock.format(time!.toLocal()), style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppIcon icon;
  final String text;
  final bool bold;
  const _InfoRow(this.icon, this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: SvgIcon(icon, size: 19, color: kMuted),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: bold ? 16 : 14.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? kText : kSub,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _BigButton extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _BigButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: onTap == null ? 0.04 : 0.1),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 20, color: onTap == null ? kMuted : color),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onTap == null ? kMuted : color),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool big;
  final Color? color;
  const _MoneyRow(this.label, this.value, {this.big = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(fontSize: 14, color: kSub)),
      ),
      Text(
        formatMoney(value),
        style: TextStyle(fontSize: big ? 22 : 16, fontWeight: FontWeight.w800, color: color ?? kText),
      ),
    ],
  );
}
