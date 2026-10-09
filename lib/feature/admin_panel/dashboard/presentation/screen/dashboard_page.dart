import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../branches/data/model/branches_model.dart';
import '../../../widget/shared_widget.dart';


class DashboardPage extends StatelessWidget {
  final List<Branch> branches;
  final ValueChanged<String> onBranchTap;

  const DashboardPage({
    super.key,
    required this.branches,
    required this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
    branches.fold(0.0, (s, b) => s + b.monthSales);
    final openCount = branches.where((b) => b.isOpen).length;

    return Column(
      children: [
        const AdminTopBar(
          title: 'Dashboard',
          subtitle: 'All branches overview',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KPI Row ───────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: KpiCard(
                      label: 'Monthly Revenue',
                      value: rsFormat(totalRevenue),
                      icon: AppIcons.paymentsOutlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      label: 'Total Branches',
                      value: '${branches.length}',
                      icon: AppIcons.storeOutlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      label: 'Open Now',
                      value: '$openCount/${branches.length}',
                      icon: AppIcons.checkCircleOutline,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      label: 'Closed',
                      value: '${branches.length - openCount}',
                      icon: AppIcons.cancelOutlined,
                      color: AppColors.danger,
                    ),
                  ),
                ]),

                const SizedBox(height: 22),

                const Text('Branch Performance',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark)),
                const SizedBox(height: 12),

                // ── Branch cards 2x2 grid ─────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: branches
                      .map((b) => _DashBranchCard(
                    branch: b,
                    onTap: () => onBranchTap(b.id),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashboard Branch Card ─────────────────────────────────────────────────────
class _DashBranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onTap;

  const _DashBranchCard({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: branch.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgIcon(AppIcons.storeOutlined,
              color: branch.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(branch.name,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark),
                  overflow: TextOverflow.ellipsis),
              Text('${branch.city}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grey),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Text(rsFormat(branch.monthSales),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: branch.color)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: branch.targetPct,
                      minHeight: 4,
                      backgroundColor: AppColors.greyLt,
                      valueColor: AlwaysStoppedAnimation(branch.color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${(branch.targetPct * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 10,
                        color: branch.color,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 10),
        StatusBadge(isOpen: branch.isOpen),
      ]),
    ),
  );
}