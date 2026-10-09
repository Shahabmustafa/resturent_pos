import 'package:resturent_application/core/widget/status_pill.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ─── Header Cell ──────────────────────────────────────────────────────────────

class HWidget extends StatelessWidget {
  final String t;
  final int flex;
  const HWidget(this.t, {super.key, this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kMuted,
                letterSpacing: 0.3)),
      );
}

// ─── Pill ─────────────────────────────────────────────────────────────────────

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class FChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const FChipWidget(this.label, this.active, this.color, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: active ? color.withOpacity(0.1) : kLight,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: active ? color.withOpacity(0.4) : kBorder)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? color : kMuted,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400)),
        ),
      );
}

// ─── Icon Button ──────────────────────────────────────────────────────────────

class IBtnWidget extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  const IBtnWidget(this.icon, this.color, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7)),
          child: SvgIcon(icon, size: 14, color: color),
        ),
      );
}

// ─── Action Button ────────────────────────────────────────────────────────────

class ABtnWidget extends StatelessWidget {
  final String label;
  final Color color;
  final AppIcon icon;
  final VoidCallback onTap;
  const ABtnWidget(this.label, this.color, this.icon, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SvgIcon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadgeWidget(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => StatusPill(label: label, color: color, dot: true);
}

// ─── Empty Widget ─────────────────────────────────────────────────────────────

class EmptyWidget extends StatelessWidget {
  final String msg;
  const EmptyWidget(this.msg, {super.key});

  @override
  Widget build(BuildContext context) => Center(
      child: Text(msg,
          style: const TextStyle(color: kMuted, fontSize: 14)));
}

// ─── Input Decoration helper ──────────────────────────────────────────────────

InputDecoration dec({String hint = ''}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBDCC)),
      filled: true,
      fillColor: kLight,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide:
              const BorderSide(color: kPrimary, width: 1.5)),
    );

// ─── Field Widget helper ──────────────────────────────────────────────────────

Widget fieldWidget(String lbl, TextEditingController c, String h,
        {TextInputType? kt}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kSub)),
      const SizedBox(height: 5),
      TextField(
          controller: c,
          keyboardType: kt,
          style: const TextStyle(fontSize: 13, color: kText),
          decoration: dec(hint: h)),
    ]);
