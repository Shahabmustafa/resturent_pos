import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/screen/setting_screen.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widget/sidebar_nav_widget.dart';
import '../widget/top_bar_widget.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selected = 10; // Settings index

  final _navItems = const [
    NavItem(icon: AppIcons.dashboardOutlined, label: 'Dashboard'),
    NavItem(icon: AppIcons.tableRestaurantOutlined, label: 'Table Management'),
    NavItem(icon: AppIcons.menuBookOutlined, label: 'Menu & Categories'),
    NavItem(icon: AppIcons.receiptLongOutlined, label: 'POS / Orders', badge: '3'),
    NavItem(icon: AppIcons.kitchenOutlined, label: 'Kitchen Display', badge: '5'),
    NavItem(icon: AppIcons.inventory2Outlined, label: 'Inventory', badge: '!', badgeDanger: true),
    NavItem(icon: AppIcons.deliveryDiningOutlined, label: 'Delivery'),
    NavItem(icon: AppIcons.barChartOutlined, label: 'Financial Reports'),
    NavItem(icon: AppIcons.peopleOutline, label: 'Customers'),
    NavItem(icon: AppIcons.manageAccountsOutlined, label: 'User Management'),
    NavItem(icon: AppIcons.settingsOutlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          Sidebar(
            items: _navItems,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(title: _navItems[_selected].label),
                Expanded(
                  child: _selected == 10
                      ? const SettingsScreen()
                      : _PlaceholderPage(label: _navItems[_selected].label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;

  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(label, style: const TextStyle(fontSize: 22, color: AppColors.textGrey)),
  );
}