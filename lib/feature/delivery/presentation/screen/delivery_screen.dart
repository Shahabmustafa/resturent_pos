import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../restaurant/auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/delivery_datasource.dart';
import '../../data/model/delivery_model.dart';
import '../widget/delivery_micro_widgets.dart';
import '../widget/order_row_widget.dart';
import '../widget/reports_tab_widget.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final deliveryDsProvider = Provider<DeliveryDatasource>(
        (_) => DeliveryDatasource(Supabase.instance.client));

class DeliveryPage extends ConsumerStatefulWidget {
  const DeliveryPage({super.key});
  @override
  ConsumerState<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends ConsumerState<DeliveryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late String _branchId;

  List<DeliveryOrder> _orders = [];
  List<Rider>         _riders = [];
  bool  _loading = true;
  String _of     = 'All';

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    _branchId = ref.read(branchAuthProvider).branch!.branchId;
    await _loadRiders();
    _setupStream();
    setState(() => _loading = false);
  }

  Future<void> _loadRiders() async {
    final ds = ref.read(deliveryDsProvider);
    _riders  = await ds.fetchRiders(_branchId);
  }

  void _setupStream() {
    final ds = ref.read(deliveryDsProvider);
    _sub = ds.deliveryOrdersStream(_branchId).listen((rows) {
      if (!mounted) return;
      setState(() => _orders = rows.map((r) => DeliveryOrder.fromJson(r)).toList());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tab.dispose();
    super.dispose();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  List<DeliveryOrder> get _filtered {
    switch (_of) {
      case 'Pending':   return _orders.where((o) => o.status == DeliveryOrderStatus.pending).toList();
      case 'Active':    return _orders.where((o) => o.status == DeliveryOrderStatus.assigned || o.status == DeliveryOrderStatus.onTheWay).toList();
      case 'Delivered': return _orders.where((o) => o.status == DeliveryOrderStatus.delivered).toList();
      case 'Cancelled': return _orders.where((o) => o.status == DeliveryOrderStatus.cancelled).toList();
      default:          return _orders;
    }
  }

  int _cnt(DeliveryOrderStatus s) => _orders.where((o) => o.status == s).length;
  int get _pendingCnt   => _cnt(DeliveryOrderStatus.pending);
  int get _activeCnt    => _cnt(DeliveryOrderStatus.assigned) + _cnt(DeliveryOrderStatus.onTheWay);
  int get _deliveredCnt => _cnt(DeliveryOrderStatus.delivered);

  String _riderName(String? id) {
    if (id == null) return '—';
    return _riders.where((r) => r.id == id).firstOrNull?.name ?? '—';
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _assignRider(DeliveryOrder order) async {
    final available = _riders.where((r) => r.status == RiderStatus.available).toList();
    String? selectedId;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => _AssignDialog(order: order, riders: available),
    );
    if (confirmed == null || !mounted) return;

    final ds = ref.read(deliveryDsProvider);
    await ds.assignRider(order.id, confirmed);
    await _loadRiders();
    setState(() {});
    _toast('Rider assigned!', kBlue);
  }

  Future<void> _markOnTheWay(DeliveryOrder order) async {
    await ref.read(deliveryDsProvider).markOnTheWay(order.id);
    _toast('Order on the way!', kPurple);
  }

  Future<void> _markDelivered(DeliveryOrder order) async {
    if (order.riderId == null) {
      _toast('No rider assigned!', kRed);
      return;
    }

    // Look in the local list — if missing, fetch fresh from the DB
    Rider? rider = _riders.where((r) => r.id == order.riderId).firstOrNull;
    if (rider == null) {
      // The rider was busy and not in the local list — reload riders
      await _loadRiders();
      rider = _riders.where((r) => r.id == order.riderId).firstOrNull;
    }

    // Fallback rider name (if still missing after the DB reload)
    final riderName   = rider?.name              ?? 'Rider';
    final riderCharge = rider?.chargePerDelivery ?? 0.0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDlg(
        title: 'Mark as Delivered?',
        msg:   '${order.orderNum} — ${order.customerName}\nRider: $riderName\nCharge: ${formatMoney(riderCharge)}'
               '\n\nCollect ${formatMoney(order.amount)} from the rider. '
               'The invoice will be marked Completed and Paid.',
        confirmLabel: 'Mark Delivered',
        color: kGreen,
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(deliveryDsProvider).markDelivered(
      branchId:        _branchId,
      deliveryOrderId: order.id,
      riderId:         order.riderId!,
      orderNum:        order.orderNum,
      orderAmount:     order.amount,
      riderCharge:     riderCharge,
    );
    await _loadRiders();
    setState(() {});
    _toast('Delivered! Rider free. Earning of ${formatMoney(riderCharge)} added.', kGreen);
  }

  Future<void> _cancelOrder(DeliveryOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDlg(
        title: 'Cancel Order?',
        msg:   'Cancel ${order.orderNum}?',
        confirmLabel: 'Cancel Order',
        color: kRed,
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(deliveryDsProvider).cancelDeliveryOrder(order.id, riderId: order.riderId);
    if (order.riderId != null) { await _loadRiders(); setState(() {}); }
    _toast('Order cancelled.', kMuted);
  }

  Future<void> _addManualOrder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddOrderDlg(),
    );
    if (result == null || !mounted) return;

    final ds    = ref.read(deliveryDsProvider);
    final order = DeliveryOrder(
      id:           '',
      orderNum:     'MNL-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      customerName: result['name'],
      phone:        result['phone'],
      address:      result['address'],
      items:        result['items'],
      amount:       result['amount'],
      notes:        result['notes'],
      status:       DeliveryOrderStatus.pending,
      createdAt:    DateTime.now(),
    );
    await ds.createDeliveryOrder(order, _branchId);
    _toast('New delivery order added!', kPrimary);
  }

  Future<void> _addRider() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddRiderDlg(),
    );
    if (result == null || !mounted) return;

    final rider = Rider(
      id:                '',
      name:              result['name'],
      phone:             result['phone'],
      vehicle:           result['vehicle'],
      status:            RiderStatus.available,
      chargePerDelivery: result['charge'],
      totalDeliveries:   0,
      totalEarnings:     0,
    );
    final ds = ref.read(deliveryDsProvider);
    final saved = await ds.addRider(rider, _branchId);
    setState(() => _riders.add(saved));

    final password = result['password'] as String;
    if (password.isEmpty) {
      _toast('Rider added!', kGreen);
      return;
    }
    await _saveLogin(saved, password: password);
  }

  /// Creates/updates the rider's mobile-app login and reports the phone to sign in with.
  Future<void> _saveLogin(Rider rider, {String? password}) async {
    try {
      final login = await ref.read(deliveryDsProvider).setRiderLogin(rider.id, password: password);
      if (!mounted) return;
      setState(() => rider.hasLogin = true);
      _toast('Rider app login ready — phone: $login', kGreen);
    } catch (e) {
      _toast('Rider saved, but app login failed: ${e.toString().replaceFirst('Exception: ', '')}', kRed);
    }
  }

  Future<void> _editRider(Rider rider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditRiderDlg(rider: rider),
    );
    if (result == null || !mounted) return;
    final phoneChanged      = rider.phone != result['phone'];
    rider.name              = result['name'];
    rider.phone             = result['phone'];
    rider.vehicle           = result['vehicle'];
    rider.chargePerDelivery = result['charge'];
    final ds = ref.read(deliveryDsProvider);
    await ds.updateRider(rider);
    setState(() {});

    final password = result['password'] as String;
    if (result['removeLogin'] == true) {
      try {
        await ds.removeRiderLogin(rider.id);
        setState(() => rider.hasLogin = false);
        _toast('Rider updated — app access removed.', kBlue);
      } catch (e) {
        _toast('Could not remove app access: ${e.toString().replaceFirst('Exception: ', '')}', kRed);
      }
    } else if (password.isNotEmpty || (rider.hasLogin && phoneChanged)) {
      // A changed phone moves the login too, since riders sign in with their phone.
      await _saveLogin(rider, password: password);
    } else {
      _toast('Rider updated!', kBlue);
    }
  }

  Future<void> _toggleRiderOffline(Rider rider) async {
    final newStatus = rider.status == RiderStatus.offline
        ? RiderStatus.available
        : RiderStatus.offline;
    await ref.read(deliveryDsProvider).updateRiderStatus(rider.id, newStatus.toJson());
    setState(() => rider.status = newStatus);
  }

  void _toast(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: kBg, body: PageSkeleton(statCount: 4, rows: 6, columns: 5));

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        // ── Top Bar ──
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
              color: kCard,
              border: Border(bottom: BorderSide(color: kBorder)),
              boxShadow: [BoxShadow(color: Color(0x08000020), blurRadius: 8, offset: Offset(0, 2))]),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const SvgIcon(AppIcons.deliveryDiningRounded, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delivery Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
              Text('Track orders and assign riders', style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _tab.index == 1 ? _addRider : _addManualOrder,
              icon: const SvgIcon(AppIcons.addRounded, size: 16),
              label: AnimatedBuilder(
                animation: _tab,
                builder: (_, __) => Text(
                  _tab.index == 1 ? 'Add Rider' : 'New Order',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ]),
        ),

        // ── Stats ──
        Container(
          color: kCard,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: StatCardRow(cards: [
            StatCardData(AppIcons.pendingActionsRounded, 'Pending',   '$_pendingCnt',   kRed),
            StatCardData(AppIcons.directionsBikeRounded,  'Active',    '$_activeCnt',    kYellow),
            StatCardData(AppIcons.checkCircleRounded,     'Delivered', '$_deliveredCnt', kGreen),
            StatCardData(AppIcons.peopleRounded,          'Riders',    '${_riders.length}', kBlue),
          ]),
        ),

        // ── Tabs ──
        Container(
          color: kCard,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AppTabBar(
            controller: _tab,
            expand: false,
            items: [
              AppTabItem('Orders', icon: AppIcons.deliveryDiningRounded, count: _orders.length),
              AppTabItem('Riders', icon: AppIcons.directionsBikeRounded, count: _riders.length),
              const AppTabItem('Reports', icon: AppIcons.barChartRounded),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(controller: _tab, children: [

            // ── TAB 1: ORDERS ────────────────────────────────────────────
            Column(children: [
              Container(
                color: kCard,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(children: [
                  for (final f in ['All', 'Pending', 'Active', 'Delivered', 'Cancelled'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FChipWidget(
                        f, _of == f,
                        f == 'Pending' ? kRed : f == 'Active' ? kYellow : f == 'Delivered' ? kGreen : f == 'Cancelled' ? kMuted : kBlue,
                            () => setState(() => _of = f),
                      ),
                    ),
                  const Spacer(),
                  Text('${_filtered.length} orders', style: const TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
              // Header
              Container(
                color: kLight,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Row(children: [
                  HWidget('Order', flex: 2), HWidget('Customer', flex: 3), HWidget('Address', flex: 4),
                  HWidget('Items', flex: 4), HWidget('Amount', flex: 2), HWidget('Rider', flex: 2),
                  HWidget('Status', flex: 2), HWidget('Time', flex: 2), HWidget('Actions', flex: 3),
                ]),
              ),
              const Divider(height: 1, color: kBorder),
              Expanded(
                child: _filtered.isEmpty
                    ? const EmptyWidget('No delivery orders')
                    : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                  itemBuilder: (_, i) {
                    final o = _filtered[i];
                    return OrderRowWidget(
                      order:     o,
                      riderName: _riderName(o.riderId),
                      onAssign:   o.status == DeliveryOrderStatus.pending  ? () => _assignRider(o)  : null,
                      onOnTheWay: o.status == DeliveryOrderStatus.assigned  ? () => _markOnTheWay(o) : null,
                      onDeliver:  o.status == DeliveryOrderStatus.onTheWay  ? () => _markDelivered(o) : null,
                      onCancel:   (o.status == DeliveryOrderStatus.pending || o.status == DeliveryOrderStatus.assigned) ? () => _cancelOrder(o) : null,
                    );
                  },
                ),
              ),
            ]),

            // ── TAB 2: RIDERS ────────────────────────────────────────────
            Column(children: [
              Container(
                color: kLight,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Row(children: [
                  HWidget('Rider', flex: 3), HWidget('Phone', flex: 2), HWidget('Vehicle', flex: 3),
                  HWidget('Charge/Del', flex: 2), HWidget('Deliveries', flex: 2), HWidget('Earnings', flex: 2),
                  HWidget('Status', flex: 2), HWidget('Actions', flex: 2),
                ]),
              ),
              const Divider(height: 1, color: kBorder),
              Expanded(
                child: _riders.isEmpty
                    ? const EmptyWidget('No riders — tap Add Rider')
                    : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _riders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                  itemBuilder: (_, i) {
                    final r  = _riders[i];
                    final sc = r.status == RiderStatus.available ? kGreen : r.status == RiderStatus.busy ? kYellow : kMuted;
                    final sl = r.status == RiderStatus.available ? 'Available' : r.status == RiderStatus.busy ? 'On Delivery' : 'Offline';
                    return Container(
                      color: r.status == RiderStatus.busy ? kYellow.withOpacity(0.02) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(children: [
                        Expanded(flex: 3, child: Row(children: [
                          CircleAvatar(radius: 18, backgroundColor: kPrimary.withOpacity(0.15),
                              child: Text(r.name[0], style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 15))),
                          const SizedBox(width: 10),
                          Flexible(child: Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText), overflow: TextOverflow.ellipsis)),
                          if (r.hasLogin) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Can sign in to the Rider app',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  SvgIcon(AppIcons.phoneAndroidRounded, size: 11, color: kGreen),
                                  SizedBox(width: 3),
                                  Text('App', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kGreen)),
                                ]),
                              ),
                            ),
                          ],
                        ])),
                        Expanded(flex: 2, child: Text(r.phone, style: const TextStyle(fontSize: 12, color: kSub))),
                        Expanded(flex: 3, child: Text(r.vehicle, style: const TextStyle(fontSize: 12, color: kSub))),
                        Expanded(flex: 2, child: Text(formatMoney(r.chargePerDelivery), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText))),
                        Expanded(flex: 2, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                          child: Text('${r.totalDeliveries}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kBlue)),
                        )),
                        Expanded(flex: 2, child: Text(formatMoney(r.totalEarnings), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGreen))),
                        Expanded(flex: 2, child: StatusBadgeWidget(sl, sc)),
                        Expanded(flex: 2, child: Row(children: [
                          IBtnWidget(AppIcons.editRounded, kBlue, () => _editRider(r)),
                          const SizedBox(width: 4),
                          if (r.status != RiderStatus.busy)
                            IBtnWidget(
                              r.status == RiderStatus.offline ? AppIcons.powerSettingsNewRounded : AppIcons.powerOffRounded,
                              r.status == RiderStatus.offline ? kGreen : kMuted,
                                  () => _toggleRiderOffline(r),
                            ),
                        ])),
                      ]),
                    );
                  },
                ),
              ),
            ]),

            // ── TAB 3: REPORTS ───────────────────────────────────────────
            ReportsTabWidget(riders: _riders, orders: _orders),
          ]),
        ),
      ]),
    );
  }
}

// ── Assign Dialog ─────────────────────────────────────────────────────────────
class _AssignDialog extends StatefulWidget {
  final DeliveryOrder order;
  final List<Rider>   riders;
  const _AssignDialog({required this.order, required this.riders});
  @override State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Row(children: [
      const SvgIcon(AppIcons.personAddRounded, color: kPrimary, size: 20), const SizedBox(width: 8),
      Text('${widget.order.orderNum} — Rider Assign',
          style: const TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 15)),
    ]),
    content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const SvgIcon(AppIcons.personOutlineRounded, size: 13, color: kMuted), const SizedBox(width: 4), Text(widget.order.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText))]),
          const SizedBox(height: 3),
          Row(children: [const SvgIcon(AppIcons.locationOnOutlined, size: 13, color: kMuted), const SizedBox(width: 4), Expanded(child: Text(widget.order.address, style: const TextStyle(fontSize: 12, color: kSub), overflow: TextOverflow.ellipsis))]),
        ]),
      ),
      const SizedBox(height: 14),
      if (widget.riders.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kRed.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.2))),
          child: const Row(children: [SvgIcon(AppIcons.warningAmberRounded, color: kRed, size: 16), SizedBox(width: 8), Text('No riders available!', style: TextStyle(color: kRed, fontWeight: FontWeight.w600))]),
        )
      else ...[
        const Align(alignment: Alignment.centerLeft, child: Text('Available Riders:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kSub))),
        const SizedBox(height: 8),
        ...widget.riders.map((r) => GestureDetector(
          onTap: () => setState(() => _selected = r.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selected == r.id ? kGreen.withOpacity(0.07) : kLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _selected == r.id ? kGreen.withOpacity(0.4) : kBorder, width: _selected == r.id ? 1.5 : 1),
            ),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: kPrimary.withOpacity(0.12), child: Text(r.name[0], style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _selected == r.id ? kText : kSub)),
                Text('${r.vehicle} • ${r.totalDeliveries} deliveries', style: const TextStyle(fontSize: 11, color: kMuted)),
              ])),
              Text('${formatMoney(r.chargePerDelivery)}/del', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selected == r.id ? kGreen : kMuted)),
              const SizedBox(width: 8),
              if (_selected == r.id) const SvgIcon(AppIcons.checkCircleRounded, color: kGreen, size: 18),
            ]),
          ),
        )),
      ],
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      if (widget.riders.isNotEmpty)
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
          child: const Text('Assign Rider', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
    ],
  );
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────
class _ConfirmDlg extends StatelessWidget {
  final String title, msg, confirmLabel;
  final Color color;
  const _ConfirmDlg({required this.title, required this.msg, required this.confirmLabel, required this.color});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.w800)),
    content: Text(msg, style: const TextStyle(color: kSub)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ── Add Order Dialog ──────────────────────────────────────────────────────────
class _AddOrderDlg extends StatefulWidget {
  const _AddOrderDlg();
  @override State<_AddOrderDlg> createState() => _AddOrderDlgState();
}

class _AddOrderDlgState extends State<_AddOrderDlg> {
  final _name = TextEditingController(), _phone = TextEditingController();
  final _addr = TextEditingController(), _items = TextEditingController();
  final _amt  = TextEditingController(), _notes = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Row(children: [SvgIcon(AppIcons.addCircleRounded, color: kPrimary, size: 20), SizedBox(width: 8), Text('New Delivery Order', style: TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 15))]),
    content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: fieldWidget('Customer Name *', _name, 'e.g. Sara Khan')),
        const SizedBox(width: 10),
        Expanded(child: fieldWidget('Phone *', _phone, '0300-xxx', kt: TextInputType.phone)),
      ]),
      const SizedBox(height: 12),
      fieldWidget('Delivery Address *', _addr, 'House 12, Street 4'),
      const SizedBox(height: 12),
      fieldWidget('Items', _items, 'Family Deal × 1, Drinks × 2'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: fieldWidget('Amount (£)', _amt, '2650', kt: TextInputType.number)),
        const SizedBox(width: 10),
        Expanded(child: fieldWidget('Notes', _notes, 'e.g. Call before delivery')),
      ]),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () {
          if (_name.text.trim().isEmpty || _addr.text.trim().isEmpty) return;
          Navigator.pop(context, {
            'name': _name.text.trim(), 'phone': _phone.text.trim(),
            'address': _addr.text.trim(), 'items': _items.text.trim(),
            'amount': double.tryParse(_amt.text) ?? 0, 'notes': _notes.text.trim(),
          });
        },
        child: const Text('Add Order', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ── Add Rider Dialog ──────────────────────────────────────────────────────────
class _AddRiderDlg extends StatefulWidget {
  const _AddRiderDlg();
  @override State<_AddRiderDlg> createState() => _AddRiderDlgState();
}

class _AddRiderDlgState extends State<_AddRiderDlg> {
  final _name    = TextEditingController();
  final _phone   = TextEditingController();
  final _vehicle = TextEditingController();
  final _charge  = TextEditingController(text: '150');
  final _pass    = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Row(children: [SvgIcon(AppIcons.personAddRounded, color: kPrimary, size: 20), SizedBox(width: 8), Text('Add New Rider', style: TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 15))]),
    content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      fieldWidget('Rider Name *', _name, 'e.g. Ali Hassan'), const SizedBox(height: 12),
      fieldWidget('Phone *', _phone, '0300-1111111', kt: TextInputType.phone), const SizedBox(height: 12),
      fieldWidget('Vehicle', _vehicle, 'Bike 🏍 ABC-123'), const SizedBox(height: 12),
      fieldWidget('Charge per Delivery (£)', _charge, '150', kt: TextInputType.number), const SizedBox(height: 12),
      _passwordField(_pass, 'Min 6 characters — leave empty for no app access'),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () {
          if (_name.text.trim().isEmpty) return;
          Navigator.pop(context, {
            'name': _name.text.trim(), 'phone': _phone.text.trim(),
            'vehicle': _vehicle.text.trim(), 'charge': double.tryParse(_charge.text) ?? 150,
            'password': _pass.text,
          });
        },
        child: const Text('Add Rider', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ── Edit Rider Dialog ─────────────────────────────────────────────────────────
class _EditRiderDlg extends StatefulWidget {
  final Rider rider;
  const _EditRiderDlg({required this.rider});
  @override State<_EditRiderDlg> createState() => _EditRiderDlgState();
}

class _EditRiderDlgState extends State<_EditRiderDlg> {
  late final _name    = TextEditingController(text: widget.rider.name);
  late final _phone   = TextEditingController(text: widget.rider.phone);
  late final _vehicle = TextEditingController(text: widget.rider.vehicle);
  late final _charge  = TextEditingController(text: amountInputText(widget.rider.chargePerDelivery));
  final _pass = TextEditingController();
  bool _removeLogin = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('Edit: ${widget.rider.name}', style: const TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 15)),
    content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      fieldWidget('Name', _name, ''), const SizedBox(height: 12),
      fieldWidget('Phone', _phone, '', kt: TextInputType.phone), const SizedBox(height: 12),
      fieldWidget('Vehicle', _vehicle, ''), const SizedBox(height: 12),
      fieldWidget('Charge/Delivery (£)', _charge, '', kt: TextInputType.number), const SizedBox(height: 12),
      if (!_removeLogin)
        _passwordField(_pass, widget.rider.hasLogin
            ? 'Leave empty to keep the current password'
            : 'Min 6 characters — gives this rider app access'),
      if (widget.rider.hasLogin)
        CheckboxListTile(
          value: _removeLogin,
          onChanged: (v) => setState(() => _removeLogin = v ?? false),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: kRed,
          title: const Text('Remove Rider app access', style: TextStyle(fontSize: 12, color: kSub)),
        ),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () => Navigator.pop(context, {
          'name': _name.text.trim(), 'phone': _phone.text.trim(),
          'vehicle': _vehicle.text.trim(), 'charge': double.tryParse(_charge.text) ?? 150,
          'password': _removeLogin ? '' : _pass.text, 'removeLogin': _removeLogin,
        }),
        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

/// Password for the Rider mobile app; riders sign in with their phone + this.
Widget _passwordField(TextEditingController c, String hint) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Rider App Password', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSub)),
      const SizedBox(height: 5),
      TextField(
          controller: c,
          obscureText: true,
          style: const TextStyle(fontSize: 13, color: kText),
          decoration: dec(hint: hint)),
    ]);
