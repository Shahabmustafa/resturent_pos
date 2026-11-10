import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'pos_setup';

/// Till settings kept on this computer: general, display and printer choices.
class PosSetup {
  // General
  final bool virtualKeyboard;
  final int zoom; // percent
  final bool orderSound;
  final Set<String> orderTypes; // carry, dine, collection, delivery
  final Set<String> payMethods; // cash, card, cashDue

  // Display
  final String menuBackground; // #RRGGBB
  final int productWidth;
  final int productHeight;
  final int categoryWidth;
  final int categoryHeight;
  final int productFont;
  final int categoryFont;
  final bool nameOnly;
  final bool onlinePopup;
  final int cartWidth; // invoice panel, in pixels
  final int postcodesPerPage;
  final int customersPerPage;

  // Print
  final String printerName; // empty = ask every time
  final String printerUrl;

  const PosSetup({
    this.virtualKeyboard = true,
    this.zoom = 100,
    this.orderSound = true,
    this.orderTypes = const {'carry', 'dine', 'collection', 'delivery'},
    this.payMethods = const {'cash', 'card', 'cashDue'},
    this.menuBackground = '#12507F',
    this.productWidth = 150,
    this.productHeight = 92,
    this.categoryWidth = 205,
    this.categoryHeight = 80,
    this.productFont = 12,
    this.categoryFont = 18,
    this.nameOnly = false,
    this.onlinePopup = true,
    this.cartWidth = 380,
    this.postcodesPerPage = 30,
    this.customersPerPage = 15,
    this.printerName = '',
    this.printerUrl = '',
  });

  Color get menuColor {
    final hex = menuBackground.replaceAll('#', '').trim();
    final v = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return v == null ? const Color(0xFF2F6FD6) : Color(v);
  }

  Map<String, dynamic> toJson() => {
    'virtualKeyboard': virtualKeyboard,
    'zoom': zoom,
    'orderSound': orderSound,
    'orderTypes': orderTypes.toList(),
    'payMethods': payMethods.toList(),
    'menuBackground': menuBackground,
    'productWidth': productWidth,
    'productHeight': productHeight,
    'categoryWidth': categoryWidth,
    'categoryHeight': categoryHeight,
    'productFont': productFont,
    'categoryFont': categoryFont,
    'nameOnly': nameOnly,
    'onlinePopup': onlinePopup,
    'cartWidth': cartWidth,
    'postcodesPerPage': postcodesPerPage,
    'customersPerPage': customersPerPage,
    'printerName': printerName,
    'printerUrl': printerUrl,
  };

  factory PosSetup.fromJson(Map<String, dynamic> j) {
    const d = PosSetup();
    Set<String> set(String k, Set<String> def) =>
        j[k] is List ? {...(j[k] as List).cast<String>()} : def;
    return PosSetup(
      virtualKeyboard: j['virtualKeyboard'] as bool? ?? d.virtualKeyboard,
      zoom: j['zoom'] as int? ?? d.zoom,
      orderSound: j['orderSound'] as bool? ?? d.orderSound,
      orderTypes: set('orderTypes', d.orderTypes),
      payMethods: set('payMethods', d.payMethods),
      menuBackground: j['menuBackground'] as String? ?? d.menuBackground,
      productWidth: j['productWidth'] as int? ?? d.productWidth,
      productHeight: j['productHeight'] as int? ?? d.productHeight,
      categoryWidth: j['categoryWidth'] as int? ?? d.categoryWidth,
      categoryHeight: j['categoryHeight'] as int? ?? d.categoryHeight,
      productFont: j['productFont'] as int? ?? d.productFont,
      categoryFont: j['categoryFont'] as int? ?? d.categoryFont,
      nameOnly: j['nameOnly'] as bool? ?? d.nameOnly,
      onlinePopup: j['onlinePopup'] as bool? ?? d.onlinePopup,
      cartWidth: j['cartWidth'] as int? ?? d.cartWidth,
      postcodesPerPage: j['postcodesPerPage'] as int? ?? d.postcodesPerPage,
      customersPerPage: j['customersPerPage'] as int? ?? d.customersPerPage,
      printerName: j['printerName'] as String? ?? d.printerName,
      printerUrl: j['printerUrl'] as String? ?? d.printerUrl,
    );
  }
}

class PosSetupNotifier extends StateNotifier<PosSetup> {
  PosSetupNotifier() : super(const PosSetup()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (raw != null && mounted) {
        state = PosSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Unreadable settings: keep the defaults.
    }
  }

  Future<void> save(PosSetup s) async {
    state = s;
    await (await SharedPreferences.getInstance()).setString(
      _prefsKey,
      jsonEncode(s.toJson()),
    );
  }
}

final posSetupProvider = StateNotifierProvider<PosSetupNotifier, PosSetup>(
  (_) => PosSetupNotifier(),
);

/// Reads the setup from a widget that is not a Riverpod consumer.
PosSetup readPosSetup(BuildContext context) =>
    ProviderScope.containerOf(context).read(posSetupProvider);
