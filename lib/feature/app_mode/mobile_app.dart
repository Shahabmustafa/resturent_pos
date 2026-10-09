import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widget/svg_icon.dart';
import '../customer_app/customer_app.dart';
import '../customer_app/data/menu_data.dart';
import '../customer_app/presentation/theme/customer_theme.dart';
import '../customer_app/presentation/widget/customer_widgets.dart';
import '../rider_app/rider_app.dart';
import 'app_mode.dart';

/// Phone build: asks once whether this is a customer or a rider, then shows
/// the website UI or the Rider app. The choice is remembered.
class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppMode?>(
      valueListenable: AppModeController.mode,
      builder: (context, mode, _) => switch (mode) {
        AppMode.customer => const CustomerApp(key: ValueKey('customer')),
        AppMode.rider => const RiderApp(key: ValueKey('rider')),
        null => MaterialApp(
          key: const ValueKey('chooser'),
          debugShowCheckedModeBanner: false,
          theme: buildCustomerTheme(),
          home: const _ChooserScreen(),
        ),
      },
    );
  }
}

class _ChooserScreen extends StatefulWidget {
  const _ChooserScreen();

  @override
  State<_ChooserScreen> createState() => _ChooserScreenState();
}

class _ChooserScreenState extends State<_ChooserScreen> {
  AppMode? _busy;

  Future<void> _pick(AppMode m) async {
    setState(() => _busy = m);
    await AppModeController.choose(m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.cream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.9),
            radius: 1.2,
            colors: [Color(0x33C68A2E), Color(0x00F8F2E6)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: CColors.goldGradient,
                          boxShadow: CShadows.soft,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: const FoodImage(MenuData.logoImage),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: CText.body(15, color: CColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text('Pak Afghan & Woking Shawarma', textAlign: TextAlign.center, style: CText.display(28)),
                    const SizedBox(height: 10),
                    Text(
                      'How are you using the app?',
                      textAlign: TextAlign.center,
                      style: CText.body(15.5, color: CColors.inkSoft, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 30),
                    _Choice(
                      icon: AppIcons.restaurantRounded,
                      title: "I'm a customer",
                      body: 'Browse the menu, order food and track your orders.',
                      dark: true,
                      busy: _busy == AppMode.customer,
                      onTap: _busy == null ? () => _pick(AppMode.customer) : null,
                    ),
                    const SizedBox(height: 14),
                    _Choice(
                      icon: AppIcons.deliveryDiningRounded,
                      title: "I'm a delivery rider",
                      body: 'See the deliveries assigned to you and update them.',
                      busy: _busy == AppMode.rider,
                      onTap: _busy == null ? () => _pick(AppMode.rider) : null,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'You can switch later from your profile.',
                      textAlign: TextAlign.center,
                      style: CText.body(12.5, color: CColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final AppIcon icon;
  final String title, body;
  final bool dark;
  final bool busy;
  final VoidCallback? onTap;

  const _Choice({
    required this.icon,
    required this.title,
    required this.body,
    this.dark = false,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : CColors.ink;
    return Material(
      color: dark ? CColors.ink : CColors.paper,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: dark ? CColors.ink : CColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: dark ? CColors.goldGradient : null,
                  color: dark ? null : CColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: SvgIcon(icon, size: 28, color: dark ? CColors.ink : CColors.rust),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CText.display(19, color: fg)),
                    const SizedBox(height: 4),
                    Text(body, style: CText.body(13, color: dark ? CColors.goldPale : CColors.muted, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: dark ? CColors.goldLight : CColors.rust),
                    )
                  : SvgIcon(AppIcons.arrowForwardRounded, size: 22, color: dark ? CColors.goldLight : CColors.rust),
            ],
          ),
        ),
      ),
    );
  }
}
