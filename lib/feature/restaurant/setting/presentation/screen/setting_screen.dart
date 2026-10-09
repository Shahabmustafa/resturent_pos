import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/screen/receipt_tab.dart';
import '../../../../../core/constants/app_colors.dart';
import 'company_tab.dart';
import '../widget/data_reset_tab.dart';
import '../widget/tax_tab_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0;

  final _tabs = const [
    (icon: AppIcons.businessOutlined, label: 'Company'),
    (icon: AppIcons.receiptOutlined, label: 'Receipt'),
    (icon: AppIcons.percentOutlined, label: 'Tax / FBR'),
    (icon: AppIcons.storageOutlined, label: 'Data & Reset'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings sidebar
        Container(
          width: 196,
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text('Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5)),
              ),
              ...List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final active = _tab == i;
                return GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SvgIcon(t.icon, size: 17, color: active ? AppColors.primary : AppColors.textGrey),
                        const SizedBox(width: 10),
                        Text(t.label, style: TextStyle(fontSize: 13, color: active ? AppColors.primary : AppColors.textGrey, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Container(width: 1, color: AppColors.border),
        // Tab content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: [
              const CompanyTab(),
              const ReceiptTab(),
              const TaxTab(),
              const DataResetTab(),
            ][_tab],
          ),
        ),
      ],
    );
  }
}