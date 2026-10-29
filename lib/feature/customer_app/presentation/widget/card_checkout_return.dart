import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_icons.dart';
import '../../data/customer_datasource.dart';
import '../provider/cart_provider.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import 'customer_widgets.dart';

/// Stripe Checkout sends the customer back to the website at
/// `?checkout=success|cancelled&payment=<id>` (see create-checkout-session).
final _checkoutResult = kIsWeb ? Uri.base.queryParameters['checkout'] : null;
final _checkoutPaymentId = kIsWeb ? Uri.base.queryParameters['payment'] : null;

/// Handles the return from Stripe once, when the site loads: confirms a paid
/// order, or puts the cart back after a cancelled payment.
class CardCheckoutReturn extends ConsumerStatefulWidget {
  final Widget child;

  const CardCheckoutReturn({super.key, required this.child});

  @override
  ConsumerState<CardCheckoutReturn> createState() => _CardCheckoutReturnState();
}

class _CardCheckoutReturnState extends ConsumerState<CardCheckoutReturn> {
  // The query string stays in the address bar, so remember which return was
  // already shown and don't show it again on a page refresh.
  static const _handledKey = 'card_checkout_handled';

  @override
  void initState() {
    super.initState();
    final paymentId = _checkoutPaymentId;
    if (paymentId == null || paymentId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle(paymentId));
  }

  Future<void> _handle(String paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_handledKey) == paymentId) return;
      await prefs.setString(_handledKey, paymentId);
    } catch (_) {}
    if (!mounted) return;

    if (_checkoutResult == 'success') {
      final viewOrders = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PaymentResultDialog(paymentId: paymentId),
      );
      ref.read(customerTabProvider.notifier).state = viewOrders == true
          ? CustomerTab.orders
          : CustomerTab.home;
    } else {
      await _restoreCart(paymentId);
    }
  }

  /// Puts the items from the unpaid checkout back in the cart.
  Future<void> _restoreCart(String paymentId) async {
    try {
      final ds = ref.read(customerDatasourceProvider);
      final payment = await ds.watchCardPayment(paymentId).first;
      final menu = await ref.read(customerMenuProvider.future);
      if (payment == null || payment.isPaid) return;
      final cart = ref.read(cartProvider.notifier);
      for (final item in payment.items) {
        final dish = menu.dishes
            .where((d) => d.id == item.menuItemId)
            .firstOrNull;
        if (dish == null) continue; // no longer on the menu
        final option = item.size.isEmpty
            ? dish.options.where((o) => !o.isSize).firstOrNull ??
                  dish.options.first
            : dish.options
                  .where((o) => o.isSize && o.label == item.size)
                  .firstOrNull;
        if (option != null) cart.add(dish, option, qty: item.qty);
      }
    } catch (_) {
      // The cart just stays empty; nothing was charged.
    }
    if (!mounted) return;
    ref.read(customerTabProvider.notifier).state = CustomerTab.cart;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment cancelled — you have not been charged. Your cart is still here.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Waits for the Stripe webhook to create the order, then shows its number.
/// Resolves to true when the customer chooses to view their orders.
class _PaymentResultDialog extends ConsumerStatefulWidget {
  final String paymentId;

  const _PaymentResultDialog({required this.paymentId});

  @override
  ConsumerState<_PaymentResultDialog> createState() =>
      _PaymentResultDialogState();
}

class _PaymentResultDialogState extends ConsumerState<_PaymentResultDialog> {
  // Created once, so rebuilds don't restart the status checks.
  late final _payment = ref
      .read(customerDatasourceProvider)
      .watchCardPayment(widget.paymentId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CardPayment?>(
      stream: _payment,
      builder: (context, snap) {
        final payment = snap.data;
        final paid = payment?.isPaid ?? false;
        // Also failed when the checks ran out while the payment was still open.
        final failed =
            snap.hasError ||
            payment?.status == 'expired' ||
            (snap.hasData && payment == null) ||
            (snap.connectionState == ConnectionState.done && !paid);

        final String title;
        final String message;
        if (paid) {
          title = 'Order placed!';
          message = payment!.delivery
              ? 'Payment received. Your food is being cooked fresh and will be delivered to your address soon.'
              : 'Payment received. Your food is being cooked fresh. We\'ll have it ready for pickup shortly.';
        } else if (failed) {
          title = 'Payment not completed';
          message =
              'We couldn\'t confirm this payment. If you were charged, please contact us and we\'ll sort it out.';
        } else {
          title = 'Confirming payment…';
          message =
              'This only takes a few seconds. Please keep this page open.';
        }

        return AlertDialog(
          backgroundColor: CColors.paper,
          icon: paid
              ? const IconBadge(
                  AppIcons.checkCircleRounded,
                  size: 64,
                  background: CColors.cream,
                  color: CColors.olive,
                )
              : failed
              ? const IconBadge(
                  AppIcons.errorOutline,
                  size: 64,
                  background: CColors.cream,
                  color: CColors.rust,
                )
              : const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: CColors.rust,
                      strokeWidth: 4,
                    ),
                  ),
                ),
          title: Text(
            title,
            style: CText.display(24),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paid) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CColors.cream,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Order ${payment!.orderNumber ?? ''} · Paid online',
                    style: CText.body(
                      15,
                      color: CColors.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: CText.body(14.5, color: CColors.muted, height: 1.6),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (paid)
              PillButton(
                label: 'Track My Order',
                small: true,
                icon: AppIcons.arrowForwardRounded,
                onPressed: () => Navigator.pop(context, true),
              ),
            if (paid || failed)
              PillButton(
                label: 'Back to Home',
                small: true,
                style: PillStyle.outlineDark,
                onPressed: () => Navigator.pop(context, false),
              ),
          ],
        );
      },
    );
  }
}
