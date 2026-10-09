import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/widget/section_card_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import 'field_widget.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  static const _users = [
    {'initials': 'AH', 'name': 'Ahmed Hassan', 'role': 'Admin', 'email': 'ahmed@sg.pk', 'color': Color(0xFF7F77DD)},
    {'initials': 'ZA', 'name': 'Zain Abbas', 'role': 'Cashier', 'email': 'zain@sg.pk', 'color': Color(0xFF1D9E75)},
    {'initials': 'IM', 'name': 'Imran Malik', 'role': 'Chef', 'email': 'imran@sg.pk', 'color': Color(0xFFB91C1C)},
    {'initials': 'RK', 'name': 'Rahul Khan', 'role': 'Rider', 'email': 'rahul@sg.pk', 'color': Color(0xFF378ADD)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'User Management',
          subtitle: 'Role-based access — each user sees only their own pages',
        ),
        SectionCard(title: 'TEAM MEMBERS', children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(''),
              PrimaryBtn(label: 'Add user', icon: AppIcons.personAddOutlined, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.4,
            children: _users.map((u) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: (u['color'] as Color).withOpacity(0.15),
                    child: Text(u['initials'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: u['color'] as Color)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(u['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        Text(u['email'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: (u['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Text(u['role'] as String, style: TextStyle(fontSize: 11, color: u['color'] as Color, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  const SvgIcon(AppIcons.editOutlined, size: 15, color: AppColors.textGrey),
                ],
              ),
            )).toList(),
          ),
        ]),
        SectionCard(title: 'ROLE PERMISSIONS', children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                children: ['Page', 'Admin', 'Cashier', 'Chef', 'Rider'].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey), textAlign: h == 'Page' ? TextAlign.left : TextAlign.center),
                )).toList(),
              ),
              ...const [
                ['POS / Sale Invoice', true, true, false, false],
                ['Orders', true, true, true, false],
                ['Delivery', true, false, false, true],
                ['Settings', true, false, false, false],
              ].map((row) => TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                children: row.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: e.key == 0
                      ? Text(e.value as String, style: const TextStyle(fontSize: 12, color: AppColors.textDark))
                      : Center(child: SvgIcon(e.value as bool ? AppIcons.checkCircleRounded : AppIcons.remove, size: 16, color: e.value as bool ? AppColors.success : AppColors.border)),
                )).toList(),
              )),
            ],
          ),
        ]),
      ],
    );
  }
}