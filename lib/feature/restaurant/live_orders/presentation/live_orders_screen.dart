import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/home/presentation/screen/pos_home_screen.dart';
import 'package:resturent_application/feature/restaurant/order/presentation/provider/order_provider.dart';
import 'package:resturent_application/feature/restaurant/pos_and_order/data/model/order_model.dart';

const _bg = Color(0xFFE9E9E9);
const _perPage = 8;

AppIcon _typeIcon(String type) => switch (type) {
  'Dine-in' => AppIcons.restaurantRounded,
  'Delivery' => AppIcons.localShippingRounded,
  _ => AppIcons.shoppingBagRounded,
};

Color _typeColor(String type) => switch (type) {
  'Dine-in' => const Color(0xFF2368D6),
  'Delivery' => const Color(0xFFFF7A00),
  _ => const Color(0xFFC9168A),
};

/// Live board of open orders: website/app orders, delivery orders and the rest of the till's orders.
class LiveOrdersScreen extends ConsumerWidget {
  final VoidCallback onHome;
  final StartSale onStartSale;
  final VoidCallback onCollection;
  final VoidCallback onOrders;
  final ValueChanged<OrderModel> onOpenOrder;

  const LiveOrdersScreen({
    super.key,
    required this.onHome,
    required this.onStartSale,
    required this.onCollection,
    required this.onOrders,
    required this.onOpenOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open =
        ref
            .watch(orderProvider)
            .orders
            .where(
              (o) => !const {
                'completed',
                'cancelled',
                'delivered',
              }.contains(o.status.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final web = open.where((o) => o.customerType == 'Online').toList();
    final delivery = open
        .where((o) => o.customerType != 'Online' && o.orderType == 'Delivery')
        .toList();
    final rest = open
        .where((o) => o.customerType != 'Online' && o.orderType != 'Delivery')
        .toList();

    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _OrderPanel(
                    title: 'Web/App Orders',
                    icon: AppIcons.peopleRounded,
                    orders: web,
                    onTap: onOpenOrder,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OrderPanel(
                    title: 'Delivery Orders',
                    icon: AppIcons.localShippingRounded,
                    orders: delivery,
                    onTap: onOpenOrder,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(4),
                          child: rest.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No open orders',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final o in rest)
                                        _OrderTile(
                                          order: o,
                                          width: 308,
                                          onTap: () => onOpenOrder(o),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: const Color(0xFF10B981),
                        elevation: 3,
                        borderRadius: BorderRadius.circular(3),
                        child: InkWell(
                          onTap: onOrders,
                          child: const SizedBox(
                            width: 300,
                            height: 64,
                            child: Center(
                              child: Text(
                                'ORDERS LIST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const TimeBox(),
              const SizedBox(width: 14),
              _HomeButton(onTap: onHome),
              const Spacer(),
              for (final t in saleTiles) ...[
                _SaleButton(
                  tile: t,
                  onTap: () =>
                      t.lookup ? onCollection() : onStartSale(t.orderType),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// White panel with a header, a count badge, « » paging and a list of order cards.
class _OrderPanel extends StatefulWidget {
  final String title;
  final AppIcon icon;
  final List<OrderModel> orders;
  final ValueChanged<OrderModel> onTap;
  const _OrderPanel({
    required this.title,
    required this.icon,
    required this.orders,
    required this.onTap,
  });

  @override
  State<_OrderPanel> createState() => _OrderPanelState();
}

class _OrderPanelState extends State<_OrderPanel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = (widget.orders.length / _perPage).ceil();
    final page = _page.clamp(0, pages == 0 ? 0 : pages - 1);
    final shown = widget.orders.skip(page * _perPage).take(_perPage).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFEAEAEA),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SvgIcon(widget.icon, size: 22, color: const Color(0xFF111827)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.orders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                _PageButton(
                  '«',
                  page > 0 ? () => setState(() => _page = page - 1) : null,
                ),
                const SizedBox(width: 8),
                _PageButton(
                  '»',
                  page < pages - 1
                      ? () => setState(() => _page = page + 1)
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final o in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _OrderTile(order: o, onTap: () => widget.onTap(o)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PageButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFDDDDDD),
    elevation: onTap == null ? 0 : 2,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 34,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: onTap == null ? Colors.black26 : Colors.black54,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Order card: coloured type block on the left, number, customer and total on the right.
class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final double? width;
  final VoidCallback onTap;
  const _OrderTile({required this.order, required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    final name = order.customerName.trim().isEmpty
        ? 'No Name'
        : order.customerName.trim();
    return Material(
      color: Colors.white,
      shape: Border.all(color: const Color(0xFFD1D5DB)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: 90,
          child: Row(
            children: [
              Container(
                width: 94,
                color: _typeColor(order.orderType),
                alignment: Alignment.center,
                child: SvgIcon(
                  _typeIcon(order.orderType),
                  size: 32,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'h:mm a',
                            ).format(order.createdAt.toLocal()),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatMoney(order.total),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live time over the logo, bottom-left.
class TimeBox extends StatelessWidget {
  const TimeBox({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
    stream: Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now()),
    initialData: DateTime.now(),
    builder: (_, snap) => Container(
      width: 160,
      height: 80,
      color: const Color(0xFF1F2A8C),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('h:mm a').format(snap.data!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SvgPicture.asset('assets/branding/app_icon.svg', height: 30),
        ],
      ),
    ),
  );
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 210,
        height: 72,
        child: Row(
          children: [
            Container(
              width: 68,
              color: const Color(0xFF2E6B85),
              alignment: Alignment.center,
              child: const SvgIcon(
                AppIcons.dashboardRounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Color(0xFF2E6B85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SaleButton extends StatelessWidget {
  final SaleTile tile;
  final VoidCallback onTap;
  const _SaleButton({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: tile.color,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(tile.icon, size: 26, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              tile.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
