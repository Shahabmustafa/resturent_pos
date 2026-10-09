import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../../pos_and_order/data/datasource/pos_remote_datasource.dart';
import '../../../pos_and_order/presentation/provider/pos_provider.dart';
import '../../data/model/kitchen_model.dart';
import '../widget/kds_top_bar_widget.dart';
import '../widget/kds_misc_widgets.dart';
import '../widget/kds_skeleton.dart';
import '../widget/order_card_widget.dart';
import '../widget/token_dialog_widget.dart';

class KDSPage extends ConsumerStatefulWidget {
  const KDSPage({super.key});
  @override
  ConsumerState<KDSPage> createState() => _KDSPageState();
}

class _KDSPageState extends ConsumerState<KDSPage> with TickerProviderStateMixin {
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<KitchenOrder> _orders = [];
  late Timer _ticker;
  String _filter       = 'All';
  bool   _voiceEnabled = true;
  bool   _loading      = true;
  String? _announcedOrderNum;

  // UUID map: orderNum → UUID string
  final Map<String, String> _numToId = {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupStream());
  }

  void _setupStream() {
    // Cancel any existing subscription first (guards against hot-reload double-subscribe)
    _sub?.cancel();

    final branch = ref.read(branchAuthProvider).branch;
    if (branch == null) return;
    final branchId = branch.branchId;
    final db       = Supabase.instance.client;

    _sub = db
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('branch_id', branchId)
        .listen(
          (rows) async {
        if (!mounted) return;
        await _handleRows(rows);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Realtime channel errors (e.g. socket closed during hot reload,
        // network blip) shouldn't crash the KDS screen — just retry.
        debugPrint('KDS realtime stream error: $error');
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _setupStream();
        });
      },
      cancelOnError: false,
    );
  }

  Future<void> _handleRows(List<Map<String, dynamic>> rows) async {
    try {
      // Only active orders (not cancelled/delivered)
      final active = rows.where((r) {
        final s = r['status'] as String? ?? '';
        return s != 'cancelled' && s != 'delivered' && s != 'served';
      }).toList();

      // Fetch order_items for all active orders
      final orderIds = active.map((r) => r['id'] as String).toList();
      Map<String, List<KitchenOrderItem>> itemsMap = {};

      if (orderIds.isNotEmpty) {
        final itemsRes = await Supabase.instance.client
            .from('order_items')
            .select()
            .inFilter('order_id', orderIds);

        for (final row in itemsRes as List) {
          final oid  = row['order_id'] as String;
          final item = KitchenOrderItem(
            row['item_name'] as String? ?? '',
            (row['qty'] as num).toInt(),
            row['item_emoji'] as String? ?? '🍽️',
          );
          itemsMap.putIfAbsent(oid, () => []).add(item);
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = active.map((r) {
          final oid    = r['id'] as String;
          final status = r['status'] as String? ?? 'pending';

          final ko = KitchenOrder(
            id:           oid,
            orderNum:     r['order_number'] as String? ?? '',
            table:        r['table_number'] as String? ?? '',
            customerName: r['customer_name'] as String? ?? '',
            orderType:    r['order_type'] as String? ?? 'Dine-in',
            notes:        r['notes'] as String? ?? '',
            createdAt:    DateTime.parse(r['created_at'] as String),
            status:       status == 'preparing'
                ? OrderStatus.preparing
                : status == 'ready'
                ? OrderStatus.ready
                : OrderStatus.pending,
            items: itemsMap[oid] ?? [],
          );

          _numToId[ko.orderNum] = oid;

          // Preserve startedAt / readyAt / isDone from existing
          final existing = _orders.where((o) => o.id == oid).firstOrNull;
          if (existing != null) {
            ko.startedAt = existing.startedAt;
            ko.readyAt   = existing.readyAt;
            for (var i = 0; i < ko.items.length && i < existing.items.length; i++) {
              ko.items[i].isDone = existing.items[i].isDone;
            }
          }

          return ko;
        }).toList();

        // Sort: pending first, then preparing, then ready
        _orders.sort((a, b) {
          const order = [OrderStatus.pending, OrderStatus.preparing, OrderStatus.ready];
          final ai = order.indexOf(a.status);
          final bi = order.indexOf(b.status);
          if (ai != bi) return ai.compareTo(bi);
          return a.createdAt.compareTo(b.createdAt);
        });

        _loading = false;
      });
    } catch (e, st) {
      debugPrint('KDS row processing error: $e\n$st');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.cancel();
    super.dispose();
  }

  List<KitchenOrder> get _filtered {
    switch (_filter) {
      case 'Pending':   return _orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'Preparing': return _orders.where((o) => o.status == OrderStatus.preparing).toList();
      case 'Ready':     return _orders.where((o) => o.status == OrderStatus.ready).toList();
      default:          return _orders.where((o) => o.status != OrderStatus.ready).toList();
    }
  }

  int _count(OrderStatus s) => _orders.where((o) => o.status == s).length;

  Future<void> _startPreparing(KitchenOrder order) async {
    final id = _numToId[order.orderNum] ?? order.id;
    await ref.read(posProvider.notifier).updateStatus(id, 'preparing');
    setState(() {
      order.status    = OrderStatus.preparing;
      order.startedAt = DateTime.now();
    });
    _toast('Order ${order.orderNum} — Preparation started!', kPrimary);
  }

  Future<void> _markReady(KitchenOrder order) async {
    final id = _numToId[order.orderNum] ?? order.id;
    await ref.read(posProvider.notifier).updateStatus(id, 'ready');
    setState(() {
      order.status  = OrderStatus.ready;
      order.readyAt = DateTime.now();
    });
    if (_voiceEnabled) _announceReady(order);
    _toast('Order ${order.orderNum} — Ready!', kPrimary);
  }

  Future<void> _completeOrder(KitchenOrder order) async {
    final id = _numToId[order.orderNum] ?? order.id;
    await ref.read(posProvider.notifier).updateStatus(id, 'delivered');
    setState(() {
      _orders.removeWhere((o) => o.id == order.id);
      _numToId.remove(order.orderNum);
    });
    _toast('Order ${order.orderNum} delivered ✓', kPrimary);
  }

  void _announceReady(KitchenOrder order) {
    setState(() => _announcedOrderNum = order.orderNum);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _announcedOrderNum = null);
    });
  }

  void _toast(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));

  @override
  Widget build(BuildContext context) {
    final pending   = _count(OrderStatus.pending);
    final preparing = _count(OrderStatus.preparing);
    final ready     = _count(OrderStatus.ready);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        KDSTopBarWidget(
          pending:       pending,
          preparing:     preparing,
          ready:         ready,
          totalOrders:   _orders.length,
          voiceEnabled:  _voiceEnabled,
          onVoiceToggle: () => setState(() => _voiceEnabled = !_voiceEnabled),
          onNewOrder:    () {},
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _announcedOrderNum != null
              ? VoiceBannerWidget(orderNum: _announcedOrderNum!)
              : const SizedBox.shrink(),
        ),

        KDSFilterBarWidget(
          selected:  _filter,
          pending:   pending,
          preparing: preparing,
          ready:     ready,
          total:     _orders.length,
          onSelect:  (f) => setState(() => _filter = f),
        ),

        Expanded(
          child: _loading
              ? const KDSSkeleton()
              : _filtered.isEmpty
              ? const EmptyKitchenWidget()
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              crossAxisSpacing:   14,
              mainAxisSpacing:    14,
              childAspectRatio:   0.72,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final order = _filtered[i];
              return OrderCardWidget(
                order:        order,
                now:          DateTime.now(),
                onStart:      () => _startPreparing(order),
                onReady:      () => _markReady(order),
                onComplete:   () => _completeOrder(order),
                onToken:      () => showDialog(
                    context: context,
                    builder: (_) => TokenDialogWidget(order: order)),
                onToggleItem: (item) => setState(() => item.isDone = !item.isDone),
              );
            },
          ),
        ),
      ]),
    );
  }
}