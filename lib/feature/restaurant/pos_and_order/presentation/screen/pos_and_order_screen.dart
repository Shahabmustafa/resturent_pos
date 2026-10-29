import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/order_model.dart';
import '../provider/pos_provider.dart';
import '../widget/menu_panel_widget.dart';
import '../widget/cart_panel_widget.dart';
import '../widget/invoice_panel_widget.dart';
import '../widget/menu_grid_widget.dart';
import '../widget/size_options_widget.dart';
import '../widget/till_dialog.dart';
import 'package:resturent_application/core/constants/currency.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/provider/branch_auth_provider.dart';
import '../widget/till_bottom_bar_widget.dart';
import 'payment_screen.dart';

final _showCheckoutProvider = StateProvider<bool>((_) => false);
// Item whose sizes are showing in place of the menu grid (desktop till).
final _optionsProductProvider = StateProvider<MenuProduct?>((_) => null);

class POSScreen extends ConsumerWidget {
  /// Shown on the desktop till's bottom bar (the till has no top bar).
  final VoidCallback? onHome;
  final VoidCallback? onOrders;

  const POSScreen({super.key, this.onHome, this.onOrders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final showCheckout = ref.watch(_showCheckoutProvider);
    final optionsProduct = ref.watch(_optionsProductProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final cartIds = <String, int>{};
    for (final c in state.cart)
      cartIds[c.product.id] = (cartIds[c.product.id] ?? 0) + c.qty;

    final menuPanel = MenuPanelWidget(
      products: state.menuItems,
      deals: state.deals,
      cartCount: state.cart.length,
      onAddToCart: (p) => _handleAddToCart(context, ref, p),
      cartItemIds: cartIds,
      onViewCart: () => ref.read(_showCheckoutProvider.notifier).state = true,
      cartTotal: state.total,
      isLoading: state.isLoading,
    );

    final cartPanel = CartPanelWidget(
      onBack: isMobile
          ? () => ref.read(_showCheckoutProvider.notifier).state = false
          : null,
      onPlaceOrder: () => _placeOrder(context, ref),
    );

    // Desktop till: touch menu with categories on the left, invoice on the right.
    final tillLayout = Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: optionsProduct != null
                    ? SizeOptionsWidget(
                        product: optionsProduct,
                        onCancel: () =>
                            ref.read(_optionsProductProvider.notifier).state =
                                null,
                        onSelect: (size) {
                          ref.read(_optionsProductProvider.notifier).state =
                              null;
                          notifier.addToCart(optionsProduct, size: size);
                        },
                      )
                    : MenuGridWidget(
                        products: state.menuItems,
                        deals: state.deals,
                        categories:
                            ref.watch(posCategoriesProvider).value ?? const [],
                        onAddToCart: (p) => _handleAddToCart(context, ref, p),
                        isLoading: state.isLoading,
                      ),
              ),
              if (onHome != null)
                TillBottomBarWidget(
                  userName: ref.watch(branchAuthProvider).branch?.name ?? '',
                  onHome: onHome!,
                  onOrders: onOrders,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 380,
          child: InvoicePanelWidget(
            onVoid: onHome,
            onSave: () {
              notifier.setPaymentStatus('Unpaid');
              _placeOrder(context, ref);
            },
            onPay: () => _pay(context, ref),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          isMobile
              ? Column(
                  children: [
                    _POSTopBar(
                      cartCount: state.cart.length,
                      onNewOrder: notifier.clearCart,
                    ),
                    Expanded(child: showCheckout ? cartPanel : menuPanel),
                  ],
                )
              : tillLayout,
          if (state.isPlacing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kPrimary),
                        SizedBox(height: 16),
                        Text(
                          'Placing order...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    WidgetRef ref,
    MenuProduct p,
  ) async {
    if (p.sizes.isEmpty) {
      ref.read(posProvider.notifier).addToCart(p);
      return;
    }
    // The desktop till picks the size in the menu area; the phone layout keeps the dialog.
    if (MediaQuery.of(context).size.width >= 800) {
      ref.read(_optionsProductProvider.notifier).state = p;
      return;
    }
    final size = await showTillChoice<ProductSize>(context, p.name, [
      for (final sz in p.sizes)
        (sz, '${sz.name.toUpperCase()}\n${formatMoney(sz.price)}'),
    ]);
    if (size != null) ref.read(posProvider.notifier).addToCart(p, size: size);
  }

  /// PAY: check the sale, take payment on the payment screen, then place the order.
  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final state = ref.read(posProvider);
    if (state.cart.isEmpty || !_valid(context, state)) return;
    final result = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(builder: (_) => PaymentScreen(sale: state)),
    );
    if (result == null || !context.mounted) return;
    final n = ref.read(posProvider.notifier);
    n.setPaymentStatus(result.paid ? 'Paid' : 'Unpaid');
    if (result.paid) n.setPaymentMethod(result.method);
    await _placeOrder(context, ref, confirm: false, change: result.change);
  }

  bool _valid(BuildContext context, PosState state) {
    if (state.orderType == 'Dine-in' && state.selectedTable.isEmpty) {
      _snack(context, 'Please select a table for Dine-in', kRed);
      return false;
    }
    if (state.orderType == 'Delivery' && state.deliveryAddress.trim().isEmpty) {
      _snack(context, 'Enter a delivery address', kRed);
      return false;
    }
    if (state.orderType == 'Delivery' && state.selectedRiderId == null) {
      _snack(
        context,
        'Select a rider — delivery orders must be assigned',
        kRed,
      );
      return false;
    }
    return true;
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref, {
    bool confirm = true,
    double change = 0,
  }) async {
    final state = ref.read(posProvider);
    if (state.cart.isEmpty) return;
    if (!_valid(context, state)) return;
    final paid = state.paymentStatus == 'Paid';
    final confirmed =
        !confirm ||
        await showTillConfirm(
          context,
          'Confirm order',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatMoney(state.total),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                paid ? 'PAID · ${state.paymentMethod.toUpperCase()}' : 'UNPAID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: paid ? kGreen : kRed,
                ),
              ),
            ],
          ),
          okLabel: paid ? 'PAY' : 'SAVE',
        );
    if (!confirmed || !context.mounted) return;

    final success = await ref.read(posProvider.notifier).placeOrder();
    if (!context.mounted) return;

    if (success) {
      final order = ref.read(posProvider).lastPlaced;
      ref.read(posProvider.notifier)
        ..clearLastPlaced()
        ..clearCart();
      ref.read(_showCheckoutProvider.notifier).state = false;
      _snack(
        context,
        change > 0.004
            ? '${order?.orderNumber ?? 'Order'} paid. Change ${formatMoney(change)}'
            : '${order?.orderNumber ?? 'Order'} placed!',
        kGreen,
        icon: AppIcons.checkCircleRounded,
      );
    } else {
      final err = ref.read(posProvider).error ?? 'Something went wrong';
      ref.read(posProvider.notifier).clearError();
      _snack(context, err, kRed);
    }
  }

  void _snack(BuildContext context, String msg, Color color, {AppIcon? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              SvgIcon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _POSTopBar extends StatelessWidget {
  final int cartCount;
  final VoidCallback onNewOrder;
  const _POSTopBar({required this.cartCount, required this.onNewOrder});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: kText,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SvgIcon(
              AppIcons.pointOfSaleRounded,
              color: kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'POS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: onNewOrder,
            icon: const SvgIcon(AppIcons.refreshRounded, size: 16),
            label: const Text('New Order', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SvgIcon(
                  AppIcons.accessTimeRounded,
                  size: 14,
                  color: Colors.white54,
                ),
                const SizedBox(width: 5),
                Text(
                  '${now.day}/${now.month} — ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
