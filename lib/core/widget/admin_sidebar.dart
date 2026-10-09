import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selected;
  final int branchCount;
  final int openCount;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.selected,
    required this.branchCount,
    required this.openCount,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    color: AppColors.sidebar,
    child: Column(
      children: [
        // ── Logo ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const SvgIcon(AppIcons.restaurantRounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spice Garden',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text('Owner Portal',
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 10)),
              ],
            ),
          ]),
        ),

        // ── Branch pill ───────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.sidebarSec,
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const SvgIcon(AppIcons.storeOutlined,
                size: 13, color: AppColors.sidebarTxt),
            const SizedBox(width: 6),
            Text('$branchCount Branches',
                style: const TextStyle(
                    color: AppColors.sidebarTxt, fontSize: 11)),
            const Spacer(),
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('$openCount Open',
                style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('MENU',
                style: TextStyle(
                    color: AppColors.sidebarTxt,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ),
        ),
        const SizedBox(height: 6),

        // ── Nav Items ─────────────────────────────────────────
        _NavItem(
          icon: AppIcons.dashboardOutlined,
          iconFill: AppIcons.dashboardRounded,
          label: 'Dashboard',
          active: selected == 0,
          onTap: () => onSelect(0),
        ),
        _NavItem(
          icon: AppIcons.storeMallDirectoryOutlined,
          iconFill: AppIcons.storeMallDirectoryRounded,
          label: 'Branches',
          active: selected == 1,
          onTap: () => onSelect(1),
        ),

        const Spacer(),

        // ── Admin user ────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.sidebarSec,
              borderRadius: BorderRadius.circular(9)),
          child: Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Text('AK',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asif Khan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text('Super Admin',
                      style: TextStyle(
                          color: AppColors.sidebarTxt, fontSize: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onLogout,
              child: const SvgIcon(AppIcons.logoutRounded,
                  size: 14, color: AppColors.sidebarTxt),
            ),
          ]),
        ),
      ],
    ),
  );
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final AppIcon icon, iconFill;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconFill,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(children: [
        SvgIcon(active ? iconFill : icon,
            size: 17,
            color:
            active ? AppColors.primary : AppColors.sidebarTxt),
        const SizedBox(width: 9),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: active
                    ? AppColors.primary
                    : AppColors.sidebarTxt,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal)),
      ]),
    ),
  );
}