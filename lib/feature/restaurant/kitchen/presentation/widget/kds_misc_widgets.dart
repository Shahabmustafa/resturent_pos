import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class VoiceBannerWidget extends StatelessWidget {
  final String orderNum;
  const VoiceBannerWidget({super.key, required this.orderNum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kPrimary, kPrimary.withOpacity(0.8)]),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SvgIcon(AppIcons.campaignRounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text('ORDER $orderNum IS READY — Please collect from reception!',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3)),
      ]),
    );
  }
}

class KDSFilterBarWidget extends StatelessWidget {
  final String selected;
  final int pending, preparing, ready, total;
  final ValueChanged<String> onSelect;
  const KDSFilterBarWidget({
    super.key,
    required this.selected,
    required this.pending,
    required this.preparing,
    required this.ready,
    required this.total,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('All', total, kSub),
      ('Pending', pending, kPrimary),
      ('Preparing', preparing, kPrimary),
      ('Ready', ready, kPrimary),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((t) {
          final isActive = selected == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? t.$3.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isActive ? t.$3.withOpacity(0.4) : kBorder),
                ),
                child: Row(children: [
                  Text(t.$1,
                      style: TextStyle(
                          color: isActive ? t.$3 : kSub,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                          fontSize: 13)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? t.$3.withOpacity(0.2) : kMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${t.$2}',
                        style: TextStyle(
                            color: isActive ? t.$3 : kMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class EmptyKitchenWidget extends StatelessWidget {
  const EmptyKitchenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
          child: const SvgIcon(AppIcons.checkCircleOutlineRounded, size: 56, color: kPrimary),
        ),
        const SizedBox(height: 20),
        const Text('All orders complete! 🎉',
            style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('No pending orders in the kitchen',
            style: TextStyle(color: kSub, fontSize: 13)),
      ]),
    );
  }
}