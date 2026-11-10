import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

/// Bottom strip of the desktop till: clock, item search, item count, and the
/// Menu and Comments buttons.
class TillBottomBarWidget extends StatefulWidget {
  final String userName;
  final int itemCount;
  final bool hasItems;
  final int heldCount;
  final VoidCallback onHeld;
  final ValueChanged<String> onSearch;
  final ValueChanged<BuildContext> onMenu;
  final VoidCallback onComments;

  const TillBottomBarWidget({
    super.key,
    required this.userName,
    required this.itemCount,
    this.hasItems = false,
    this.heldCount = 0,
    required this.onHeld,
    required this.onSearch,
    required this.onMenu,
    required this.onComments,
  });

  @override
  State<TillBottomBarWidget> createState() => _TillBottomBarWidgetState();
}

class _TillBottomBarWidgetState extends State<TillBottomBarWidget> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFD3D3D3),
    padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
    child: Row(
      children: [
        _ClockBox(userName: widget.userName, hasItems: widget.hasItems),
        const SizedBox(width: 4),
        SizedBox(
          width: 150,
          height: 66,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      color: const Color(0xFFE8201B),
                      alignment: Alignment.center,
                      child: const SvgIcon(
                        AppIcons.searchRounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _search,
                          onChanged: widget.onSearch,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'search',
                            hintStyle: TextStyle(color: Color(0xFF444444)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      color: const Color(0xFF12A67A),
                      alignment: Alignment.center,
                      child: const SvgIcon(
                        AppIcons.shoppingCartOutlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.itemCount}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Builder(
          builder: (ctx) => _BarButton(
            label: 'Menu',
            icon: AppIcons.menuBookRounded,
            color: const Color(0xFF9050C0),
            onTap: () => widget.onMenu(ctx),
          ),
        ),
        const SizedBox(width: 6),
        _BarButton(
          label: 'Comments',
          icon: AppIcons.stickyNote2Rounded,
          color: widget.hasItems
              ? const Color(0xFFE32D0E)
              : const Color(0xFFCFCFCF),
          dark: !widget.hasItems,
          onTap: widget.onComments,
        ),
        const SizedBox(width: 6),
        _BarButton(
          label: 'Hold List (${widget.heldCount})',
          icon: AppIcons.receiptLongRounded,
          color: widget.heldCount > 0
              ? const Color(0xFFFF7200)
              : const Color(0xFFCFCFCF),
          dark: widget.heldCount == 0,
          onTap: widget.onHeld,
        ),
      ],
    ),
  );
}

class _ClockBox extends StatefulWidget {
  final String userName;
  final bool hasItems;
  const _ClockBox({required this.userName, required this.hasItems});

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
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    height: 66,
    child: Row(
      children: [
        Container(
          width: 18,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: widget.hasItems
                ? const Color(0xFFE32D0E)
                : const Color(0xFF2778C4),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('h:mm a').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.white54),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/branding/app_icon.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.userName.isEmpty
                              ? 'PakAfghan'
                              : widget.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BarButton extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final Color color;
  final bool dark;
  final VoidCallback onTap;
  const _BarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFF6B6E68) : Colors.white;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black87, offset: Offset(3, 3))],
      ),
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 120,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(icon, size: 24, color: fg),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(color: fg, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
