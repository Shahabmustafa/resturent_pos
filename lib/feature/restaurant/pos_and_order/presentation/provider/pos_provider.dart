import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../../cash/data/datasource/cash_datasource.dart';
import '../../../cash/presentation/provider/cash_provider.dart';
import '../../../dashboard/presentation/provider/dashboard_provider.dart';
import '../../../table/presentation/provider/table_provider.dart';
import '../../../setting/presentation/provider/tax_provider.dart';
import '../../data/datasource/pos_remote_datasource.dart';
import '../../data/model/order_model.dart';

final posDatasourceProvider = Provider<PosRemoteDatasource>(
        (_) => PosRemoteDatasource(Supabase.instance.client));
final cashDatasourceProvider = Provider<CashRemoteDatasource>(
        (_) => CashRemoteDatasource(Supabase.instance.client));

// ── State ─────────────────────────────────────────────────────────────────────
class PosState {
  final List<MenuProduct>      menuItems;
  final List<MenuProduct>      deals;
  final List<PosTableModel>    tables;
  final List<PosCustomerModel> customers;
  final List<PosRiderModel>    availableRiders;   // ── NEW
  final List<OrderModel>       recentOrders;
  final bool                   isLoading;
  final bool                   isPlacing;
  final String?                error;
  final OrderModel?            lastPlaced;

  final List<CartItem> cart;
  final double         discountPct;
  final double         discountFlat;
  final String         orderType;
  final String         customerType;
  final String         paymentMethod;
  final String         paymentStatus;
  final String         selectedTable;
  final String         customerName;
  final String         customerPhone;
  final String         orderNotes;
  final String?        selectedCustomerId;
  final double         taxRate;
  final String         deliveryAddress;
  final String?        selectedRiderId;           // ── NEW

  const PosState({
    this.menuItems        = const [],
    this.deals            = const [],
    this.tables           = const [],
    this.customers        = const [],
    this.availableRiders  = const [],             // ── NEW
    this.recentOrders     = const [],
    this.isLoading        = false,
    this.isPlacing        = false,
    this.error,
    this.lastPlaced,
    this.cart              = const [],
    this.discountPct       = 0,
    this.discountFlat      = 0,
    this.orderType         = 'Dine-in',
    this.customerType      = 'Walk-in',
    this.paymentMethod     = 'Cash',
    this.paymentStatus     = 'Unpaid',
    this.selectedTable     = '',
    this.customerName      = '',
    this.customerPhone     = '',
    this.orderNotes        = '',
    this.selectedCustomerId,
    this.taxRate           = 5.0,
    this.deliveryAddress   = '',
    this.selectedRiderId,                         // ── NEW
  });

  List<MenuProduct> get allProducts => [...menuItems, ...deals];
  double get subtotal    => cart.fold(0.0, (s, i) => s + i.total);
  double get discountAmt => (subtotal * discountPct / 100) + discountFlat;
  double get tax         => (subtotal - discountAmt) * (taxRate / 100);
  double get total       => subtotal - discountAmt + tax;

  PosState copyWith({
    List<MenuProduct>?      menuItems,
    List<MenuProduct>?      deals,
    List<PosTableModel>?    tables,
    List<PosCustomerModel>? customers,
    List<PosRiderModel>?    availableRiders,      // ── NEW
    List<OrderModel>?       recentOrders,
    bool?                   isLoading,
    bool?                   isPlacing,
    String?                 error,
    bool                    clearError      = false,
    OrderModel?             lastPlaced,
    bool                    clearLastPlaced = false,
    List<CartItem>?         cart,
    double?                 discountPct,
    double?                 discountFlat,
    String?                 orderType,
    String?                 customerType,
    String?                 paymentMethod,
    String?                 paymentStatus,
    String?                 selectedTable,
    String?                 customerName,
    String?                 customerPhone,
    String?                 orderNotes,
    Object?                 selectedCustomerId = _sentinel,
    double?                 taxRate,
    String?                 deliveryAddress,
    Object?                 selectedRiderId = _sentinel,   // ── NEW
  }) =>
      PosState(
        menuItems:       menuItems       ?? this.menuItems,
        deals:           deals           ?? this.deals,
        tables:          tables          ?? this.tables,
        customers:       customers       ?? this.customers,
        availableRiders: availableRiders ?? this.availableRiders,  // ── NEW
        recentOrders:    recentOrders    ?? this.recentOrders,
        isLoading:       isLoading       ?? this.isLoading,
        isPlacing:       isPlacing       ?? this.isPlacing,
        error:           clearError ? null : error ?? this.error,
        lastPlaced:      clearLastPlaced ? null : lastPlaced ?? this.lastPlaced,
        cart:            cart             ?? this.cart,
        discountPct:     discountPct      ?? this.discountPct,
        discountFlat:    discountFlat     ?? this.discountFlat,
        orderType:       orderType        ?? this.orderType,
        customerType:    customerType     ?? this.customerType,
        paymentMethod:   paymentMethod    ?? this.paymentMethod,
        paymentStatus:   paymentStatus    ?? this.paymentStatus,
        selectedTable:   selectedTable    ?? this.selectedTable,
        customerName:    customerName     ?? this.customerName,
        customerPhone:   customerPhone    ?? this.customerPhone,
        orderNotes:      orderNotes       ?? this.orderNotes,
        taxRate:         taxRate          ?? this.taxRate,
        deliveryAddress: deliveryAddress  ?? this.deliveryAddress,
        selectedCustomerId: identical(selectedCustomerId, _sentinel)
            ? this.selectedCustomerId
            : selectedCustomerId as String?,
        selectedRiderId: identical(selectedRiderId, _sentinel)   // ── NEW
            ? this.selectedRiderId
            : selectedRiderId as String?,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────
class PosNotifier extends StateNotifier<PosState> {
  final PosRemoteDatasource  _ds;
  final CashRemoteDatasource _cash;
  final String               _branchId;
  final Ref                  _ref;

  PosNotifier(this._ds, this._cash, this._branchId, this._ref)
      : super(const PosState()) {
    loadAll();

    _ref.listen(tablesRefreshProvider, (prev, next) async {
      if (!mounted) return;
      final tables = await _ds.fetchAvailableTables(_branchId);
      if (!mounted) return;
      state = state.copyWith(tables: tables);
    });
  }

  Future<void> loadAll() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final r = await Future.wait([
        _ds.fetchMenuItems(_branchId),
        _ds.fetchDeals(_branchId),
        _ds.fetchAvailableTables(_branchId),
        _ds.fetchCustomers(_branchId),
        _ds.fetchOrders(_branchId),
        _ds.fetchAvailableRiders(_branchId),      // ── NEW
      ]);
      if (!mounted) return;
      state = state.copyWith(
        menuItems:       r[0] as List<MenuProduct>,
        deals:           r[1] as List<MenuProduct>,
        tables:          r[2] as List<PosTableModel>,
        customers:       r[3] as List<PosCustomerModel>,
        recentOrders:    r[4] as List<OrderModel>,
        availableRiders: r[5] as List<PosRiderModel>, // ── NEW
        isLoading:       false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Refresh available riders (after delivery order placed) ────────────────
  Future<void> _refreshRiders() async {
    final riders = await _ds.fetchAvailableRiders(_branchId);
    if (!mounted) return;
    state = state.copyWith(availableRiders: riders);
  }

  // ── Cart mutations ────────────────────────────────────────────────────────
  void addToCart(MenuProduct p, {ProductSize? size}) {
    final cart = [...state.cart];
    final idx  = cart.indexWhere((c) => c.product.id == p.id && c.size?.id == size?.id);
    if (idx >= 0)
      cart[idx] = CartItem(cart[idx].product, qty: cart[idx].qty + 1, size: cart[idx].size);
    else
      cart.add(CartItem(p, size: size));
    state = state.copyWith(cart: cart);
  }

  void changeQty(CartItem item, int delta) {
    final cart = [...state.cart];
    final idx  = cart.indexWhere((c) => c.product.id == item.product.id && c.size?.id == item.size?.id);
    if (idx < 0) return;
    final newQty = cart[idx].qty + delta;
    if (newQty <= 0) cart.removeAt(idx);
    else             cart[idx] = CartItem(cart[idx].product, qty: newQty, size: cart[idx].size);
    state = state.copyWith(cart: cart);
  }

  void removeFromCart(CartItem item) {
    state = state.copyWith(cart: state.cart
        .where((c) => !(c.product.id == item.product.id && c.size?.id == item.size?.id))
        .toList());
  }

  void clearCart() => state = state.copyWith(
    cart: [], discountPct: 0, discountFlat: 0,
    orderNotes: '', customerName: '', customerPhone: '',
    selectedTable: '', selectedCustomerId: null,
    orderType: 'Dine-in', customerType: 'Walk-in',
    paymentMethod: 'Cash', paymentStatus: 'Unpaid',
    deliveryAddress: '', selectedRiderId: null,
  );

  // ── Field setters ─────────────────────────────────────────────────────────
  void setOrderType(String v)       => state = state.copyWith(
      orderType: v, selectedTable: '', deliveryAddress: '', selectedRiderId: null);
  void setCustomerType(String v)    => state = state.copyWith(
      customerType: v, selectedCustomerId: null, customerName: '', customerPhone: '');
  void setPaymentMethod(String v)   => state = state.copyWith(paymentMethod: v);
  void setPaymentStatus(String v)   => state = state.copyWith(paymentStatus: v);
  void setTable(String v)           => state = state.copyWith(selectedTable: v);
  void setCustomerName(String v)    => state = state.copyWith(customerName: v);
  void setCustomerPhone(String v)   => state = state.copyWith(customerPhone: v);
  void setNotes(String v)           => state = state.copyWith(orderNotes: v);
  void setDiscountPct(double v)     => state = state.copyWith(discountPct: v);
  void setDiscountFlat(double v)    => state = state.copyWith(discountFlat: v);
  void setTaxRate(double rate)      => state = state.copyWith(taxRate: rate);
  void setDeliveryAddress(String v) => state = state.copyWith(deliveryAddress: v);
  void setRider(String? id)         => state = state.copyWith(selectedRiderId: id); // ── NEW

  /// Picks a regular customer: fills name/phone and applies their saved discount.
  /// Passing null goes back to a walk-in and removes that discount.
  void selectCustomer(String? id) {
    final cust = id == null ? null : state.customers.where((c) => c.id == id).firstOrNull;
    state = state.copyWith(
      selectedCustomerId: cust?.id,
      customerName:  cust?.name  ?? '',
      customerPhone: cust?.phone ?? '',
      customerType:  cust == null ? 'Walk-in' : 'Regular',
      discountPct:   cust?.discount ?? 0,
    );
  }

  /// Reloads saved customers (e.g. someone just registered on the website).
  Future<void> refreshCustomers() async {
    try {
      final customers = await _ds.fetchCustomers(_branchId);
      if (mounted) state = state.copyWith(customers: customers);
    } catch (_) {}
  }

  /// Saves the typed name/phone as a regular customer and selects them.
  Future<void> saveAsRegular() async {
    final name  = state.customerName.trim();
    final phone = state.customerPhone.trim();
    if (name.isEmpty || phone.isEmpty) return;
    try {
      final cust = await _ds.addCustomer(_branchId, name, phone);
      if (!mounted) return;
      state = state.copyWith(customers: [...state.customers, cust]..sort((a, b) => a.name.compareTo(b.name)));
      selectCustomer(cust.id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  Future<bool> placeOrder() async {
    if (!mounted) return false;
    state = state.copyWith(isPlacing: true, clearError: true);
    try {
      final s = state;

      // Look up the selected rider's name (for the delivery_orders record)
      final selectedRider = s.availableRiders
          .where((r) => r.id == s.selectedRiderId)
          .firstOrNull;

      final order = await _ds.placeOrder(
        branchId:        _branchId,
        orderType:       s.orderType,
        customerType:    s.customerType,
        customerName:    s.customerName,
        customerPhone:   s.customerPhone,
        tableNumber:     s.selectedTable,
        paymentMethod:   s.paymentMethod,
        paymentStatus:   s.paymentStatus,
        subtotal:        s.subtotal,
        discountPct:     s.discountPct,
        discountFlat:    s.discountFlat,
        discountAmt:     s.discountAmt,
        taxAmt:          s.tax,
        total:           s.total,
        notes:           s.orderNotes,
        customerId:      s.selectedCustomerId,
        deliveryAddress: s.deliveryAddress,
        riderId:         s.selectedRiderId,        // ── NEW
        riderName:       selectedRider?.name,      // ── NEW
        items: s.cart.map((c) => {
          'menu_item_id': c.product.isDeal ? null : c.product.id,
          'item_name': c.displayName, 'item_emoji': '',
          'size': c.size?.name ?? '', 'unit_price': c.unitPrice,
          'qty': c.qty, 'total_price': c.total,
        }).toList(),
      );

      if (!mounted) return false;

      if (s.paymentStatus == 'Paid' && s.paymentMethod == 'Cash') {
        await _cash.updateCash(
          branchId: _branchId, amount: s.total, type: 'sale_in',
          refLabel: order.orderNumber, note: 'POS Sale — ${order.orderNumber}',
        );
        if (!mounted) return false;
        _ref.read(cashProvider(_branchId).notifier).load();
      }

      final tables = await _ds.fetchAvailableTables(_branchId);
      if (!mounted) return false;
      // Order counts/totals changed for the linked customer.
      final customers = await _ds.fetchCustomers(_branchId);
      if (!mounted) return false;

      // The rider is busy after the order is placed — refresh the riders list
      if (s.orderType == 'Delivery' && s.selectedRiderId != null) {
        await _refreshRiders();
        if (!mounted) return false;
      }

      state = state.copyWith(
        isPlacing: false, lastPlaced: order,
        tables: tables, customers: customers, recentOrders: [order, ...state.recentOrders],
      );

      _ref.read(dashboardRefreshProvider.notifier).state++;

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isPlacing: false, error: e.toString());
      return false;
    }
  }

  // ── Update Order Status ───────────────────────────────────────────────────
  Future<void> updateStatus(String orderId, String status) async {
    if (!mounted) return;
    try {
      await _ds.updateStatus(orderId, status);
      if (!mounted) return;

      final order = state.recentOrders.where((o) => o.id == orderId).firstOrNull;
      if (order != null && order.tableNumber.isNotEmpty &&
          (status == 'completed' || status == 'cancelled')) {
        await _ds.freeTable(_branchId, order.tableNumber);
        if (!mounted) return;
        final tables = await _ds.fetchAvailableTables(_branchId);
        if (!mounted) return;
        state = state.copyWith(tables: tables);
      }

      if (!mounted) return;
      state = state.copyWith(
        recentOrders: state.recentOrders
            .map((o) => o.id == orderId ? o.copyWith(status: status) : o)
            .toList(),
      );

      _ref.read(dashboardRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Update Payment Status ─────────────────────────────────────────────────
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    if (!mounted) return;
    try {
      await _ds.updatePaymentStatus(orderId, paymentStatus);
      if (!mounted) return;

      final order = state.recentOrders.where((o) => o.id == orderId).firstOrNull;

      if (order != null && paymentStatus == 'Paid' && order.paymentStatus != 'Paid') {
        if (order.paymentMethod == 'Cash') {
          await _cash.updateCash(
            branchId: _branchId, amount: order.total, type: 'sale_in',
            refLabel: order.orderNumber, note: 'POS Sale — ${order.orderNumber}',
          );
          if (!mounted) return;
        }
        _ref.read(cashProvider(_branchId).notifier).load();
      }

      if (order != null && paymentStatus == 'Paid' &&
          order.orderType == 'Dine-in' && order.tableNumber.isNotEmpty) {
        await _ds.freeTable(_branchId, order.tableNumber);
        if (!mounted) return;
        final tables = await _ds.fetchAvailableTables(_branchId);
        if (!mounted) return;
        state = state.copyWith(tables: tables);
      }

      if (!mounted) return;
      state = state.copyWith(
        recentOrders: state.recentOrders
            .map((o) => o.id == orderId ? o.copyWith(paymentStatus: paymentStatus) : o)
            .toList(),
      );

      _ref.read(dashboardRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  void clearLastPlaced() => state = state.copyWith(clearLastPlaced: true);
  void clearError()      => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  final ds       = ref.watch(posDatasourceProvider);
  final cash     = ref.watch(cashDatasourceProvider);
  final branchId = ref.watch(branchAuthProvider).branch!.branchId;
  final notifier = PosNotifier(ds, cash, branchId, ref);

  ref.listen<TaxState>(taxProvider, (_, next) {
    if (!next.loading && next.settings != null) {
      final rate = next.settings!.enableTax
          ? next.settings!.activeTaxRate
          : 0.0;
      notifier.setTaxRate(rate);
    }
  });

  return notifier;
});
