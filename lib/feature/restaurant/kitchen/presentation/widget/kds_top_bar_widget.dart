import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class KDSTopBarWidget extends StatelessWidget {
  final int pending, preparing, ready, totalOrders;
  final bool voiceEnabled;
  final VoidCallback onVoiceToggle, onNewOrder;
  const KDSTopBarWidget({
    super.key,
    required this.pending,
    required this.preparing,
    required this.ready,
    required this.totalOrders,
    required this.voiceEnabled,
    required this.onVoiceToggle,
    required this.onNewOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.75)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const SvgIcon(AppIcons.soupKitchenRounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kitchen Display',
              style: TextStyle(
                  color: kText, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
          Text('Live Order Queue', style: TextStyle(color: kMuted, fontSize: 11)),
        ]),
        const SizedBox(width: 20),

        // Live indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Row(children: [
            PulseDotWidget(color: kPrimary),
            const SizedBox(width: 6),
            const Text('LIVE',
                style: TextStyle(
                    color: kPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ]),
        ),

        const Spacer(),

        // Stats pills
        TopStatPillWidget('$pending',   'Pending',   kPrimary),
        const SizedBox(width: 8),
        TopStatPillWidget('$preparing', 'Preparing', kPrimary),
        const SizedBox(width: 8),
        TopStatPillWidget('$ready',     'Ready',     kPrimary),
        const SizedBox(width: 16),

        // Voice toggle
        GestureDetector(
          onTap: onVoiceToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: voiceEnabled ? kPrimary.withOpacity(0.15) : kMuted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: voiceEnabled ? kPrimary.withOpacity(0.4) : kMuted.withOpacity(0.3)),
            ),
            child: Row(children: [
              SvgIcon(voiceEnabled ? AppIcons.volumeUpRounded : AppIcons.volumeOffRounded,
                  size: 16, color: voiceEnabled ? kPrimary : kMuted),
              const SizedBox(width: 6),
              Text('Voice',
                  style: TextStyle(
                      fontSize: 12,
                      color: voiceEnabled ? kPrimary : kMuted,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(width: 8),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onNewOrder,
          icon: const SvgIcon(AppIcons.addRounded, size: 16),
          label: const Text('Test Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Top Stat Pill ────────────────────────────────────────────────────────────

class TopStatPillWidget extends StatelessWidget {
  final String value, label;
  final Color color;
  const TopStatPillWidget(this.value, this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ]),
    );
  }
}

// ─── Pulse Dot ────────────────────────────────────────────────────────────────

class PulseDotWidget extends StatefulWidget {
  final Color color;
  const PulseDotWidget({super.key, required this.color});

  @override
  State<PulseDotWidget> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      ),
    );
  }
}