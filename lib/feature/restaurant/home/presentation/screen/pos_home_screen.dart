import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/desktop_window.dart';
import 'package:resturent_application/core/widget/drawer.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

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
  SaleTile('SHOP', 'Shop', AppIcons.storefrontRounded, Color(0xFF0096A8)),
  SaleTile('DINE', 'Dine-in', AppIcons.restaurantRounded, Color(0xFF2368D6)),
  SaleTile(
    'COLLECTION',
    'Takeaway',
    AppIcons.shoppingBagRounded,
    Color(0xFFC9168A),
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
    Color(0xFFFF4033),
  ),
  _PageTile(
    POSPage.customers,
    'CUSTOMERS',
    AppIcons.peopleRounded,
    Color(0xFF664A31),
  ),
  _PageTile(
    POSPage.order,
    'ORDERS',
    AppIcons.receiptLongRounded,
    Color(0xFF6A2CF5),
  ),
  _PageTile(
    POSPage.menu,
    'MENU',
    AppIcons.menuBookRounded,
    Color(0xFFD6336C),
  ),
  _PageTile(
    POSPage.salesReport,
    'REPORT',
    AppIcons.barChartRounded,
    Color(0xFF2E8B78),
  ),
  _PageTile(
    POSPage.till,
    'OPEN TILL',
    AppIcons.pointOfSaleRounded,
    Color(0xFFE8A512),
  ),
  _PageTile(
    POSPage.notes,
    'NOTES',
    AppIcons.stickyNote2Rounded,
    Color(0xFFB5541E),
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
      color: const Color(0xFFE9E9E9),
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 24),
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
                          _SolidTile(
                            tile: t,
                            onTap: () => t.lookup
                                ? widget.onCollection()
                                : widget.onStartSale(t.orderType),
                          ),
                      ],
                    ),
                  const SizedBox(width: 120),
                  // Two columns, filled row by row like the reference POS.
                  SizedBox(
                    width: 2 * _SplitTile.width + 20,
                    child: Wrap(spacing: 20, runSpacing: 24, children: tiles),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _ClockBox(),
              const SizedBox(width: 14),
              if (allowed.contains(POSPage.live))
                _SplitTile(
                  label: 'DASH',
                  icon: AppIcons.dashboardRounded,
                  color: const Color(0xFF2E6B85),
                  onTap: () => widget.onOpen(POSPage.live),
                ),
              const Spacer(),
              _ControlButton(
                label: 'SHUTDOWN',
                icon: AppIcons.powerSettingsNewRounded,
                onTap: _confirmShutdown,
              ),
              const SizedBox(width: 14),
              _ControlButton(
                label: 'LOCK',
                icon: AppIcons.lockOutlineRounded,
                onTap: widget.onLock,
              ),
              const SizedBox(width: 14),
              _ControlButton(
                label: 'MINIMIZE',
                icon: AppIcons.removeRounded,
                onTap: minimizeApp,
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
    padding: const EdgeInsets.only(bottom: 30),
    child: Material(
      color: tile.color,
      elevation: 6,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: SizedBox(
          width: 200,
          height: 84,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: SvgIcon(tile.icon, size: 26, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

/// Two-tone tile: coloured icon block on the left, light label panel on the right.
class _SplitTile extends StatelessWidget {
  static const width = 210.0;

  final String label;
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  const _SplitTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black,
    borderRadius: BorderRadius.circular(3),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 72,
        child: Row(
          children: [
            Container(
              width: 68,
              color: color,
              alignment: Alignment.center,
              child: SvgIcon(icon, size: 28, color: Colors.white),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEEF2F6),
    elevation: 3,
    borderRadius: BorderRadius.circular(3),
    child: InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: onTap,
      child: SizedBox(
        width: 130,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(icon, size: 24, color: const Color(0xFF4B5563)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4A2A2A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEE dd.MM.yy').format(now),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            DateFormat('h:mm a').format(now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
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
    width: 240,
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
