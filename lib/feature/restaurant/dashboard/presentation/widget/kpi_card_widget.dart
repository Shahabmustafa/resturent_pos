import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool positive;
  final AppIcon icon;
  final Color color;

  const KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.positive,
    required this.icon,
    required this.color,
  });

  static const _accent = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: [BoxShadow(color: Color(0x0D000030), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgIcon(icon, color: _accent, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFF1A1D3A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: Color(0xFF9396B0), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}