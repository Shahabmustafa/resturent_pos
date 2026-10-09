import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../provider/cart_provider.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/auth_dialog.dart';
import '../widget/customer_avatar.dart';
import '../widget/customer_widgets.dart';
import 'cart_screen.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

const _tabs = [
  (CustomerTab.home, 'Home', AppIcons.storefrontRounded),
  (CustomerTab.menu, 'Menu', AppIcons.menuBookRounded),
  (CustomerTab.cart, 'Cart', AppIcons.shoppingBagRounded),
  (CustomerTab.orders, 'My Orders', AppIcons.receiptLongRounded),
  (CustomerTab.contact, 'Contact', AppIcons.phoneRounded),
];

/// Customer-facing app shell: utility bar, header, and tab navigation
/// (bottom bar on phones, header links on wide screens).
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(customerTabProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Column(
        children: [
          const _UtilityBar(),
          _Header(wide: wide),
          const _TableBanner(),
          Expanded(
            child: _TabFade(
              index: tab.index,
              child: IndexedStack(
                index: tab.index,
                // Built from the enum so every tab always has exactly one screen.
                children: [for (final t in CustomerTab.values) _screenFor(t)],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : const _BottomNav(),
    );
  }
}

/// Fades and lifts the page in whenever the tab changes. Wraps the IndexedStack
/// instead of re-keying it, so each tab keeps its scroll position and inputs.
class _TabFade extends StatefulWidget {
  final int index;
  final Widget child;

  const _TabFade({required this.index, required this.child});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  late final _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: 0.2 + 0.8 * _curve.value,
      child: Transform.translate(offset: Offset(0, (1 - _curve.value) * 14), child: child),
    ),
  );
}

Widget _screenFor(CustomerTab tab) => switch (tab) {
  CustomerTab.home => const HomeScreen(),
  CustomerTab.menu => const MenuScreen(),
  CustomerTab.cart => const CartScreen(),
  CustomerTab.orders => const OrdersScreen(),
  CustomerTab.contact => const ContactScreen(),
  CustomerTab.profile => const ProfileScreen(),
};

/// Opened from a table's QR code: shows which table orders go to.
class _TableBanner extends ConsumerWidget {
  const _TableBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tableQrToken == null || tableQrToken!.isEmpty) return const SizedBox.shrink();
    final session = ref.watch(tableSessionProvider);
    if (session.isLoading) return const SizedBox.shrink();
    final table = session.value;
    final valid = table != null;
    return Container(
      width: double.infinity,
      color: valid ? CColors.goldPale : CColors.rust,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgIcon(AppIcons.tableRestaurantRounded, size: 16, color: valid ? CColors.ink : Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valid
                  ? 'Table $table · Dine-in — add dishes and send your order from the cart'
                  : 'This table QR code isn\'t valid. Please ask the staff for help.',
              style: CText.body(13, color: valid ? CColors.ink : Colors.white, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityBar extends ConsumerWidget {
  const _UtilityBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hours come from the POS settings; blank until loaded so no stale times flash.
    final hours = ref.watch(openingHoursProvider).value;
    final text = hours == null ? '' : (hours.is24Hours ? 'Open 24 hours, every day' : 'Open daily ${hours.range}');
    return Container(
      color: CColors.ink,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 7, 16, 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SvgIcon(AppIcons.accessTimeRounded, size: 14, color: CColors.goldLight),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: CText.body(11.5, color: CColors.goldPale, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool wide;

  const _Header({required this.wide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(customerTabProvider);
    void go(CustomerTab t) => ref.read(customerTabProvider.notifier).state = t;

    return Container(
      decoration: const BoxDecoration(
        color: CColors.paper,
        border: Border(bottom: BorderSide(color: CColors.line)),
      ),
      padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Row(
            children: [
              // Takes the free space; on very narrow phones the logo scales down
              // instead of pushing the account/cart buttons off screen.
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => go(CustomerTab.home),
                      child: const BrandMark(),
                    ),
                  ),
                ),
              ),
              if (wide) ...[
                for (final (t, label, _) in _tabs)
                  if (t != CustomerTab.cart) _NavLink(label: label, active: tab == t, onTap: () => go(t)),
                const SizedBox(width: 16),
                PillButton(
                  label: 'Order Now',
                  small: true,
                  icon: AppIcons.arrowForwardRounded,
                  onPressed: () => go(CustomerTab.menu),
                ),
                const SizedBox(width: 12),
              ],
              // Phone app only — the website never offers the Rider app.
              if (!kIsWeb) ...[const _RiderButton(), const SizedBox(width: 10)],
              _AccountButton(active: tab == CustomerTab.profile, onOpen: () => go(CustomerTab.profile)),
              const SizedBox(width: 10),
              _CartButton(onTap: () => go(CustomerTab.cart)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header text link with an animated underline marking the current page.
class _NavLink extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hoverable(
      lift: 0,
      builder: (context, hovered) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CText.body(14.5, color: active || hovered ? CColors.rust : CColors.ink, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration.zero,
                curve: Curves.easeOutCubic,
                height: 2,
                width: active ? 22 : (hovered ? 10 : 0),
                decoration: BoxDecoration(color: CColors.rust, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signed in: the customer's initial, opening their profile.
/// Signed out: a login button.
class _AccountButton extends ConsumerWidget {
  final bool active;
  final VoidCallback onOpen;

  const _AccountButton({required this.active, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerUserProvider).value;
    if (user == null) {
      return Tooltip(
        message: 'Login',
        child: Material(
          color: CColors.cream,
          shape: const CircleBorder(side: BorderSide(color: CColors.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              if (await showCustomerAuthDialog(context, reason: 'Log in to order and manage your profile.')) {
                onOpen();
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(11),
              child: SvgIcon(AppIcons.personRounded, size: 20, color: CColors.ink),
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message: 'My profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onOpen,
        child: AnimatedContainer(
          duration: Duration.zero,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? CColors.rust : Colors.transparent, width: 2),
          ),
          child: CustomerAvatar(user: user, size: 38),
        ),
      ),
    );
  }
}

class _RiderButton extends StatelessWidget {
  const _RiderButton();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Switch to Rider app',
    child: Material(
      color: CColors.cream,
      shape: const CircleBorder(side: BorderSide(color: CColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => confirmSwitchToRider(context),
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: SvgIcon(AppIcons.deliveryDiningRounded, size: 20, color: CColors.rust),
        ),
      ),
    ),
  );
}

class _CartButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _CartButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: CColors.rust,
      offset: const Offset(-2, 2),
      child: Material(
        color: CColors.ink,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(11),
            child: SvgIcon(AppIcons.shoppingBagRounded, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(customerTabProvider);
    final count = ref.watch(cartCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: CColors.paper,
        border: Border(top: BorderSide(color: CColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          for (final (t, label, icon) in _tabs)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => ref.read(customerTabProvider.notifier).state = t,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: Duration.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: tab == t ? CColors.goldPale : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Badge(
                          isLabelVisible: t == CustomerTab.cart && count > 0,
                          label: Text('$count'),
                          backgroundColor: CColors.rust,
                          child: SvgIcon(icon, size: 22, color: tab == t ? CColors.rust : CColors.muted),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: CText.body(
                          11.5,
                          color: tab == t ? CColors.ink : CColors.muted,
                          weight: tab == t ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
