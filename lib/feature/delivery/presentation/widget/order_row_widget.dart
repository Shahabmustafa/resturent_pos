import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/delivery_model.dart';
import 'delivery_micro_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

class OrderRowWidget extends StatelessWidget {
  final DeliveryOrder order;
  final String riderName;
  final VoidCallback? onAssign, onOnTheWay, onDeliver, onCancel;

  const OrderRowWidget({
    super.key,
    required this.order,
    required this.riderName,
    this.onAssign,
    this.onOnTheWay,
    this.onDeliver,
    this.onCancel,
  });

  Color get _sc {
    switch (order.status) {
      case DeliveryOrderStatus.pending:
        return kRed;
      case DeliveryOrderStatus.assigned:
        return kYellow;
      case DeliveryOrderStatus.onTheWay:
        return kBlue;
      case DeliveryOrderStatus.delivered:
        return kGreen;
      case DeliveryOrderStatus.cancelled:
        return kMuted;
    }
  }

  String get _sl {
    switch (order.status) {
      case DeliveryOrderStatus.pending:
        return 'Pending';
      case DeliveryOrderStatus.assigned:
        return 'Assigned';
      case DeliveryOrderStatus.onTheWay:
        return 'On the Way';
      case DeliveryOrderStatus.delivered:
        return 'Delivered';
      case DeliveryOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) => Container(
        color: order.status == DeliveryOrderStatus.pending
            ? kRed.withOpacity(0.02)
            : order.status == DeliveryOrderStatus.onTheWay
                ? kBlue.withOpacity(0.02)
                : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text(order.orderNum,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kPrimary))),
          Expanded(
              flex: 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText)),
                    Text(order.phone,
                        style:
                            const TextStyle(fontSize: 11, color: kMuted)),
                  ])),
          Expanded(
              flex: 4,
              child: Row(children: [
                const SvgIcon(AppIcons.locationOnOutlined,
                    size: 12, color: kMuted),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(order.address,
                        style:
                            const TextStyle(fontSize: 11, color: kSub),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2)),
              ])),
          Expanded(
              flex: 4,
              child: Text(order.items,
                  style: const TextStyle(fontSize: 11, color: kSub),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2)),
          Expanded(
              flex: 2,
              child: Text(formatMoney(order.amount),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kText))),
          Expanded(
              flex: 2,
              child: order.riderId == null
                  ? const Text('—',
                      style: TextStyle(fontSize: 12, color: kMuted))
                  : Row(children: [
                      const SvgIcon(AppIcons.personRounded,
                          size: 12, color: kSub),
                      const SizedBox(width: 3),
                      Expanded(
                          child: Text(riderName,
                              style: const TextStyle(
                                  fontSize: 11, color: kSub),
                              overflow: TextOverflow.ellipsis))
                    ])),
          Expanded(flex: 2, child: StatusBadgeWidget(_sl, _sc)),
          Expanded(
              flex: 2,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ago(order.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: kMuted)),
                    if (order.notes.isNotEmpty)
                      Row(children: [
                        const SvgIcon(AppIcons.stickyNote2Outlined,
                            size: 10, color: kYellow),
                        const SizedBox(width: 2),
                        Expanded(
                            child: Text(order.notes,
                                style: const TextStyle(
                                    fontSize: 10, color: kYellow),
                                overflow: TextOverflow.ellipsis))
                      ]),
                  ])),
          Expanded(
              flex: 3,
              child: Row(children: [
                if (onAssign != null)
                  ABtnWidget('Assign', kBlue,
                      AppIcons.personAddRounded, onAssign!),
                if (onOnTheWay != null)
                  ABtnWidget('On Way', kPurple,
                      AppIcons.directionsBikeRounded, onOnTheWay!),
                if (onDeliver != null)
                  ABtnWidget('Deliver', kGreen,
                      AppIcons.checkCircleRounded, onDeliver!),
                if (onCancel != null) ...[
                  const SizedBox(width: 4),
                  IBtnWidget(
                      AppIcons.cancelOutlined, kMuted, onCancel!),
                ],
              ])),
        ]),
      );
}
