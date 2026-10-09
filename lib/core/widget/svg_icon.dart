import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reference to an SVG icon asset. Drop-in replacement for Flutter's [IconData].
class AppIcon {
  final String asset;
  const AppIcon(this.asset);
}

/// Drop-in replacement for Flutter's [Icon] that renders an SVG asset.
/// Size and color fall back to the ambient [IconTheme], same as [Icon].
class SvgIcon extends StatelessWidget {
  final AppIcon? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const SvgIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final theme = IconTheme.of(context);
    final iconSize = size ?? theme.size ?? 24.0;
    if (icon == null) return SizedBox(width: iconSize, height: iconSize);

    var iconColor = color ?? theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    if (opacity != null && opacity != 1.0) {
      iconColor = iconColor.withValues(alpha: iconColor.a * opacity);
    }

    // Same layout as Flutter's Icon: the outer box may be stretched by tight
    // parent constraints, but the glyph stays centered at [iconSize].
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Center(
        child: SvgPicture.asset(
          icon.asset,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          semanticsLabel: semanticLabel,
        ),
      ),
    );
  }
}
