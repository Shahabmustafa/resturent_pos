import 'package:flutter_riverpod/legacy.dart';

enum CustomerTab { home, menu, cart, orders, contact, profile }

final customerTabProvider = StateProvider<CustomerTab>((_) => CustomerTab.home);

/// Category selected on the Menu tab; set from Home so tiles deep-link.
/// Null = the first category of the live menu.
final menuCategoryProvider = StateProvider<String?>((_) => null);
