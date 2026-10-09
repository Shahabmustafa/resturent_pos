import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({super.key, this.title = 'Settings'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SvgIcon(AppIcons.calendarTodayOutlined, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Today — Jun 10, 2026', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              const SvgIcon(AppIcons.notificationsOutlined, size: 24, color: AppColors.textGrey),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}