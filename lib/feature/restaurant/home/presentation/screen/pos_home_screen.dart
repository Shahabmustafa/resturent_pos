import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resturent_application/core/widget/hard_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/desktop_window.dart';
import 'package:resturent_application/core/widget/calculator_dialog.dart';
import 'package:resturent_application/core/widget/drawer.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:resturent_application/feature/restaurant/setup/pos_setup.dart';

/// Starts a new sale in POS with this order type ('Dine-in', 'Takeaway', 'Delivery').
typedef StartSale = void Function(String orderType);

class SaleTile {
  final String label;
  final String orderType;
  final AppIcon icon;
  final Color color;
  // Ask for the customer's phone first (collection lookup).
  final bool lookup;
  const SaleTile(
    this.label,
    this.orderType,
    this.icon,
    this.color, {
    this.lookup = false,
  });
}

class _PageTile {
  final POSPage page;
  final String label;
  final AppIcon icon;
  final Color color;
  const _PageTile(this.page, this.label, this.icon, this.color);
}

// SHOP is a quick walk-in counter sale; COLLECTION is a takeaway order to collect later.
const saleTiles = [
  SaleTile('SHOP', 'Shop', AppIcons.storefrontRounded, Color(0xFF0099A8)),
  SaleTile('DINE', 'Dine-in', AppIcons.restaurantRounded, Color(0xFF1A6FD8)),
  SaleTile(
    'COLLECTION',
    'Takeaway',
    AppIcons.shoppingBagRounded,
    Color(0xFFCC0A82),
    lookup: true,
  ),
  SaleTile(
    'DELIVERY',
    'Delivery',
    AppIcons.localShippingRounded,
    Color(0xFFFF7A00),
  ),
];

const _mainTiles = [
  _PageTile(
    POSPage.restaurant,
    'RESTAURANT',
    AppIcons.eventSeatRounded,
    Color(0xFFFF3B2A),
  ),
  _PageTile(
    POSPage.customers,
    'CUSTOMERS',
    AppIcons.peopleRounded,
    Color(0xFF5C4B33),
  ),
  _PageTile(
    POSPage.order,
    'ORDERS',
    AppIcons.receiptLongRounded,
    Color(0xFF6A2CF5),
  ),
  _PageTile(POSPage.menu, 'MENU', AppIcons.menuBookRounded, Color(0xFFD6336C)),
  _PageTile(
    POSPage.salesReport,
    'REPORT',
    AppIcons.barChartRounded,
    Color(0xFF2E8B6E),
  ),
  _PageTile(
    POSPage.till,
    'OPEN TILL',
    AppIcons.pointOfSaleRounded,
    Color(0xFFE8A612),
  ),
  _PageTile(
    POSPage.notes,
    'NOTES',
    AppIcons.stickyNote2Rounded,
    Color(0xFFB8541E),
  ),
];

const _manageColor = Color(0xFF3DBB16);

/// Tile launcher shown after login, in place of a sidebar.
class POSHomeScreen extends StatefulWidget {
  final Set<POSPage> allowed;
  final ValueChanged<POSPage> onOpen;
  final StartSale onStartSale;
  final VoidCallback onCollection;
  final VoidCallback onLock;
  final String branchName;
  // Address, phone, etc. shown bottom-right under the logo.
  final List<String> branchDetails;

  const POSHomeScreen({
    super.key,
    required this.allowed,
    required this.onOpen,
    required this.onStartSale,
    required this.onCollection,
    required this.onLock,
    required this.branchName,
    this.branchDetails = const [],
  });

  @override
  State<POSHomeScreen> createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  /// Sale types switched off in the POS setup are hidden.
  bool _tileOn(SaleTile t) =>
      readPosSetup(context).orderTypes.contains(switch (t.label) {
        'SHOP' => 'carry',
        'DINE' => 'dine',
        'COLLECTION' => 'collection',
        _ => 'delivery',
      });

  Future<void> _confirmShutdown() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Shut down',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Close the POS application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Shut down'),
          ),
        ],
      ),
    );
    if (ok == true) await closeApp();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.allowed;
    final canSell = allowed.contains(POSPage.pos);
    final tiles = [
      for (final t in _mainTiles.where((t) => allowed.contains(t.page)))
        _SplitTile(
          label: t.label,
          icon: t.icon,
          color: t.color,
          onTap: () => widget.onOpen(t.page),
        ),
      if (allowed.contains(POSPage.manage))
        _SplitTile(
          label: 'MANAGE',
          icon: AppIcons.tuneRounded,
          color: _manageColor,
          onTap: () => widget.onOpen(POSPage.manage),
        ),
    ];

    return Container(
      color: const Color(0xFFEDF0EA),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canSell)
                    Column(
                      children: [
                        for (final t in saleTiles)
                          if (_tileOn(t))
                            _SolidTile(
                              tile: t,
                              onTap: () => t.lookup
                                  ? widget.onCollection()
                                  : widget.onStartSale(t.orderType),
                            ),
                      ],
                    ),
                  const SizedBox(width: 110),
                  // Two columns, filled row by row like the reference POS.
                  SizedBox(
                    width: 2 * _SplitTile.width + 20,
                    child: Wrap(spacing: 20, runSpacing: 22, children: tiles),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Raised row: system buttons sit above the clock row, as on the reference POS.
                  Padding(
                    padding: const EdgeInsets.only(left: 200),
                    child: Row(
                      children: [
                        _ControlButton(
                          label: 'System Off',
                          icon: AppIcons.powerSettingsNewRounded,
                          red: true,
                          onTap: _confirmShutdown,
                        ),
                        const SizedBox(width: 12),
                        _ControlButton(
                          label: 'LOCK',
                          icon: AppIcons.lockOutlineRounded,
                          onTap: widget.onLock,
                        ),
                        const SizedBox(width: 12),
                        _ControlButton(
                          label: 'MINIMIZE',
                          icon: AppIcons.removeRounded,
                          onTap: minimizeApp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const _ClockBox(),
                      const SizedBox(width: 10),
                      _ControlButton(
                        label: 'CALCULATOR',
                        icon: AppIcons.calculateOutlined,
                        onTap: () => showCalculator(context),
                      ),
                      const SizedBox(width: 10),
                      if (allowed.contains(POSPage.live))
                        _SplitTile(
                          label: 'DASH',
                          icon: AppIcons.dashboardRounded,
                          color: const Color(0xFF2E6B7D),
                          tileWidth: 150,
                          tileHeight: 72,
                          blockWidth: 56,
                          iconSize: 28,
                          fontSize: 13,
                          onTap: () => widget.onOpen(POSPage.live),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _BranchInfo(
                name: widget.branchName,
                details: widget.branchDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large single-colour tile for starting a sale (left column).
class _SolidTile extends StatelessWidget {
  final SaleTile tile;
  final VoidCallback onTap;
  const _SolidTile({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: HardShadow(
      offset: 4,
      child: Material(
        color: tile.color,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: onTap,
          child: SizedBox(
            width: 200,
            height: 90,
            child: Row(
              children: [
                const SizedBox(width: 14),
                SvgIcon(tile.icon, size: 40, color: Colors.white),
                Expanded(
                  child: Text(
                    tile.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Two-tone tile: coloured icon block on the left, light label panel on the right.
class _SplitTile extends StatelessWidget {
  static const width = 190.0;

  final String label;
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  final double? tileWidth;
  final double tileHeight;
  final double blockWidth;
  final double iconSize;
  final double fontSize;
  const _SplitTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tileWidth,
    this.tileHeight = 76,
    this.blockWidth = 76,
    this.iconSize = 32,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) => HardShadow(
    offset: 4,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: tileWidth ?? width,
          height: tileHeight,
          child: Row(
            children: [
              Container(
                width: blockWidth,
                color: color,
                alignment: Alignment.center,
                child: SvgIcon(icon, size: iconSize, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Grey button with icon over label (shutdown, lock, minimize).
class _ControlButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final VoidCallback onTap;
  final bool red;
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.red = false,
  });

  @override
  Widget build(BuildContext context) => HardShadow(
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: SizedBox(
          width: 130,
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(
                icon,
                size: 28,
                color: red ? const Color(0xFFE02020) : const Color(0xFF111111),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: red
                      ? const Color(0xFFE02020)
                      : const Color(0xFF222222),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Live date and time, bottom-left of the home screen.
class _ClockBox extends StatefulWidget {
  const _ClockBox();

  @override
  State<_ClockBox> createState() => _ClockBoxState();
}

class _ClockBoxState extends State<_ClockBox> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      width: 190,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF4527A8),
        border: Border(left: BorderSide(color: Colors.black, width: 14)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('EEE dd.MM.yy').format(now),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            DateFormat('h:mm a').format(now),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo with the restaurant's name and contact details, bottom-right.
class _BranchInfo extends StatelessWidget {
  final String name;
  final List<String> details;
  const _BranchInfo({required this.name, required this.details});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'assets/branding/app_icon.svg',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFA8431F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final line in details)
          Text(
            line,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              height: 1.4,
            ),
          ),
      ],
    ),
  );
}
