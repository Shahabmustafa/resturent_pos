import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/kitchen_model.dart';
import 'kds_top_bar_widget.dart';

class OrderCardWidget extends StatelessWidget {
  final KitchenOrder order;
  final DateTime now;
  final VoidCallback onStart, onReady, onComplete, onToken;
  final ValueChanged<KitchenOrderItem> onToggleItem;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.now,
    required this.onStart,
    required this.onReady,
    required this.onComplete,
    required this.onToken,
    required this.onToggleItem,
  });

  Color get _borderColor => kPrimary.withOpacity(0.5);

  Color get _statusColor => kPrimary;

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:   return 'PENDING';
      case OrderStatus.preparing: return 'PREPARING';
      case OrderStatus.ready:     return 'READY';
    }
  }

  bool get _isUrgent =>
      order.waitTime.inMinutes >= 15 && order.status != OrderStatus.ready;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Opacity ramps up as elapsed time grows — stronger color means more urgent.
  Color _timerColor(Duration d) {
    if (d.inMinutes < 5) return kPrimary.withOpacity(0.55);
    if (d.inMinutes < 10) return kPrimary.withOpacity(0.8);
    return kPrimary;
  }

  AppIcon _typeIcon(String type) {
    switch (type) {
      case 'Takeaway': return AppIcons.takeoutDiningRounded;
      case 'Delivery': return AppIcons.deliveryDiningRounded;
      default:         return AppIcons.restaurantRounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed =
    order.status == OrderStatus.preparing ? order.elapsed : order.waitTime;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(_isUrgent ? 0.15 : 0.06),
            blurRadius: _isUrgent ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: SvgIcon(_typeIcon(order.orderType), color: _statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNum,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                    Text(order.orderType,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kSub, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_formatDuration(elapsed),
                    style: TextStyle(
                        color: _timerColor(elapsed),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                Text(order.status == OrderStatus.preparing ? 'cooking' : 'waiting',
                    style: const TextStyle(color: kSub, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              if (order.table.isNotEmpty) ...[
                InfoPillWidget(AppIcons.tableRestaurantRounded, order.table, kPrimary),
                const SizedBox(width: 6),
              ],
              if (order.customerName.isNotEmpty)
                Flexible(
                  child: InfoPillWidget(
                      AppIcons.personRounded, order.customerName, kSub),
                ),
              const SizedBox(width: 6),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (order.status == OrderStatus.preparing) ...[
                    PulseDotWidget(color: _statusColor),
                    const SizedBox(width: 4),
                  ],
                  Text(_statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ]),
              ),
            ]),
            if (_isUrgent) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kPrimary.withOpacity(0.25)),
                ),
                child: const Row(children: [
                  SvgIcon(AppIcons.warningAmberRounded, color: kPrimary, size: 13),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text('URGENT — Over 15 minutes!',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ],
          ]),
        ),

        // ── Items ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Items',
                    style: TextStyle(
                        color: kSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const Spacer(),
                if (order.status == OrderStatus.preparing)
                  Text('${order.doneItems}/${order.items.length}',
                      style: const TextStyle(
                          color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  children: order.items
                      .map((item) => GestureDetector(
                    onTap: order.status == OrderStatus.preparing
                        ? () => onToggleItem(item)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: item.isDone
                            ? kPrimary.withOpacity(0.08)
                            : kBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: item.isDone
                                ? kPrimary.withOpacity(0.3)
                                : Colors.transparent),
                      ),
                      child: Row(children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: item.isDone ? kSub : kText,
                                fontSize: 13,
                                fontWeight: item.isDone
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: kSub,
                              )),
                        ),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kMuted.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('×${item.qty}',
                              style: const TextStyle(
                                  color: kSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        if (order.status == OrderStatus.preparing)
                          SvgIcon(
                            item.isDone
                                ? AppIcons.checkCircleRounded
                                : AppIcons.radioButtonUncheckedRounded,
                            color: item.isDone ? kPrimary : kMuted,
                            size: 18,
                          ),
                      ]),
                    ),
                  ))
                      .toList(),
                ),
              ),
            ]),
          ),
        ),

        // ── Notes ──
        if (order.notes.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SvgIcon(AppIcons.stickyNote2Rounded, color: kPrimary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(order.notes,
                    style: const TextStyle(
                        color: kPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

        // ── Progress bar ──
        if (order.status == OrderStatus.preparing) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Progress', style: TextStyle(color: kSub, fontSize: 10)),
                Text(
                    '${order.items.isEmpty ? 0 : order.allItemsDone ? 100 : ((order.doneItems / order.items.length) * 100).toInt()}%',
                    style: const TextStyle(
                        color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: order.items.isEmpty ? 0 : order.doneItems / order.items.length,
                  backgroundColor: kBorder,
                  valueColor:
                  AlwaysStoppedAnimation(kPrimary),
                  minHeight: 5,
                ),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 10),

        // ── Action Buttons ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(children: [
            if (order.status == OrderStatus.pending)
              ActionBtnWidget(
                  label: 'Start Preparing',
                  color: kPrimary,
                  onTap: onStart,
                  icon: AppIcons.playArrowRounded),
            if (order.status == OrderStatus.preparing)
              ActionBtnWidget(
                  label: 'Mark as Ready',
                  color: order.allItemsDone ? kPrimary : kPrimary.withOpacity(0.7),
                  onTap: onReady,
                  icon: AppIcons.checkCircleRounded),
            if (order.status == OrderStatus.ready)
              ActionBtnWidget(
                  label: 'Delivered — Complete',
                  color: kPrimary,
                  onTap: onComplete,
                  icon: AppIcons.doneAllRounded),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onToken,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SvgIcon(AppIcons.printRounded, size: 14, color: kSub),
                  SizedBox(width: 6),
                  Text('Kitchen Token Print',
                      style: TextStyle(color: kSub, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Info Pill ────────────────────────────────────────────────────────────────

class InfoPillWidget extends StatelessWidget {
  final AppIcon icon;
  final String text;
  final Color color;
  const InfoPillWidget(this.icon, this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgIcon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class ActionBtnWidget extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final AppIcon icon;
  const ActionBtnWidget({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }
}