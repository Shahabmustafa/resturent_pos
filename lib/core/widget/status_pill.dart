import 'package:flutter/material.dart';
import 'svg_icon.dart';

/// Compact rounded status badge for table rows (e.g. "Available", "Paid").
/// It only takes the width of its content, even inside an Expanded cell.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  /// Leading icon; ignored when [dot] is true.
  final AppIcon? icon;

  /// Show a small coloured dot instead of an icon.
  final bool dot;

  /// Small hint icon after the label, e.g. edit or swap when [onTap] is set.
  final AppIcon? trailing;
  final VoidCallback? onTap;
  final String? tooltip;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dot = false,
    this.trailing,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot)
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else if (icon != null)
          SvgIcon(icon!, size: 12, color: color),
        if (dot || icon != null) const SizedBox(width: 5),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          SvgIcon(trailing!, size: 11, color: color.withValues(alpha: 0.6)),
        ],
      ]),
    );

    if (onTap != null) {
      pill = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: pill),
      );
    }
    if (tooltip != null) pill = Tooltip(message: tooltip!, child: pill);
    return Align(alignment: Alignment.centerLeft, child: pill);
  }
}
