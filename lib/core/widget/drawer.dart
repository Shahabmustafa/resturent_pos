import 'package:resturent_application/core/constants/app_info.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/feature/restaurant/cash/presentation/screen/cash_screen.dart';
import 'package:resturent_application/feature/restaurant/financial_reports/financial_reports/screens/financial_reports_screen.dart';
import 'package:resturent_application/feature/restaurant/order/presentation/screen/order_screen.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/screen/setting_screen.dart';
import '../../feature/delivery/presentation/screen/delivery_screen.dart';
import '../../feature/inventory/presentation/screen/invenory_screen.dart';
import '../../feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import '../../feature/restaurant/auth/presentation/screen/branch_auth_screen.dart';
import '../../feature/restaurant/customer/presentation/screen/customer_screen.dart';
import '../../feature/restaurant/kitchen/presentation/screen/kitchen_screen.dart';
import '../../feature/restaurant/menu_and_category/presentation/screen/menu_and_category_screen.dart';
import '../../feature/restaurant/pos_and_order/presentation/screen/pos_and_order_screen.dart';
import '../../feature/restaurant/table/presentation/screen/table_screen.dart';
import '../../feature/restaurant/table/presentation/screen/table_grid_screen.dart';
import '../../feature/restaurant/user_role/presentation/screen/user_role_screen.dart';
import '../../feature/restaurant/setting/presentation/provider/branch_setting_provider.dart';
import '../../feature/restaurant/order/presentation/provider/order_provider.dart';
import '../../feature/restaurant/cash_counter/presentation/cash_counter_screen.dart';
import '../../feature/restaurant/reports/presentation/sales_report_screen.dart';
import '../../feature/restaurant/manage/presentation/manage_screen.dart';
import '../../feature/restaurant/live_orders/presentation/live_orders_screen.dart';
import '../../feature/restaurant/till/presentation/till_screen.dart';
import '../../feature/restaurant/notes/presentation/notes_screen.dart';
import '../../feature/restaurant/home/presentation/screen/pos_home_screen.dart';
import '../../feature/restaurant/customer_lookup/presentation/collection_flow.dart';
import '../../feature/restaurant/pos_and_order/presentation/provider/pos_provider.dart';
import '../../feature/restaurant/sales_dashboard/presentation/sales_dashboard_screen.dart';
import 'package:resturent_application/core/constants/currency.dart';

enum POSPage {
  dashboard,
  tables,
  menu,
  pos,
  order,
  kitchen,
  delivery,
  inventory,
  reports,
  customers,
  users,
  settings,
  cash,
  counter,
  notes,
  live,
  till,
  restaurant,
  manage,
  salesReport,
}

class NavItem {
  final POSPage page;
  final AppIcon icon;
  final String label;
  const NavItem(this.page, this.icon, this.label);
}

// Simplified POS: only these sections are shown (as home screen tiles). The
// Kitchen Display, Inventory, Reports and Cash screens still exist — to bring one
// back, re-add its NavItem, a home tile and role access. Orders go straight to Orders as
// 'pending' and are completed or cancelled there.
const navItems = [
  NavItem(POSPage.dashboard, AppIcons.dashboardRounded, 'Dashboard'),
  NavItem(POSPage.pos, AppIcons.pointOfSaleRounded, 'POS / Sale Invoice'),
  NavItem(POSPage.order, AppIcons.receiptLongRounded, 'Orders'),
  NavItem(POSPage.customers, AppIcons.peopleRounded, 'Customers'),
  NavItem(POSPage.counter, AppIcons.paymentsRounded, 'Cash Counter'),
  NavItem(POSPage.delivery, AppIcons.deliveryDiningRounded, 'Delivery'),
  NavItem(POSPage.tables, AppIcons.tableRestaurantRounded, 'Table Management'),
  NavItem(POSPage.menu, AppIcons.menuBookRounded, 'Menu & Categories'),
  NavItem(POSPage.users, AppIcons.manageAccountsRounded, 'User Management'),
  NavItem(POSPage.settings, AppIcons.settingsRounded, 'Settings'),
  NavItem(POSPage.live, AppIcons.dashboardRounded, 'Dash'),
  NavItem(POSPage.till, AppIcons.pointOfSaleRounded, 'Open Till'),
  NavItem(POSPage.salesReport, AppIcons.barChartRounded, 'Report'),
  NavItem(POSPage.manage, AppIcons.tuneRounded, 'Manage'),
  NavItem(POSPage.notes, AppIcons.stickyNote2Rounded, 'Notes'),
];

const _roleAccess = <String, Set<POSPage>>{
  'admin': {
    POSPage.dashboard,
    POSPage.pos,
    POSPage.order,
    POSPage.customers,
    POSPage.counter,
    POSPage.till,
    POSPage.delivery,
    POSPage.tables,
    POSPage.restaurant,
    POSPage.menu,
    POSPage.users,
    POSPage.settings,
    POSPage.notes,
    POSPage.live,
    POSPage.manage,
    POSPage.salesReport,
  },
  'manager': {
    POSPage.dashboard,
    POSPage.pos,
    POSPage.order,
    POSPage.customers,
    POSPage.counter,
    POSPage.till,
    POSPage.delivery,
    POSPage.tables,
    POSPage.restaurant,
    POSPage.menu,
    POSPage.notes,
    POSPage.live,
    POSPage.manage,
    POSPage.salesReport,
  },
  'cashier': {
    POSPage.pos,
    POSPage.restaurant,
    POSPage.order,
    POSPage.customers,
    POSPage.counter,
    POSPage.till,
    POSPage.notes,
    POSPage.live,
  },
  // Kitchen Display is hidden, so chefs work from Orders.
  'chef': {POSPage.order},
  'rider': {POSPage.delivery},
  'waiter': {
    POSPage.pos,
    POSPage.tables,
    POSPage.restaurant,
    POSPage.order,
    POSPage.notes,
    POSPage.live,
  },
};

Set<POSPage> _allowedPages(String? role) {
  if (role == null) return {};
  return _roleAccess[role.toLowerCase()] ?? _roleAccess['cashier']!;
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // null = the home tile screen.
  POSPage? _currentPage;
  // Collection customer lookup is showing (before POS opens).
  bool _collection = false;
  // Delivery customer lookup is showing (before POS opens).
  bool _delivery = false;
  // Website orders not yet dismissed (raw `orders` rows from realtime).
  final List<Map<String, dynamic>> _alerts = [];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(branchAuthProvider);

    if (!authState.isLoading && !authState.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BranchLoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
        ),
      );
    }

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
        ),
      );
    }

    final role = authState.branch?.role;
    final allowed = _allowedPages(role);

    if (_currentPage != null && !allowed.contains(_currentPage)) {
      _currentPage = null;
    }

    void navigate(POSPage? page) {
      if (page != null && !allowed.contains(page)) return;
      setState(() {
        _collection = false;
        _delivery = false;
        _currentPage = page;
      });
    }

    void startSale(String orderType) {
      // Delivery and Collection ask for the customer before POS opens.
      if (orderType == 'Delivery' || orderType == 'Collection') {
        setState(() {
          _currentPage = null;
          _delivery = orderType == 'Delivery';
          _collection = orderType == 'Collection';
        });
        return;
      }
      // SHOP is a walk-in Takeaway sale that keeps its own label.
      final shop = orderType == 'Shop';
      ref
          .read(posProvider.notifier)
          .setOrderType(shop ? 'Takeaway' : orderType, shop: shop);
      navigate(POSPage.pos);
    }

    // New website or table QR order: show who ordered, on whatever screen staff are on.
    ref.listen(onlineOrderAlertsProvider, (_, next) {
      final order = next.value;
      if (order == null || !allowed.contains(POSPage.order)) return;
      if (_alerts.any((a) => a['id'] == order['id'])) return;
      SystemSound.play(SystemSoundType.alert);
      setState(() {
        _alerts.insert(0, order);
        if (_alerts.length > 4) _alerts.removeLast();
      });
    });

    void dismissAlert(Map<String, dynamic> order) =>
        setState(() => _alerts.removeWhere((a) => a['id'] == order['id']));

    void viewAlert(Map<String, dynamic> order) {
      dismissAlert(order);
      navigate(POSPage.order);
      // Open the order's detail panel if the list already has it.
      final orders = ref.read(orderProvider).orders;
      final match = orders.where((o) => o.id == order['id']).firstOrNull;
      if (match != null) ref.read(orderProvider.notifier).select(match);
    }

    // Branch name from branchSettingsProvider (saved in company_tab)
    // Fallback: branchAuthProvider's name (set at login)
    final settingsState = ref.watch(branchSettingsProvider);
    final branchName = settingsState.branch?.restaurantName.isNotEmpty == true
        ? settingsState.branch!.restaurantName
        : settingsState.branch?.name.isNotEmpty == true
        ? settingsState.branch!.name
        : authState.branch?.name ?? kAppName;

    Future<void> startCollection(String? customerId) async {
      final pos = ref.read(posProvider.notifier);
      pos.setOrderType('Takeaway');
      if (customerId != null) await pos.useCustomer(customerId);
      if (mounted) navigate(POSPage.pos);
    }

    Future<void> startDelivery(
      String? customerId,
      double charge,
      String address,
    ) async {
      final pos = ref.read(posProvider.notifier);
      pos.setOrderType('Delivery');
      pos.setDeliveryCharge(charge);
      pos.setDeliveryAddress(address);
      if (customerId != null) await pos.useCustomer(customerId);
      if (mounted) navigate(POSPage.pos);
    }

    final b = settingsState.branch;
    final page = _currentPage;
    return Scaffold(
      body: Stack(
        children: [
          if (_collection)
            CollectionFlow(
              onBack: () => navigate(null),
              onStartSale: startSale,
              onSkip: () => startCollection(null),
              onConfirm: startCollection,
            )
          else if (_delivery)
            CollectionFlow(
              saleLabel: 'DELIVERY',
              onBack: () => navigate(null),
              onStartSale: startSale,
              onSkip: () => startDelivery(null, 0, ''),
              onConfirm: (_) {},
              onDelivery: startDelivery,
            )
          else if (page == null)
            POSHomeScreen(
              allowed: allowed,
              onOpen: navigate,
              onStartSale: startSale,
              onCollection: () => setState(() => _collection = true),
              onLock: () {
                setState(() {
                  _currentPage = null;
                  _collection = false;
                });
                ref.read(branchAuthProvider.notifier).logout();
              },
              branchName: branchName,
              branchDetails: [
                for (final v in [
                  b?.address,
                  b?.city,
                  b?.phone,
                  b?.email,
                  b?.website,
                ])
                  if (v != null && v.trim().isNotEmpty) v.trim(),
              ],
            )
          else if (page == POSPage.live)
            LiveOrdersScreen(
              onHome: () => navigate(null),
              onStartSale: startSale,
              onCollection: () => setState(() => _collection = true),
              onOrders: () => navigate(POSPage.order),
              onOpenOrder: (o) {
                navigate(POSPage.order);
                ref.read(orderProvider.notifier).select(o);
              },
            )
          else if (page == POSPage.restaurant)
            TableGridScreen(
              onBack: () => navigate(null),
              onSelect: (number) {
                final pos = ref.read(posProvider.notifier);
                pos.setOrderType('Dine-in');
                pos.setTable(number);
                navigate(POSPage.pos);
              },
            )
          else if (page == POSPage.customers)
            CustomerPage(
              onBack: () => navigate(null),
              onStartSale: (type, customer) async {
                final pos = ref.read(posProvider.notifier);
                pos.setOrderType(type);
                if (type == 'Delivery') {
                  pos.setDeliveryAddress(
                    [
                      customer.address,
                      customer.city,
                      customer.postcode,
                    ].where((s) => s.trim().isNotEmpty).join(', '),
                  );
                }
                await pos.useCustomer(customer.id!);
                if (mounted) navigate(POSPage.pos);
              },
              onReorder: (customer, order) async {
                final pos = ref.read(posProvider.notifier);
                pos.setOrderType('Takeaway');
                await pos.useCustomer(customer.id!);
                final skipped = pos.reorder([
                  for (final l in order.lines)
                    (
                      menuItemId: l.menuItemId,
                      name: l.name,
                      size: l.size,
                      qty: l.qty,
                    ),
                ]);
                if (!mounted) return;
                navigate(POSPage.pos);
                if (skipped > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$skipped item(s) are no longer on the menu and were skipped',
                      ),
                    ),
                  );
                }
              },
            )
          else if (page == POSPage.order)
            OrdersScreen(onBack: () => navigate(null))
          else if (page == POSPage.salesReport)
            SalesReportScreen(
              onBack: () => navigate(null),
              onShiftReport: () => navigate(POSPage.counter),
            )
          else if (page == POSPage.manage)
            ManageScreen(
              onBack: () => navigate(null),
              onMenu: () => navigate(POSPage.menu),
              onDeliveries: allowed.contains(POSPage.delivery)
                  ? () => navigate(POSPage.delivery)
                  : null,
              onUsers: allowed.contains(POSPage.users)
                  ? () => navigate(POSPage.users)
                  : null,
              onSettings: allowed.contains(POSPage.settings)
                  ? () => navigate(POSPage.settings)
                  : null,
              // Receipts are printed from the order's detail panel: open the latest order.
              onReprint: () {
                navigate(POSPage.order);
                final orders = ref.read(orderProvider).orders;
                if (orders.isNotEmpty)
                  ref.read(orderProvider.notifier).select(orders.first);
              },
            )
          else if (page == POSPage.till)
            TillScreen(
              onBack: () => navigate(null),
              onCounter: () => navigate(POSPage.counter),
            )
          // The desktop till has its own HOME button in its bottom bar.
          else if (page == POSPage.pos &&
              MediaQuery.of(context).size.width >= 800)
            POSScreen(
              onHome: () => navigate(null),
              onOrders: allowed.contains(POSPage.order)
                  ? () => navigate(POSPage.order)
                  : null,
            )
          else
            Column(
              children: [
                _PageTopBar(
                  title: navItems.firstWhere((n) => n.page == page).label,
                  onHome: () => navigate(null),
                ),
                Expanded(child: _pageContent(page)),
              ],
            ),
          // Website order notifications, newest on top.
          if (_alerts.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in _alerts)
                      _OrderAlertCard(
                        key: ValueKey(a['id']),
                        order: a,
                        onView: () => viewAlert(a),
                        onDismiss: () => dismissAlert(a),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pageContent(POSPage page) {
    switch (page) {
      case POSPage.dashboard:
        return const SalesDashboardScreen();
      case POSPage.tables:
        return const TablePage();
      case POSPage.menu:
        return const MenuManagementPage();
      case POSPage.pos:
        return const POSScreen();
      case POSPage.order:
        return const SizedBox.shrink();
      case POSPage.kitchen:
        return const KDSPage();
      case POSPage.inventory:
        return InventoryPage();
      case POSPage.delivery:
        return const DeliveryPage();
      case POSPage.reports:
        return const FinancialReportsScreen();
      case POSPage.customers:
        return const SizedBox.shrink();
      case POSPage.users:
        return const UserManagementPage();
      case POSPage.settings:
        return const SettingsScreen();
      case POSPage.cash:
        return const CashScreen();
      case POSPage.counter:
        return const CashCounterScreen();
      case POSPage.notes:
        return const NotesScreen();
      case POSPage.live:
        return const SizedBox.shrink();
      case POSPage.till:
        return const SizedBox.shrink();
      case POSPage.manage:
        return const SizedBox.shrink();
      case POSPage.salesReport:
        return const SizedBox.shrink();
      case POSPage.restaurant:
        return const SizedBox.shrink();
    }
  }
}

// ── Page Top Bar ──────────────────────────────────────────────────────────────
/// Thin bar above every section with a button back to the home tiles.
class _PageTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onHome;
  const _PageTopBar({required this.title, required this.onHome});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE8EAF0))),
    ),
    child: Row(
      children: [
        Material(
          color: const Color(0xFF1D5FBF),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onHome,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  SvgIcon(
                    AppIcons.arrowBackRounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'HOME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1D3A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// ── Website Order Alert ───────────────────────────────────────────────────────
/// Slides in when a customer places an order on the website: who ordered,
/// what kind of order, and the total. Stays until viewed or closed.
class _OrderAlertCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const _OrderAlertCard({
    super.key,
    required this.order,
    required this.onView,
    required this.onDismiss,
  });

  static const _primary = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final name = (order['customer_name'] as String?)?.trim();
    final phone = (order['customer_phone'] as String?)?.trim() ?? '';
    final number = order['order_number'] as String? ?? '';
    final delivery = order['order_type'] == 'Delivery';
    final table = order['order_type'] == 'Dine-in'
        ? (order['table_number'] as String? ?? '')
        : '';
    final total =
        double.tryParse('${order['total'] ?? 0}') ??
        0; // numeric may arrive as text
    // Website notes look like "Online order (website) • Address: … • extra spicy".
    final address = ((order['notes'] as String?) ?? '')
        .split(' • ')
        .where((p) => p.startsWith('Address: '))
        .map((p) => p.substring('Address: '.length))
        .firstOrNull;
    final created = DateTime.tryParse(
      order['created_at'] as String? ?? '',
    )?.toLocal();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((1 - t) * 60, 0),
          child: child,
        ),
      ),
      child: Container(
        width: 360,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              color: _primary,
              child: Row(
                children: [
                  const SvgIcon(
                    AppIcons.receiptLongRounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      table.isNotEmpty
                          ? 'New table order — Table $table'
                          : 'New website order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (created != null)
                    Text(
                      DateFormat('h:mm a').format(created),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: const SvgIcon(
                      AppIcons.closeRounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _primary.withOpacity(0.1),
                        child: Text(
                          (name?.isNotEmpty == true ? name![0] : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${name?.isNotEmpty == true ? name : 'A customer'} placed an order',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1A1D3A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: Color(0xFF6B6F90),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _AlertChip(number),
                      if (table.isNotEmpty)
                        _AlertChip(
                          'Dine-in · Table $table',
                          icon: AppIcons.tableRestaurantRounded,
                        )
                      else
                        _AlertChip(
                          delivery ? 'Delivery' : 'Takeaway',
                          icon: delivery
                              ? AppIcons.deliveryDiningRounded
                              : AppIcons.takeoutDiningRounded,
                        ),
                      _AlertChip(formatMoney(total), strong: true),
                    ],
                  ),
                  if (delivery && address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SvgIcon(
                          AppIcons.locationOnOutlined,
                          size: 14,
                          color: Color(0xFF9396B0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B6F90),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: onView,
                      child: const Text(
                        'View Order',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

class _AlertChip extends StatelessWidget {
  final String label;
  final AppIcon? icon;
  final bool strong;

  const _AlertChip(this.label, {this.icon, this.strong = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: strong
          ? const Color(0xFFB91C1C).withOpacity(0.08)
          : const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          SvgIcon(icon, size: 13, color: const Color(0xFF6B6F90)),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? const Color(0xFFB91C1C) : const Color(0xFF1A1D3A),
          ),
        ),
      ],
    ),
  );
}

// ── Coming Soon ───────────────────────────────────────────────────────────────
class ComingSoonPage extends StatelessWidget {
  final String title;
  const ComingSoonPage(this.title);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8EAF0)),
          ),
          child: const SvgIcon(
            AppIcons.constructionRounded,
            size: 48,
            color: Color(0xFFB91C1C),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1D3A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This screen is under development',
          style: TextStyle(color: Color(0xFF9396B0), fontSize: 14),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFB91C1C)),
            foregroundColor: const Color(0xFFB91C1C),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: const Text('Coming Soon'),
        ),
      ],
    ),
  );
}
