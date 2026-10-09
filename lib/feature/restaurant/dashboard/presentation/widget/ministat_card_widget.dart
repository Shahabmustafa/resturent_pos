import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

class MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final AppIcon icon;
  final Color color;
  const MiniStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: [BoxShadow(color: Color(0x0D000030), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgIcon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(color: const Color(0xFF1A1D3A), fontSize: 16, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(color: const Color(0xFF9396B0), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
