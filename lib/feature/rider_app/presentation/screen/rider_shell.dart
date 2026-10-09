import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../provider/rider_provider.dart';
import '../widget/rider_actions.dart';
import 'rider_deliveries_screen.dart';
import 'rider_earnings_screen.dart';
import 'rider_profile_screen.dart';

/// Signed-in rider: bottom navigation between Deliveries, Earnings and Profile.
class RiderShell extends ConsumerStatefulWidget {
  const RiderShell({super.key});

  @override
  ConsumerState<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends ConsumerState<RiderShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Buzz and jump to Deliveries when the restaurant assigns a new delivery.
    ref.listen(riderProvider.select((s) => s.newAssignments), (prev, next) {
      if (prev == null || next <= prev) return;
      HapticFeedback.heavyImpact();
      setState(() => _tab = 0);
      riderToast(context, 'New delivery assigned to you!', kPrimary);
    });

    final s = ref.watch(riderProvider);
    if (s.me == null) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: s.error == null
              ? const CircularProgressIndicator(color: kPrimary)
              : _LoadError(
                  message: s.error!,
                  onRetry: ref.read(riderProvider.notifier).load,
                  onSignOut: () => confirmSignOut(context, ref),
                ),
        ),
      );
    }

    final activeCount = s.active.length;
    Widget icon(AppIcon i, Color c) => SvgIcon(i, size: 24, color: c);

    // Deliveries has a red header, the other tabs a light background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _tab == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kBg,
        // IndexedStack keeps each tab's scroll position when switching.
        body: IndexedStack(
          index: _tab,
          children: const [RiderDeliveriesScreen(), RiderEarningsScreen(), RiderProfileScreen()],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: kCard,
            indicatorColor: kPrimary.withValues(alpha: 0.12),
            surfaceTintColor: kCard,
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: activeCount > 0,
                  label: Text('$activeCount'),
                  backgroundColor: kPrimary,
                  child: icon(AppIcons.deliveryDiningOutlined, kSub),
                ),
                selectedIcon: Badge(
                  isLabelVisible: activeCount > 0,
                  label: Text('$activeCount'),
                  backgroundColor: kPrimary,
                  child: icon(AppIcons.deliveryDiningRounded, kPrimary),
                ),
                label: 'Deliveries',
              ),
              NavigationDestination(
                icon: icon(AppIcons.accountBalanceWalletOutlined, kSub),
                selectedIcon: icon(AppIcons.accountBalanceWalletRounded, kPrimary),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: icon(AppIcons.personOutlineRounded, kSub),
                selectedIcon: icon(AppIcons.personRounded, kPrimary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the rider's profile can't be loaded. Sign out is offered too, so a
/// rider who logged in with the wrong account is never stuck here.
class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  const _LoadError({required this.message, required this.onRetry, required this.onSignOut});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const SvgIcon(AppIcons.errorOutlineRounded, size: 40, color: kRed),
        ),
        const SizedBox(height: 16),
        const Text(
          "Couldn't load your profile",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: kSub, height: 1.5),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Try again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: onSignOut,
          child: const Text(
            'Sign out',
            style: TextStyle(color: kSub, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
