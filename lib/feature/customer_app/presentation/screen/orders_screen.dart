import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/customer_datasource.dart';
import '../../data/model/dish_model.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/auth_dialog.dart';
import '../widget/customer_widgets.dart';
import '../widget/feedback_widgets.dart';
import '../widget/reveal.dart';

/// "My Orders": live tracker cards for orders in progress, then a compact,
/// filterable history of past orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

enum _Filter { all, active, completed, cancelled }

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(customerUserProvider).value != null;
    final ordersAsync = ref.watch(myOrdersProvider);
    final gutter = MediaQuery.sizeOf(context).width < 640 ? 20.0 : 28.0;

    final List<Widget> body;
    if (!signedIn) {
      body = [const _SignInPrompt()];
    } else if (ordersAsync.hasError) {
      body = [MenuStatus.error(error: '${ordersAsync.error}', onRetry: () => ref.invalidate(myOrdersProvider))];
    } else if (ordersAsync.value == null) {
      body = [const MenuStatus.loading()];
    } else if (ordersAsync.value!.isEmpty) {
      body = [const _NoOrders()];
    } else {
      final orders = ordersAsync.value!;
      bool matches(CustomerOrder o) => switch (_filter) {
        _Filter.all => true,
        _Filter.active => o.isOpen,
        _Filter.completed => _stageOf(o.status) == _Stage.done,
        _Filter.cancelled => _stageOf(o.status) == _Stage.cancelled,
      };
      final active = orders.where((o) => o.isOpen && matches(o)).toList();
      final past = orders.where((o) => !o.isOpen && matches(o)).toList();

      body = [
        _FilterTabs(
          selected: _filter,
          counts: {
            _Filter.all: orders.length,
            _Filter.active: orders.where((o) => o.isOpen).length,
            _Filter.completed: orders.where((o) => _stageOf(o.status) == _Stage.done).length,
            _Filter.cancelled: orders.where((o) => _stageOf(o.status) == _Stage.cancelled).length,
          },
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 20),
        if (active.isEmpty && past.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'No orders here.',
              textAlign: TextAlign.center,
              style: CText.body(14.5, color: CColors.muted),
            ),
          ),
        for (final o in active)
          Reveal(
            key: ValueKey('live-${o.id}'),
            child: _LiveOrderCard(order: o),
          ),
        if (past.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 10),
          if (_filter == _Filter.all) _SectionLabel('Order history', past.length),
          for (var i = 0; i < past.length; i++)
            Reveal(
              key: ValueKey('past-${past[i].id}'),
              delay: Duration(milliseconds: 40 * (i % 6)),
              child: _PastOrderTile(order: past[i]),
            ),
        ],
      ];
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
          children: [
            Text('MY ORDERS', style: CText.eyebrow()),
            const SizedBox(height: 8),
            Text('Your orders', style: CText.display(30)),
            const SizedBox(height: 6),
            Text(
              'Status updates here automatically as the restaurant works on your order.',
              style: CText.body(14, color: CColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            ...body,
          ],
        ),
      ),
    );
  }
}

// ── Stage helpers ─────────────────────────────────────────────────────────────

/// Where an order is, as the customer should read it.
enum _Stage { placed, preparing, ready, done, cancelled }

_Stage _stageOf(String status) => switch (status) {
  'cancelled' => _Stage.cancelled,
  'completed' || 'delivered' || 'served' => _Stage.done,
  'ready' => _Stage.ready,
  'preparing' => _Stage.preparing,
  _ => _Stage.placed,
};

(String, Color) _statusStyle(_Stage stage, bool delivery) => switch (stage) {
  _Stage.placed => ('Pending', CColors.gold),
  _Stage.preparing => ('Preparing', CColors.rust),
  _Stage.ready => (delivery ? 'On the way' : 'Ready', CColors.olive),
  _Stage.done => (delivery ? 'Delivered' : 'Completed', CColors.olive),
  _Stage.cancelled => ('Cancelled', CColors.muted),
};

String _itemsSummary(CustomerOrder o) {
  final count = o.lines.fold<int>(0, (n, l) => n + l.qty);
  final names = o.lines.map((l) => l.name).join(', ');
  return '$count ${count == 1 ? 'item' : 'items'}${names.isEmpty ? '' : ' · $names'}';
}

String _when(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final time = DateFormat('h:mm a').format(t);
  if (day == today) return 'Today, $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
  return DateFormat('d MMM yyyy, h:mm a').format(t);
}

// ── Filter tabs ───────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;

  const _FilterTabs({required this.selected, required this.counts, required this.onChanged});

  static const _labels = {
    _Filter.all: 'All',
    _Filter.active: 'In progress',
    _Filter.completed: 'Completed',
    _Filter.cancelled: 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: Duration.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: f == selected ? CColors.ink : CColors.paper,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: f == selected ? CColors.ink : CColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _labels[f]!,
                      style: CText.body(
                        13.5,
                        color: f == selected ? Colors.white : CColors.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: f == selected ? CColors.gold : CColors.cream,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${counts[f] ?? 0}',
                        style: CText.body(
                          11.5,
                          color: f == selected ? CColors.ink : CColors.muted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;

  const _SectionLabel(this.title, this.count);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      children: [
        Text(
          title,
          style: CText.body(14, color: CColors.ink, weight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text('$count', style: CText.body(13, color: CColors.muted)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: CColors.line)),
      ],
    ),
  );
}

// ── Live order (in progress) ──────────────────────────────────────────────────

class _LiveOrderCard extends StatelessWidget {
  final CustomerOrder order;

  const _LiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final stage = _stageOf(order.status);
    final delivery = order.type == 'Delivery';
    final headline = switch (stage) {
      _Stage.placed || _Stage.preparing => 'Your food is being prepared',
      _Stage.ready => delivery ? 'Your order is on its way' : 'Your order is ready to collect',
      _ => 'Order received',
    };
    final hint = switch (stage) {
      _Stage.ready => delivery ? 'Our rider is heading to you.' : 'Pop in to Walton Road to pick it up.',
      _ => delivery ? 'We\'ll send it out as soon as it\'s cooked.' : 'We\'ll have it ready for collection shortly.',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CColors.ink, CColors.inkElev],
        ),
        boxShadow: CShadows.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LiveBadge(),
                    const Spacer(),
                    Text(
                      'Order ${order.number}',
                      style: CText.body(13, color: CColors.goldPale, weight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(headline, style: CText.display(24, color: Colors.white)),
                const SizedBox(height: 6),
                Text(hint, style: CText.body(13.5, color: CColors.mutedLight, height: 1.5)),
                const SizedBox(height: 22),
                _Tracker(stage: stage, delivery: delivery),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Order details on a light panel
          Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CColors.paper, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SvgIcon(
                      delivery ? AppIcons.deliveryDiningRounded : AppIcons.takeoutDiningRounded,
                      size: 18,
                      color: CColors.rust,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${delivery ? 'Delivery' : 'Takeaway'} • ${_when(order.createdAt)}',
                        style: CText.body(13, color: CColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LineItems(order: order),
                const Divider(color: CColors.line, height: 22),
                _TotalRow(order: order, stage: stage, delivery: delivery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing "LIVE" dot + label.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: CColors.goldLight.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  if (!still)
                    Container(
                      width: 6 + 8 * _ctrl.value,
                      height: 6 + 8 * _ctrl.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CColors.goldLight.withValues(alpha: .5 * (1 - _ctrl.value)),
                      ),
                    ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: CColors.goldLight, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('LIVE', style: CText.eyebrow(color: CColors.goldLight)),
        ],
      ),
    );
  }
}

/// Placed → Preparing → On the way / Ready → Delivered / Collected, with icons.
class _Tracker extends StatelessWidget {
  final _Stage stage;
  final bool delivery;

  const _Tracker({required this.stage, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (AppIcons.receiptLongRounded, 'Placed'),
      (AppIcons.soupKitchenRounded, 'Preparing'),
      (delivery ? AppIcons.deliveryDiningRounded : AppIcons.takeoutDiningRounded, delivery ? 'On the way' : 'Ready'),
      (AppIcons.checkRounded, delivery ? 'Delivered' : 'Collected'),
    ];
    // Pending orders are already being cooked, so "Preparing" is the current step.
    final current = switch (stage) {
      _Stage.placed || _Stage.preparing => 1,
      _Stage.ready => 2,
      _ => 3,
    };

    // Steps shrink on small phones so the tracker never overflows.
    return LayoutBuilder(
      builder: (context, c) {
        final stepWidth = (c.maxWidth / steps.length).clamp(52.0, 64.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(top: 17),
                    decoration: BoxDecoration(
                      color: i <= current ? CColors.goldLight : Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              SizedBox(
                width: stepWidth,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: Duration.zero,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: i <= current ? CColors.goldGradient : null,
                        color: i <= current ? null : Colors.white.withValues(alpha: .08),
                        boxShadow: i == current
                            ? [BoxShadow(color: CColors.goldLight.withValues(alpha: .45), blurRadius: 14)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: SvgIcon(
                        steps[i].$1,
                        size: 18,
                        color: i <= current ? CColors.ink : Colors.white.withValues(alpha: .35),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      steps[i].$2,
                      textAlign: TextAlign.center,
                      style: CText.body(
                        11.5,
                        color: i <= current ? Colors.white : CColors.mutedLight,
                        weight: i == current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Past order (collapsible row) ──────────────────────────────────────────────

class _PastOrderTile extends StatefulWidget {
  final CustomerOrder order;

  const _PastOrderTile({required this.order});

  @override
  State<_PastOrderTile> createState() => _PastOrderTileState();
}

class _PastOrderTileState extends State<_PastOrderTile> {
  bool _open = false;

  Future<void> _rate() async {
    final sent = await showFeedbackDialog(context, widget.order);
    if (sent && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Thanks for your feedback!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final stage = _stageOf(order.status);
    final delivery = order.type == 'Delivery';
    final (statusLabel, statusColor) = _statusStyle(stage, delivery);
    final narrow = MediaQuery.sizeOf(context).width < 560;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _open ? CColors.gold.withValues(alpha: .55) : CColors.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: stage == _Stage.cancelled ? CColors.cream : CColors.goldPale.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: SvgIcon(
                        stage == _Stage.cancelled
                            ? AppIcons.blockRounded
                            : (delivery ? AppIcons.deliveryDiningRounded : AppIcons.takeoutDiningRounded),
                        size: 21,
                        color: stage == _Stage.cancelled ? CColors.mutedLight : CColors.rust,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Order ${order.number}',
                                  overflow: TextOverflow.ellipsis,
                                  style: CText.body(15, color: CColors.ink, weight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusDot(label: statusLabel, color: statusColor),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(_when(order.createdAt), style: CText.body(12, color: CColors.muted)),
                          const SizedBox(height: 2),
                          Text(
                            _itemsSummary(order),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CText.body(12.5, color: CColors.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(order.total),
                          style: CText.body(
                            15,
                            color: stage == _Stage.cancelled ? CColors.mutedLight : CColors.ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (order.canRate && !narrow)
                          _MiniButton(label: 'Rate', icon: AppIcons.starRounded, onTap: _rate)
                        else if (order.myRating != null)
                          StarRow(rating: order.myRating!, size: 13),
                      ],
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: Duration.zero,
                      child: const SvgIcon(AppIcons.keyboardArrowDownRounded, size: 22, color: CColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            // Narrow screens: rating prompt gets its own row instead of squeezing the header.
            if (order.canRate && narrow)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: _MiniButton(label: 'Rate this order', icon: AppIcons.starRounded, onTap: _rate, expand: true),
              ),
            AnimatedSize(
              duration: Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(color: CColors.line, height: 1),
                          const SizedBox(height: 14),
                          _LineItems(order: order),
                          const Divider(color: CColors.line, height: 22),
                          _TotalRow(order: order, stage: stage, delivery: delivery),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: CText.body(11, color: color, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _MiniButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final VoidCallback onTap;
  final bool expand;

  const _MiniButton({required this.label, required this.icon, required this.onTap, this.expand = false});

  @override
  Widget build(BuildContext context) => Material(
    color: CColors.goldPale.withValues(alpha: .6),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 13, color: CColors.rustDeep),
            const SizedBox(width: 4),
            Text(
              label,
              style: CText.body(12, color: CColors.rustDeep, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Shared pieces ─────────────────────────────────────────────────────────────

class _LineItems extends StatelessWidget {
  final CustomerOrder order;

  const _LineItems({required this.order});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final l in order.lines)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 26,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: CColors.cream, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text(
                  '${l.qty}×',
                  style: CText.body(12, color: CColors.rust, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l.name, style: CText.body(13.5, color: CColors.ink)),
              ),
              Text(formatPrice(l.total), style: CText.body(13.5, color: CColors.muted)),
            ],
          ),
        ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  final CustomerOrder order;
  final _Stage stage;
  final bool delivery;

  const _TotalRow({required this.order, required this.stage, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final cancelled = stage == _Stage.cancelled;
    final paid = order.paymentStatus == 'Paid';
    return Row(
      children: [
        SvgIcon(
          cancelled ? AppIcons.blockRounded : AppIcons.accountBalanceWalletRounded,
          size: 16,
          color: cancelled ? CColors.mutedLight : CColors.olive,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cancelled
                ? 'Nothing to pay'
                : paid
                ? 'Paid'
                : 'Pay on ${delivery ? 'delivery' : 'pickup'}',
            style: CText.body(12.5, color: cancelled ? CColors.muted : CColors.olive, weight: FontWeight.w600),
          ),
        ),
        Text('Total  ', style: CText.body(13, color: CColors.muted)),
        Text(
          formatPrice(order.total),
          style: CText.body(17, color: CColors.ink, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Empty / signed-out states ─────────────────────────────────────────────────

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) => _Message(
    icon: AppIcons.lockOutlineRounded,
    title: 'Log in to see your orders',
    text: 'Your orders and their status appear here once you are logged in.',
    action: PillButton(label: 'Login', small: true, onPressed: () => showCustomerAuthDialog(context)),
  );
}

class _NoOrders extends ConsumerWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Message(
    icon: AppIcons.receiptLongRounded,
    title: 'No orders yet',
    text: 'When you place an order it will show up here with its status.',
    action: PillButton(
      label: 'Browse Menu',
      small: true,
      icon: AppIcons.arrowForwardRounded,
      onPressed: () => ref.read(customerTabProvider.notifier).state = CustomerTab.menu,
    ),
  );
}

class _Message extends StatelessWidget {
  final AppIcon icon;
  final String title;
  final String text;
  final Widget action;

  const _Message({required this.icon, required this.title, required this.text, required this.action});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: CColors.paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CColors.line),
    ),
    child: Column(
      children: [
        IconBadge(icon, size: 64, background: CColors.cream, color: CColors.gold),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: CText.display(22)),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: CText.body(14, color: CColors.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        action,
      ],
    ),
  );
}
