import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/model/dish_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException, User;
import '../../data/customer_datasource.dart';
import '../provider/cart_provider.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/auth_dialog.dart';
import '../widget/customer_widgets.dart';
import '../widget/dish_card.dart';

enum _Fulfilment { delivery, collection }

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

// UK postcode, with or without the space, e.g. "GU21 6AB" or "SW1A1AA".
final _ukPostcode = RegExp(r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$');

class _CartScreenState extends ConsumerState<CartScreen> {
  _Fulfilment _fulfilment = _Fulfilment.delivery;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _postcode = TextEditingController();
  final _notes = TextEditingController();
  bool _placing = false;
  String? _prefilledFor;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _postcode, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fill name/phone/address from the account once per signed-in user.
  void _prefill(User? user) {
    if (user == null || _prefilledFor == user.id) return;
    _prefilledFor = user.id;
    if (_name.text.isEmpty) _name.text = user.displayName;
    if (_phone.text.isEmpty) _phone.text = user.contactPhone;
    if (_address.text.isEmpty) _address.text = user.savedAddress;
  }


  // Light grey page so the white checkout cards stand out.
  @override
  Widget build(BuildContext context) => ColoredBox(color: CColors.pageGrey, child: _page(context));

  Widget _page(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final user = ref.watch(customerUserProvider).value;
    // Opened from a table's QR code: dine-in order for that table, no login needed.
    final table = ref.watch(tableSessionProvider).value;
    final gutter = MediaQuery.sizeOf(context).width < 640 ? 20.0 : 28.0;
    _prefill(user);

    if (lines.isEmpty) return const _EmptyCart();

    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Text(
        t,
        style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 24),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Your Order', style: CText.display(30))),
                      TextButton(
                        onPressed: () => ref.read(cartProvider.notifier).clear(),
                        child: Text(
                          'Clear',
                          style: CText.body(14, color: CColors.rust, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final line in lines) _CartLineTile(line: line),
                  const SizedBox(height: 10),
                  if (table != null)
                    _TableDetails(table: table, formKey: _formKey, name: _name, notes: _notes)
                  else ...[
                    Text(
                      'How would you like it?',
                      style: CText.body(14, color: CColors.ink, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _FulfilmentOption(
                            icon: AppIcons.deliveryDiningRounded,
                            label: 'Delivery',
                            hint: 'To your door',
                            selected: _fulfilment == _Fulfilment.delivery,
                            onTap: () => setState(() => _fulfilment = _Fulfilment.delivery),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FulfilmentOption(
                            icon: AppIcons.takeoutDiningRounded,
                            label: 'Takeaway',
                            hint: 'Collect it yourself',
                            selected: _fulfilment == _Fulfilment.collection,
                            onTap: () => setState(() => _fulfilment = _Fulfilment.collection),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (user == null)
                      const _LoginPrompt()
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CColors.paper,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CColors.line),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AccountRow(user: user),
                              const Divider(color: CColors.line, height: 28),
                              Text('Your details', style: CText.display(19)),
                              label('Name'),
                              TextFormField(controller: _name, validator: required),
                              label('Phone'),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                                    ? 'Enter a valid phone number'
                                    : null,
                              ),
                              if (_fulfilment == _Fulfilment.delivery) ...[
                                label('Delivery address'),
                                TextFormField(
                                  controller: _address,
                                  validator: required,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(hintText: 'House, street, area'),
                                ),
                                label('Postcode'),
                                TextFormField(
                                  controller: _postcode,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: const InputDecoration(hintText: 'e.g. GU21 6AB'),
                                  validator: (v) => _ukPostcode.hasMatch((v ?? '').trim().toUpperCase())
                                      ? null
                                      : 'Enter a valid UK postcode',
                                ),
                              ],
                              label('Notes (optional)'),
                              TextFormField(
                                controller: _notes,
                                decoration: const InputDecoration(hintText: 'e.g. extra spicy, no onions'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const SvgIcon(AppIcons.paymentsRounded, size: 18, color: CColors.olive),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Payment: cash on delivery / at pickup',
                                      style: CText.body(13, color: CColors.olive, weight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            _CheckoutBar(
              subtotal: subtotal,
              gutter: gutter,
              signedIn: user != null,
              table: table,
              placing: _placing,
              onCheckout: () => table != null ? _checkoutTable(table) : _checkout(user),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(User? user) async {
    if (user == null) {
      await showCustomerAuthDialog(context);
      return; // the details form appears once signed in; the customer reviews it and taps again
    }
    if (!_formKey.currentState!.validate()) return;

    final delivery = _fulfilment == _Fulfilment.delivery;
    setState(() => _placing = true);
    try {
      final orderNumber = await ref
          .read(customerDatasourceProvider)
          .placeOrder(
            details: CheckoutDetails(
              delivery: delivery,
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              // The postcode goes on the end of the address the restaurant sees.
              address: delivery ? '${_address.text.trim()}, ${_postcode.text.trim().toUpperCase()}' : '',
              notes: _notes.text,
            ),
            lines: [for (final l in ref.read(cartProvider)) (dish: l.dish, option: l.option, qty: l.qty)],
          );
      if (!mounted) return;
      _notes.clear();
      final viewOrders = await _showPlaced(orderNumber, delivery);
      ref.read(cartProvider.notifier).clear();
      ref.read(customerTabProvider.notifier).state = viewOrders ? CustomerTab.orders : CustomerTab.home;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Couldn\'t place your order. Please try again. ($e)')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _checkoutTable(String table) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    try {
      final orderNumber = await ref
          .read(customerDatasourceProvider)
          .placeTableOrder(
            token: tableQrToken!,
            name: _name.text.trim(),
            notes: _notes.text,
            lines: [for (final l in ref.read(cartProvider)) (dish: l.dish, option: l.option, qty: l.qty)],
          );
      if (!mounted) return;
      _notes.clear();
      await _showSentToTable(orderNumber, table);
      ref.read(cartProvider.notifier).clear();
      ref.read(customerTabProvider.notifier).state = CustomerTab.menu;
    } catch (e) {
      if (!mounted) return;
      final message = e is PostgrestException ? e.message : 'Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t send your order. $message')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _showSentToTable(String orderNumber, String table) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: CColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const IconBadge(AppIcons.checkCircleRounded, size: 64, background: CColors.cream, color: CColors.olive),
      title: Text('Order sent!', style: CText.display(24), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: CColors.cream, borderRadius: BorderRadius.circular(30)),
            child: Text(
              'Order $orderNumber · Table $table',
              style: CText.body(15, color: CColors.ink, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'The kitchen has your order. We\'ll bring it to your table — pay at the counter when you\'re done.',
            textAlign: TextAlign.center,
            style: CText.body(14.5, color: CColors.muted, height: 1.6),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        PillButton(
          label: 'Order Something Else',
          small: true,
          icon: AppIcons.arrowForwardRounded,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );

  /// Resolves to true when the customer chooses to view their orders.
  Future<bool> _showPlaced(String orderNumber, bool delivery) async {
    final viewOrders = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const IconBadge(AppIcons.checkCircleRounded, size: 64, background: CColors.cream, color: CColors.olive),
        title: Text('Order placed!', style: CText.display(24), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: CColors.cream, borderRadius: BorderRadius.circular(30)),
              child: Text(
                'Order $orderNumber',
                style: CText.body(15, color: CColors.ink, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              delivery
                  ? 'Your food is being cooked fresh and will be delivered to your address soon.'
                  : 'Your food is being cooked fresh. We\'ll have it ready for pickup shortly.',
              textAlign: TextAlign.center,
              style: CText.body(14.5, color: CColors.muted, height: 1.6),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          PillButton(
            label: 'Track My Order',
            small: true,
            icon: AppIcons.arrowForwardRounded,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          PillButton(
            label: 'Back to Home',
            small: true,
            style: PillStyle.outlineDark,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
    return viewOrders ?? false;
  }
}

/// Table QR checkout: which table the order goes to, an optional name and notes.
class _TableDetails extends StatelessWidget {
  final String table;
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController notes;

  const _TableDetails({required this.table, required this.formKey, required this.name, required this.notes});

  @override
  Widget build(BuildContext context) {
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Text(
        t,
        style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CColors.line),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconBadge(AppIcons.tableRestaurantRounded, size: 44, background: CColors.cream),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dine-in · Table $table', style: CText.display(19)),
                      Text('Your order goes straight to the kitchen.', style: CText.body(12.5, color: CColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            label('Your name (optional)'),
            TextFormField(controller: name),
            label('Notes (optional)'),
            TextFormField(
              controller: notes,
              decoration: const InputDecoration(hintText: 'e.g. extra spicy, no onions'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SvgIcon(AppIcons.paymentsRounded, size: 18, color: CColors.olive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment: at the counter when you\'re done',
                    style: CText.body(13, color: CColors.olive, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: CColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const IconBadge(AppIcons.lockOutlineRounded, size: 44, background: CColors.inkElev, color: CColors.goldLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Login to place your order', style: CText.display(17, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  'New here? Registering takes just a minute.',
                  style: CText.body(12.5, color: CColors.goldPale, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillButton(
            label: 'Login',
            small: true,
            style: PillStyle.gold,
            onPressed: () => showCustomerAuthDialog(context),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final User user;

  const _AccountRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconBadge(AppIcons.personRounded, size: 40, background: CColors.cream),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: CText.body(14.5, color: CColors.ink, weight: FontWeight.w600),
              ),
              Text(user.email ?? '', style: CText.body(12.5, color: CColors.muted)),
            ],
          ),
        ),
        TextButton(
          onPressed: CustomerAuth.signOut,
          child: Text(
            'Logout',
            style: CText.body(13.5, color: CColors.rust, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  final CartLine line;

  const _CartLineTile({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 72, height: 72, child: FoodImage(line.dish.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CText.body(14, color: CColors.ink, weight: FontWeight.w600, height: 1.3),
                ),
                if (line.dish.hasOptions) Text(line.option.label, style: CText.body(12.5, color: CColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatPrice(line.total),
                        style: CText.body(14.5, color: CColors.rust, weight: FontWeight.w700),
                      ),
                    ),
                    QtyStepper(
                      qty: line.qty,
                      compact: true,
                      onChanged: (v) => ref.read(cartProvider.notifier).setQty(line.key, v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfilmentOption extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _FulfilmentOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? CColors.ink : CColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? CColors.ink : CColors.line),
        ),
        child: Row(
          children: [
            SvgIcon(icon, size: 22, color: selected ? CColors.goldLight : CColors.rust),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CText.body(14, color: selected ? Colors.white : CColors.ink, weight: FontWeight.w600),
                  ),
                  Text(hint, style: CText.body(11.5, color: selected ? CColors.mutedLight : CColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double subtotal;
  final double gutter;
  final bool signedIn;
  final String? table;
  final bool placing;
  final VoidCallback onCheckout;

  const _CheckoutBar({
    required this.subtotal,
    required this.gutter,
    required this.signedIn,
    required this.table,
    required this.placing,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 18),
      decoration: const BoxDecoration(
        color: CColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: CShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Total', style: CText.body(14.5, color: CColors.muted)),
              ),
              Text(formatPrice(subtotal), style: CText.display(22)),
            ],
          ),
          const SizedBox(height: 14),
          PillButton(
            label: placing
                ? 'Placing order…'
                : table != null
                ? 'Send Order to Kitchen'
                : (signedIn ? 'Place Order' : 'Login to Order'),
            icon: placing
                ? null
                : (signedIn || table != null ? AppIcons.arrowForwardRounded : AppIcons.lockOutlineRounded),
            expand: true,
            onPressed: placing ? null : onCheckout,
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(AppIcons.shoppingBagOutlined, size: 88, color: CColors.gold),
            const SizedBox(height: 22),
            Text('Your cart is empty', style: CText.display(26)),
            const SizedBox(height: 8),
            Text(
              'Add something delicious from our menu.',
              textAlign: TextAlign.center,
              style: CText.body(14.5, color: CColors.muted),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Browse Menu',
              icon: AppIcons.arrowForwardRounded,
              onPressed: () => ref.read(customerTabProvider.notifier).state = CustomerTab.menu,
            ),
          ],
        ),
      ),
    );
  }
}
