import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import 'package:resturent_application/core/constants/currency.dart';

/// Opens a phone call or Maps link in the right app.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No app found to open this')));
  }
}

/// An active delivery: who, where, what, how much, and the next step.
class RiderOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final bool busy;
  final VoidCallback? onStartTrip; // assigned -> picked up
  final VoidCallback? onDelivered; // on the way -> delivered

  final VoidCallback? onTap; // open the detail screen

  const RiderOrderCard({
    super.key,
    required this.order,
    required this.busy,
    this.onTap,
    this.onStartTrip,
    this.onDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final onTheWay = order.status == DeliveryOrderStatus.onTheWay;
    final (badge, badgeColor) = onTheWay ? ('On the way', kPurple) : ('To pick up', kBlue);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: const [BoxShadow(color: Color(0x0D000020), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Order number + status ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    order.orderNum,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      DateFormat('h:mm a').format((order.assignedAt ?? order.createdAt).toLocal()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: badgeColor),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const SvgIcon(AppIcons.chevronRightRounded, size: 20, color: kMuted),
                  ],
                ],
              ),
            ),
            // Three-step progress: assigned → on the way → delivered.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= (onTheWay ? 1 : 0) ? badgeColor : kBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Customer + address ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(AppIcons.personRounded, order.customerName, bold: true),
                  const SizedBox(height: 10),
                  _Line(AppIcons.locationOnOutlined, order.address.isEmpty ? 'No address given' : order.address),
                  if (order.items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _Line(AppIcons.shoppingBagOutlined, _itemsSummary(order.items)),
                  ],
                  if (order.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SvgIcon(AppIcons.infoOutlineRounded, size: 16, color: kYellow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(order.notes, style: const TextStyle(fontSize: 13, color: kText, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Call / Map ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickButton(
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
                    child: _QuickButton(
                      icon: AppIcons.locationOnOutlined,
                      label: 'Map',
                      color: kBlue,
                      onTap: order.address.isEmpty
                          ? null
                          : () => openExternal(
                              context,
                              Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': order.address}),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Amount + next step ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: kLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('Collect', style: TextStyle(fontSize: 13, color: kSub)),
                      const Spacer(),
                      Text(
                        formatMoney(order.amount),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : (onTheWay ? onDelivered : onStartTrip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: onTheWay ? kGreen : kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: (onTheWay ? kGreen : kPrimary).withValues(alpha: 0.5),
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
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final AppIcon icon;
  final String text;
  final bool bold;
  const _Line(this.icon, this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: SvgIcon(icon, size: 18, color: kMuted),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: bold ? 15.5 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? kText : kSub,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _QuickButton extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _QuickButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: onTap == null ? 0.04 : 0.1),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 18, color: onTap == null ? kMuted : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: onTap == null ? kMuted : color),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A finished (delivered or cancelled) delivery in the History tab.
class RiderHistoryTile extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback? onTap;
  const RiderHistoryTile({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == DeliveryOrderStatus.delivered;
    final color = delivered ? kGreen : kMuted;
    final when = (order.deliveredAt ?? order.createdAt).toLocal();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: SvgIcon(delivered ? AppIcons.checkCircleRounded : AppIcons.cancelOutlined, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.orderNum} • ${order.customerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${delivered ? 'Delivered' : 'Cancelled'} • ${DateFormat('d MMM, h:mm a').format(when)}',
                    style: const TextStyle(fontSize: 12, color: kMuted),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(order.amount),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: delivered ? kText : kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// "4 items · Chicken Karahi × 1 +3 more" — the full list is on the detail screen.
String _itemsSummary(String items) {
  final parts = items.split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.length <= 1) return items.trim();
  return '${parts.length} items · ${parts.first} +${parts.length - 1} more';
}
