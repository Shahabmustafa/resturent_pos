import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../../../app_mode/app_mode.dart';
import '../../rider_app.dart';
import '../provider/rider_provider.dart';
import '../widget/rider_actions.dart';
import 'package:resturent_application/core/constants/currency.dart';

String _rs(double v) => formatMoney(v);

/// Profile tab: rider details, all-time totals, password change and sign out.
class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(riderProvider.select((s) => s.me))!;
    final (statusLabel, statusColor) = switch (me.status) {
      RiderStatus.available => ('Online', kGreen),
      RiderStatus.busy => ('On a delivery', kYellow),
      RiderStatus.offline => ('Offline', kMuted),
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 24, 16, 24),
      children: [
        // ── Identity ──
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: kPrimary.withValues(alpha: 0.12),
                child: Text(
                  me.name.isEmpty ? '?' : me.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: kPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                me.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── All-time totals ──
        Row(
          children: [
            _Total(label: 'Total deliveries', value: '${me.totalDeliveries}', icon: AppIcons.deliveryDiningRounded),
            const SizedBox(width: 12),
            _Total(label: 'Total earned', value: _rs(me.totalEarnings), icon: AppIcons.savingsRounded),
          ],
        ),
        const SizedBox(height: 16),

        // ── Details ──
        _Section(
          children: [
            _Row(AppIcons.phoneRounded, 'Phone (your login)', me.phone.isEmpty ? '—' : me.phone),
            _Row(AppIcons.directionsBikeRounded, 'Vehicle', me.vehicle.isEmpty ? '—' : me.vehicle),
            _Row(AppIcons.paymentsRounded, 'Charge per delivery', _rs(me.chargePerDelivery)),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Wrong details? Ask the restaurant manager to update them in the POS.',
            style: TextStyle(fontSize: 12, color: kMuted, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),

        // ── Account ──
        _Section(
          children: [
            _Action(
              icon: AppIcons.lockOutlineRounded,
              label: 'Change password',
              onTap: () => showDialog(context: context, builder: (_) => const _ChangePasswordDialog()),
            ),
            _Action(
              icon: AppIcons.restaurantRounded,
              label: 'Switch to the customer app',
              onTap: () => _confirmSwitch(context),
            ),
            _Action(
              icon: AppIcons.logoutRounded,
              label: 'Sign out',
              color: kRed,
              onTap: () => confirmSignOut(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _confirmSwitch(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Switch app?'),
      content: const Text('You will be signed out and taken back to the start screen.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Switch')),
      ],
    ),
  );
  if (ok == true) await AppModeController.reset();
}

class _Total extends StatelessWidget {
  final String label, value;
  final AppIcon icon;
  const _Total({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgIcon(icon, size: 22, color: kPrimary),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: kBorder, indent: 68),
          children[i],
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final AppIcon icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: SvgIcon(icon, size: 19, color: kPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap, this.color = kText});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (color == kText ? kSub : color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: SvgIcon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SvgIcon(AppIcons.chevronRightRounded, size: 20, color: kMuted),
        ],
      ),
    ),
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pass.text.length < 6) {
      setState(() => _error = 'Use at least 6 characters');
      return;
    }
    if (_pass.text != _confirm.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(riderDsProvider).changePassword(_pass.text);
      if (!mounted) return;
      Navigator.pop(context);
      riderToast(context, 'Password changed. Use it next time you sign in.', kGreen);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: kLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    suffixIcon: IconButton(
      onPressed: () => setState(() => _hide = !_hide),
      icon: SvgIcon(_hide ? AppIcons.visibilityRounded : AppIcons.visibilityOffRounded, size: 20, color: kMuted),
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text(
      'Change password',
      style: TextStyle(fontWeight: FontWeight.w800, color: kText),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _pass,
          obscureText: _hide,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: _dec('New password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirm,
          obscureText: _hide,
          decoration: _dec('Repeat new password'),
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: kRed, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel', style: TextStyle(color: kSub)),
      ),
      ElevatedButton(
        onPressed: _busy ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(_busy ? 'Saving…' : 'Save'),
      ),
    ],
  );
}
