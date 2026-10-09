import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class NavItem {
  final AppIcon icon;
  final String label;
  final String? badge;
  final bool badgeDanger;

  const NavItem({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeDanger = false,
  });
}

class Sidebar extends StatelessWidget {
  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  const Sidebar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: const SvgIcon(AppIcons.restaurant, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spice Garden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('POS System v2.1', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          // Restaurant info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoRow(icon: AppIcons.locationOnOutlined, text: 'Blue Area, Islamabad'),
                SizedBox(height: 4),
                _InfoRow(icon: AppIcons.phoneOutlined, text: '+92 51 234 5678'),
                SizedBox(height: 4),
                _InfoRow(icon: AppIcons.tag, text: 'ID: RES-2024-001'),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final active = selected == i;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primaryLight.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SvgIcon(item.icon, size: 18, color: active ? AppColors.primary : AppColors.sidebarText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: active ? AppColors.primary : AppColors.sidebarText,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (item.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.badgeDanger ? AppColors.danger : AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(item.badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          // Admin footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Super Admin', style: TextStyle(color: AppColors.sidebarText, fontSize: 11)),
                    ],
                  ),
                ),
                const SvgIcon(AppIcons.logout, size: 18, color: AppColors.sidebarText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppIcon icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SvgIcon(icon, size: 12, color: AppColors.sidebarText),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: AppColors.sidebarText, fontSize: 11)),
    ],
  );
}