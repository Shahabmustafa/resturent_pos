import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_colors.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';

/// One tab in an [AppTabBar].
class AppTabItem {
  final String label;
  final AppIcon? icon;

  /// Optional counter shown as a small badge next to the label.
  final int? count;

  const AppTabItem(this.label, {this.icon, this.count});
}

/// Segmented pill tab bar used across the app.
///
/// Drive it either with a [TabController] (`controller:`) or with
/// [index] + [onChanged] for tabs that are plain state.
/// [expand] stretches the tabs to share the full width; otherwise the bar
/// hugs its content and scrolls horizontally when there is not enough room.
class AppTabBar extends StatelessWidget {
  final List<AppTabItem> items;
  final TabController? controller;
  final int index;
  final ValueChanged<int>? onChanged;
  final bool expand;

  const AppTabBar({
    super.key,
    required this.items,
    this.controller,
    this.index = 0,
    this.onChanged,
    this.expand = true,
  }) : assert(controller != null || onChanged != null,
            'Provide either a controller or onChanged');

  static const _track = Color(0xFFEEF0F6);

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return _buildBar(index);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => _buildBar(controller.index),
    );
  }

  void _select(int i) {
    final controller = this.controller;
    if (controller != null) {
      controller.animateTo(i);
    } else {
      onChanged!(i);
    }
  }

  Widget _buildBar(int selected) {
    final tabs = List.generate(items.length, (i) {
      final tab = _AppTab(
        item: items[i],
        selected: i == selected,
        shrinkLabel: expand,
        onTap: () => _select(i),
      );
      return expand ? Expanded(child: tab) : tab;
    });

    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            tabs[i],
          ],
        ],
      ),
    );

    if (expand) return track;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: track),
    );
  }
}

class _AppTab extends StatelessWidget {
  final AppTabItem item;
  final bool selected;

  /// Let the label ellipsize; only valid when the tab has bounded width.
  final bool shrinkLabel;
  final VoidCallback onTap;

  const _AppTab({
    required this.item,
    required this.selected,
    required this.shrinkLabel,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.grey;

    final label = AnimatedDefaultTextStyle(
      duration: _duration,
      style: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: fg,
      ),
      child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x1A101828), blurRadius: 6, offset: Offset(0, 2))]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            hoverColor: AppColors.primary.withValues(alpha: 0.06),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: shrinkLabel ? 10 : 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon != null) ...[
                    SvgIcon(item.icon, size: 17, color: fg),
                    const SizedBox(width: 8),
                  ],
                  if (shrinkLabel) Flexible(child: label) else label,
                  if (item.count != null) ...[
                    const SizedBox(width: 8),
                    _CountBadge(count: item.count!, selected: selected),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _CountBadge({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.greyLt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.grey,
        ),
      ),
    );
  }
}
