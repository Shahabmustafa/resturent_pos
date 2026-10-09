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
import '../widget/pos_misc_widgets.dart';
import 'package:resturent_application/core/constants/currency.dart';

final _showCheckoutProvider = StateProvider<bool>((_) => false);

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state       = ref.watch(posProvider);
    final notifier    = ref.read(posProvider.notifier);
    final showCheckout = ref.watch(_showCheckoutProvider);
    final isMobile    = MediaQuery.of(context).size.width < 800;
    final cartIds = <String, int>{};
    for (final c in state.cart) cartIds[c.product.id] = (cartIds[c.product.id] ?? 0) + c.qty;

    final menuPanel = MenuPanelWidget(
      products:    state.menuItems,
      deals:       state.deals,
      cartCount:   state.cart.length,
      onAddToCart: (p) => _handleAddToCart(context, ref, p),
      cartItemIds: cartIds,
      onViewCart:  () => ref.read(_showCheckoutProvider.notifier).state = true,
      cartTotal:   state.total,
      isLoading:   state.isLoading,
    );

    final cartPanel = CartPanelWidget(
      onBack:       isMobile ? () => ref.read(_showCheckoutProvider.notifier).state = false : null,
      onPlaceOrder: () => _placeOrder(context, ref),
    );

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        Column(children: [
          _POSTopBar(cartCount: state.cart.length, onNewOrder: notifier.clearCart),
          Expanded(
            child: isMobile
                ? (showCheckout ? cartPanel : menuPanel)
                : Row(children: [
                    Expanded(flex: 6, child: menuPanel),
                    SizedBox(width: 380, child: cartPanel),
                  ]),
          ),
        ]),
        if (state.isPlacing)
          Container(
            color: Colors.black26,
            child: const Center(child: Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: kPrimary),
                SizedBox(height: 16),
                Text('Placing order...', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ))),
          ),
      ]),
    );
  }

  Future<void> _handleAddToCart(BuildContext context, WidgetRef ref, MenuProduct p) async {
    if (p.sizes.isEmpty) { ref.read(posProvider.notifier).addToCart(p); return; }
    final size = await showDialog<ProductSize>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${p.name} — Select Size', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
        content: Column(mainAxisSize: MainAxisSize.min, children: p.sizes.map((s) => GestureDetector(
          onTap: () => Navigator.pop(context, s),
          child: Container(
            width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: kLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
            child: Row(children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText)),
              const Spacer(),
              Text(formatMoney(s.price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimary)),
            ]),
          ),
        )).toList()),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kMuted)))],
      ),
    );
    if (size != null) ref.read(posProvider.notifier).addToCart(p, size: size);
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final state = ref.read(posProvider);
    if (state.cart.isEmpty) return;

    // ── Validations ──────────────────────────────────────────────────────────
    if (state.orderType == 'Dine-in' && state.selectedTable.isEmpty) {
      _snack(context, 'Please select a table for Dine-in', kRed);
      return;
    }
    if (state.orderType == 'Delivery' && state.deliveryAddress.trim().isEmpty) {
      _snack(context, 'Enter a delivery address', kRed);
      return;
    }
    if (state.orderType == 'Delivery' && state.selectedRiderId == null) {
      _snack(context, 'Select a rider — delivery orders must be assigned', kRed);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => OrderConfirmDialog(
        orderId: 'New Order', total: state.total, paymentStatus: state.paymentStatus,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(posProvider.notifier).placeOrder();
    if (!context.mounted) return;

    if (success) {
      final order = ref.read(posProvider).lastPlaced;
      ref.read(posProvider.notifier)..clearLastPlaced()..clearCart();
      ref.read(_showCheckoutProvider.notifier).state = false;
      _snack(context, '${order?.orderNumber ?? 'Order'} placed! Rider assigned.', kGreen, icon: AppIcons.checkCircleRounded);
    } else {
      final err = ref.read(posProvider).error ?? 'Something went wrong';
      ref.read(posProvider.notifier).clearError();
      _snack(context, err, kRed);
    }
  }

  void _snack(BuildContext context, String msg, Color color, {AppIcon? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[SvgIcon(icon, color: Colors.white, size: 16), const SizedBox(width: 8)],
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
      height: 58, padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: kText, boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const SvgIcon(AppIcons.pointOfSaleRounded, color: kPrimary, size: 20)),
        const SizedBox(width: 10),
        const Text('POS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const Spacer(),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.white60, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          onPressed: onNewOrder,
          icon: const SvgIcon(AppIcons.refreshRounded, size: 16),
          label: const Text('New Order', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const SvgIcon(AppIcons.accessTimeRounded, size: 14, color: Colors.white54),
            const SizedBox(width: 5),
            Text('${now.day}/${now.month} — ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          ]),
        ),
      ]),
    );
  }
}
