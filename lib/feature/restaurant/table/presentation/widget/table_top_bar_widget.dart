import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class TableTopBarWidget extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onQrCodes;
  const TableTopBarWidget({super.key, required this.onAdd, required this.onQrCodes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorder)),
        boxShadow: [BoxShadow(color: Color(0x08000020), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SvgIcon(AppIcons.tableRestaurantRounded, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Table Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
              Text('Track and manage your tables',
                  style: TextStyle(fontSize: 11, color: kMuted)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onQrCodes,
            icon: const SvgIcon(AppIcons.qrCode2Rounded, size: 18, color: kPrimary),
            label: const Text('QR Codes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onAdd,
            icon: const SvgIcon(AppIcons.addRounded, size: 18),
            label: const Text('Add Table', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}