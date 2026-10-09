import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

class TopSellingCard extends StatelessWidget {
  const TopSellingCard();

  static const _accent = Color(0xFFB91C1C);
  static const _opacities = [1.0, 0.8, 0.6, 0.45, 0.3];

  static const _products = [
    ('Chicken Karahi', '£18,400.00', 92),
    ('Beef Biryani', '£14,200.00', 71),
    ('Seekh Kabab', '£11,800.00', 59),
    ('Naan Bread', '£4,500.00', 45),
    ('Cold Drinks', '£3,200.00', 38),
  ];

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SvgIcon(AppIcons.emojiEventsRounded, color: _accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Top Selling Products', style: TextStyle(color: Color(0xFF1A1D3A), fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Text('by revenue', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          ..._products.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final color = _accent.withOpacity(_opacities[i % _opacities.length]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? _accent.withOpacity(0.2) : const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0 ? _accent : const Color(0xFF9396B0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$1, style: const TextStyle(color: Color(0xFF3D4060), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p.$3 / 100,
                            backgroundColor: const Color(0xFFF0F2F8),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(p.$2, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}