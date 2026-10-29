import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

/// Bottom strip of the desktop till: clock with the signed-in user, and
/// buttons back to the home tiles and to Orders.
class TillBottomBarWidget extends StatelessWidget {
  final String userName;
  final VoidCallback onHome;
  final VoidCallback? onOrders;

  const TillBottomBarWidget({
    super.key,
    required this.userName,
    required this.onHome,
    this.onOrders,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFDCE6F2),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Row(
      children: [
        _ClockBox(userName: userName),
        const SizedBox(width: 16),
        _BarButton(
          label: 'HOME',
          icon: AppIcons.dashboardRounded,
          color: const Color(0xFF8E7CC3),
          onTap: onHome,
        ),
        if (onOrders != null) ...[
          const SizedBox(width: 10),
          _BarButton(
            label: 'ORDERS',
            icon: AppIcons.receiptLongRounded,
            color: const Color(0xFFF4F7FB),
            dark: true,
            onTap: onOrders!,
          ),
        ],
      ],
    ),
  );
}

class _ClockBox extends StatefulWidget {
  final String userName;
  const _ClockBox({required this.userName});

  @override
  State<_ClockBox> createState() => _ClockBoxState();
}

class _ClockBoxState extends State<_ClockBox> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF2346B8),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('h:mm a').format(DateTime.now()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            const SvgIcon(
              AppIcons.personRounded,
              size: 13,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BarButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final bool dark;
  final VoidCallback onTap;
  const _BarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFF4B5563) : Colors.white;
    return Material(
      color: color,
      elevation: 2,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: SizedBox(
          width: 130,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(icon, size: 22, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
