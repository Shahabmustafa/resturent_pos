import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

class RecentOrdersCard extends StatelessWidget {
  const RecentOrdersCard();

  static const _orders = [
    ('#1042', 'Table 5', 'Dine-in', '£1,850.00', 'Paid'),
    ('#1041', 'Walk-in', 'Takeaway', '£950.00', 'Unpaid'),
    ('#1040', 'Delivery', 'Delivery', '£2,100.00', 'Paid'),
    ('#1039', 'Table 2', 'Dine-in', '£3,400.00', 'Partial'),
    ('#1038', 'Walk-in', 'Takeaway', '£700.00', 'Paid'),
  ];

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SvgIcon(AppIcons.receiptRounded, color: _accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Recent Orders', style: TextStyle(color: Color(0xFF1A1D3A), fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: _accent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Table Header
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('Order', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Customer', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Type', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(color: Color(0xFF9396B0), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE8EAF0), height: 1),
          const SizedBox(height: 8),
          ..._orders.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text(o.$1, style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700))),
                Expanded(flex: 2, child: Text(o.$2, style: const TextStyle(color: Color(0xFF3D4060), fontSize: 13))),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(o.$3, style: const TextStyle(color: Color(0xFF6B6F90), fontSize: 11)),
                  ),
                ),
                Expanded(flex: 2, child: Text(o.$4, style: const TextStyle(color: Color(0xFF1A1D3A), fontSize: 13, fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(o.$5, style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}