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
import '../../feature/restaurant/user_role/presentation/screen/user_role_screen.dart';
import '../../feature/restaurant/setting/presentation/provider/branch_setting_provider.dart';
import '../../feature/restaurant/order/presentation/provider/order_provider.dart';
import '../../feature/restaurant/cash_counter/presentation/cash_counter_screen.dart';
import '../../feature/restaurant/sales_dashboard/presentation/sales_dashboard_screen.dart';
import 'package:resturent_application/core/constants/currency.dart';

enum POSPage {
  dashboard, tables, menu, pos, order, kitchen, delivery, inventory,
  reports, customers, users, settings, cash, counter
}

class NavItem {
  final POSPage page;
  final AppIcon icon;
  final String label;
  const NavItem(this.page, this.icon, this.label);
}

// Simplified POS: only these sections are shown. The Kitchen Display, Inventory,
// Reports and Cash screens still exist — to bring one back, re-add its NavItem
// and role access. Orders go straight to Orders as
// 'pending' and are completed or cancelled there.
const navItems = [
  NavItem(POSPage.dashboard,  AppIcons.dashboardRounded,              'Dashboard'),
  NavItem(POSPage.pos,        AppIcons.pointOfSaleRounded,          'POS / Sale Invoice'),
  NavItem(POSPage.order,      AppIcons.receiptLongRounded,           'Orders'),
  NavItem(POSPage.customers,  AppIcons.peopleRounded,                'Customers'),
  NavItem(POSPage.counter,    AppIcons.paymentsRounded,              'Cash Counter'),
  NavItem(POSPage.delivery,   AppIcons.deliveryDiningRounded,        'Delivery'),
  NavItem(POSPage.tables,     AppIcons.tableRestaurantRounded,       'Table Management'),
  NavItem(POSPage.menu,       AppIcons.menuBookRounded,              'Menu & Categories'),
  NavItem(POSPage.users,      AppIcons.manageAccountsRounded,        'User Management'),
  NavItem(POSPage.settings,   AppIcons.settingsRounded,               'Settings'),
];

const _roleAccess = <String, Set<POSPage>>{
  'admin': {
    POSPage.dashboard, POSPage.pos, POSPage.order, POSPage.customers, POSPage.counter, POSPage.delivery,
    POSPage.tables, POSPage.menu, POSPage.users, POSPage.settings,
  },
  'manager': {
    POSPage.dashboard, POSPage.pos, POSPage.order, POSPage.customers, POSPage.counter, POSPage.delivery,
    POSPage.tables, POSPage.menu,
  },
  'cashier': {
    POSPage.pos, POSPage.order, POSPage.customers, POSPage.counter,
  },
  // Kitchen Display is hidden, so chefs work from Orders.
  'chef': {
    POSPage.order,
  },
  'rider': {
    POSPage.delivery,
  },
  'waiter': {
    POSPage.pos, POSPage.tables, POSPage.order,
  },
};

Set<POSPage> _allowedPages(String? role) {
  if (role == null) return {};
  return _roleAccess[role.toLowerCase()] ?? _roleAccess['cashier']!;
}

POSPage _defaultPage(String? role) {
  final allowed = _allowedPages(role);
  for (final item in navItems) {
    if (allowed.contains(item.page)) return item.page;
  }
  return POSPage.pos;
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  POSPage? _currentPage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB91C1C))),
      );
    }

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB91C1C))),
      );
    }

    final role    = authState.branch?.role;
    final allowed = _allowedPages(role);

    if (_currentPage == null || !allowed.contains(_currentPage)) {
      _currentPage = _defaultPage(role);
    }

    void navigate(POSPage page) {
      if (!allowed.contains(page)) return;
      setState(() => _currentPage = page);
    }

    void navigateFromDrawer(POSPage page) {
      if (!allowed.contains(page)) return;
      Navigator.pop(context);
      setState(() => _currentPage = page);
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

    // Branch name + address from branchSettingsProvider (saved in company_tab)
    // Fallback: branchAuthProvider's name (set at login)
    final settingsState = ref.watch(branchSettingsProvider);
    final branchName = settingsState.branch?.restaurantName.isNotEmpty == true
        ? settingsState.branch!.restaurantName
        : settingsState.branch?.name.isNotEmpty == true
        ? settingsState.branch!.name
        : authState.branch?.name ?? 'Restaurant';
    final branchAddress = settingsState.branch?.address ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: _POSDrawer(
        current:     _currentPage!,
        allowed:     allowed,
        onNavigate:  navigateFromDrawer,
        role:        role,
        branchName:  branchName,
        branchAddress: branchAddress,
      ),
      body: Stack(children: [
        Row(children: [
          if (MediaQuery.of(context).size.width >= 1100)
            _SideNav(
              current:      _currentPage!,
              allowed:      allowed,
              onNavigate:   navigate,
              role:         role,
              branchName:   branchName,
              branchAddress: branchAddress,
            ),
          Expanded(child: _pageContent(_currentPage!)),
        ]),
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
      ]),
    );
  }

  Widget _pageContent(POSPage page) {
    switch (page) {
      case POSPage.dashboard:  return const SalesDashboardScreen();
      case POSPage.tables:     return const TablePage();
      case POSPage.menu:       return const MenuManagementPage();
      case POSPage.pos:        return const POSScreen();
      case POSPage.order:      return const OrdersScreen();
      case POSPage.kitchen:    return const KDSPage();
      case POSPage.inventory:  return InventoryPage();
      case POSPage.delivery:   return const DeliveryPage();
      case POSPage.reports:    return const FinancialReportsScreen();
      case POSPage.customers:  return const CustomerPage();
      case POSPage.users:      return const UserManagementPage();
      case POSPage.settings:   return const SettingsScreen();
      case POSPage.cash:       return const CashScreen();
      case POSPage.counter:    return const CashCounterScreen();
      default:
        return ComingSoonPage(navItems.firstWhere((n) => n.page == page).label);
    }
  }
}

// ── Side Nav ──────────────────────────────────────────────────────────────────
class _SideNav extends StatelessWidget {
  final POSPage current;
  final Set<POSPage> allowed;
  final ValueChanged<POSPage> onNavigate;
  final String? role;
  final String branchName;
  final String branchAddress;

  const _SideNav({
    required this.current,
    required this.allowed,
    required this.onNavigate,
    required this.role,
    required this.branchName,
    required this.branchAddress,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 236,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: Color(0xFFE8EAF0))),
    ),
    child: Column(children: [
      _DrawerHeader(
        branchName: branchName,
        branchAddress: branchAddress,
        topPadding: 22,
      ),
      const _SectionLabel('MENU'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          children: navItems
              .where((item) => allowed.contains(item.page))
              .map((item) => _NavTile(item: item, current: current, onTap: onNavigate))
              .toList(),
        ),
      ),
      const _DrawerFooter(),
    ]),
  );
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _POSDrawer extends StatelessWidget {
  final POSPage current;
  final Set<POSPage> allowed;
  final ValueChanged<POSPage> onNavigate;
  final String? role;
  final String branchName;
  final String branchAddress;

  const _POSDrawer({
    required this.current,
    required this.allowed,
    required this.onNavigate,
    required this.role,
    required this.branchName,
    required this.branchAddress,
  });

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: const Color(0xFFFAFBFF),
    width: 240,
    child: Column(children: [
      _DrawerHeader(branchName: branchName, branchAddress: branchAddress),
      const _SectionLabel('MENU'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          children: navItems
              .where((item) => allowed.contains(item.page))
              .map((item) => _NavTile(item: item, current: current, onTap: onNavigate))
              .toList(),
        ),
      ),
      const _DrawerFooter(),
    ]),
  );
}

// ── Drawer Header — branch name dynamic ───────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String branchName;
  final String branchAddress;
  // The mobile drawer needs extra room for the status bar.
  final double topPadding;
  const _DrawerHeader({
    required this.branchName,
    required this.branchAddress,
    this.topPadding = 40,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(18, topPadding, 18, 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE8EAF0))),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB91C1C), Color(0xFFF87171)],
          ),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB91C1C).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const SvgIcon(AppIcons.restaurantRounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          branchName,
          style: const TextStyle(color: Color(0xFF1A1D3A), fontSize: 15, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Address or fallback subtitle
        Text(
          branchAddress.isNotEmpty ? branchAddress : 'POS System v2.1',
          style: const TextStyle(color: Color(0xFF9396B0), fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ])),
    ]),
  );
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
            color: Color(0xFFA6A9C0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          )),
    ),
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _DrawerFooter extends ConsumerWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(branchAuthProvider).branch;
    final roleLabel = (user?.role ?? '')
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFB91C1C).withOpacity(0.15),
          child: Text(
            (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
            style: const TextStyle(
                color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.name ?? 'User',
              style: const TextStyle(
                  color: Color(0xFF1A1D3A), fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          Text(roleLabel,
              style: const TextStyle(color: Color(0xFF9396B0), fontSize: 11)),
        ])),
        IconButton(
          tooltip: 'Logout',
          splashRadius: 18,
          icon: const SvgIcon(AppIcons.logoutRounded, color: Color(0xFF9396B0), size: 18),
          onPressed: () => _confirmLogout(context, ref),
        ),
      ]),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9396B0))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(branchAuthProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final NavItem item;
  final POSPage current;
  final ValueChanged<POSPage> onTap;
  const _NavTile({required this.item, required this.current, required this.onTap});

  static const _primary = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final isActive = item.page == current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFF1F2F8),
          splashColor: _primary.withOpacity(0.08),
          highlightColor: _primary.withOpacity(0.04),
          mouseCursor: SystemMouseCursors.click,
          onTap: () => onTap(item.page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(0, 11, 12, 11),
            decoration: BoxDecoration(
              color: isActive ? _primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              // Accent bar marking the active item
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive ? _primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 11),
              SvgIcon(item.icon, size: 20,
                  color: isActive ? _primary : const Color(0xFF9396B0)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? _primary : const Color(0xFF5A5E80),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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
    final name     = (order['customer_name'] as String?)?.trim();
    final phone    = (order['customer_phone'] as String?)?.trim() ?? '';
    final number   = order['order_number'] as String? ?? '';
    final delivery = order['order_type'] == 'Delivery';
    final table    = order['order_type'] == 'Dine-in' ? (order['table_number'] as String? ?? '') : '';
    final total    = double.tryParse('${order['total'] ?? 0}') ?? 0; // numeric may arrive as text
    // Website notes look like "Online order (website) • Address: … • extra spicy".
    final address = ((order['notes'] as String?) ?? '')
        .split(' • ')
        .where((p) => p.startsWith('Address: '))
        .map((p) => p.substring('Address: '.length))
        .firstOrNull;
    final created = DateTime.tryParse(order['created_at'] as String? ?? '')?.toLocal();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset((1 - t) * 60, 0), child: child),
      ),
      child: Container(
        width: 360,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAF0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            color: _primary,
            child: Row(children: [
              const SvgIcon(AppIcons.receiptLongRounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(table.isNotEmpty ? 'New table order — Table $table' : 'New website order',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              if (created != null)
                Text(DateFormat('h:mm a').format(created),
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
              IconButton(
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const SvgIcon(AppIcons.closeRounded, size: 16, color: Colors.white),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _primary.withOpacity(0.1),
                  child: Text(
                    (name?.isNotEmpty == true ? name![0] : '?').toUpperCase(),
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${name?.isNotEmpty == true ? name : 'A customer'} placed an order',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF1A1D3A), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (phone.isNotEmpty)
                      Text(phone, style: const TextStyle(color: Color(0xFF6B6F90), fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _AlertChip(number),
                if (table.isNotEmpty)
                  _AlertChip('Dine-in · Table $table', icon: AppIcons.tableRestaurantRounded)
                else
                  _AlertChip(delivery ? 'Delivery' : 'Takeaway',
                      icon: delivery ? AppIcons.deliveryDiningRounded : AppIcons.takeoutDiningRounded),
                _AlertChip(formatMoney(total), strong: true),
              ]),
              if (delivery && address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SvgIcon(AppIcons.locationOnOutlined, size: 14, color: Color(0xFF9396B0)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6B6F90), fontSize: 12)),
                  ),
                ]),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  onPressed: onView,
                  child: const Text('View Order', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
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
      color: strong ? const Color(0xFFB91C1C).withOpacity(0.08) : const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        SvgIcon(icon, size: 13, color: const Color(0xFF6B6F90)),
        const SizedBox(width: 4),
      ],
      Text(label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? const Color(0xFFB91C1C) : const Color(0xFF1A1D3A),
          )),
    ]),
  );
}

// ── Coming Soon ───────────────────────────────────────────────────────────────
class ComingSoonPage extends StatelessWidget {
  final String title;
  const ComingSoonPage(this.title);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: const SvgIcon(AppIcons.constructionRounded, size: 48, color: Color(0xFFB91C1C)),
      ),
      const SizedBox(height: 24),
      Text(title, style: const TextStyle(
          color: Color(0xFF1A1D3A), fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('This screen is under development',
          style: TextStyle(color: Color(0xFF9396B0), fontSize: 14)),
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
    ]),
  );
}