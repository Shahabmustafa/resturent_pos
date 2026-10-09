import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../theme/customer_theme.dart';

/// Food image — a network URL (POS menu photos in Supabase storage) or a
/// bundled asset — with a warm placeholder while loading, when empty, or on error.
class FoodImage extends StatelessWidget {
  final String source;
  final BoxFit fit;

  const FoodImage(this.source, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const _Placeholder();
    Widget frame(BuildContext _, Widget child, int? frame, bool sync) =>
        sync || frame != null ? child : const _Placeholder();
    Widget error(BuildContext _, Object _, StackTrace? _) => const _Placeholder();

    return source.startsWith('http')
        ? Image.network(
            source,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          )
        : Image.asset(
            source,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: frame,
            errorBuilder: error,
          );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CColors.cream2,
      alignment: Alignment.center,
      child: const SvgIcon(AppIcons.restaurantRounded, size: 28, color: CColors.mutedLight),
    );
  }
}

/// Web hover affordance: lifts [child] and exposes the hover state to [builder]
/// (e.g. to zoom an image). No-op on touch devices, which never report hover.
class Hoverable extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final double lift;

  const Hoverable({super.key, required this.builder, this.lift = 4});

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}

/// Image that eases into a slight zoom while [zoomed] is true.
class ZoomImage extends StatelessWidget {
  final String asset;
  final bool zoomed;

  const ZoomImage(this.asset, {super.key, required this.zoomed});

  @override
  Widget build(BuildContext context) {
    return FoodImage(asset);
  }
}

enum PillStyle { rust, gold, outlineDark, outlineLight }

/// Rounded pill button — matches the site's `.btn-*` variants.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final AppIcon? icon;
  final bool small;
  final bool expand;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.rust,
    this.icon,
    this.small = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color? bg, Gradient? gradient, Color fg, Color? border, List<BoxShadow>? shadow) = switch (style) {
      PillStyle.rust => (CColors.rust, null, Colors.white, null, CShadows.rust),
      PillStyle.gold => (null, CColors.goldGradient, CColors.ink, null, null),
      PillStyle.outlineDark => (null, null, CColors.ink, CColors.ink, null),
      PillStyle.outlineLight => (null, null, Colors.white, Colors.white70, null),
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: CText.body(small ? 13.5 : 14.5, color: fg, weight: FontWeight.w600),
          ),
        ),
        if (icon != null) ...[const SizedBox(width: 9), SvgIcon(icon, size: 16, color: fg)],
      ],
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: BorderRadius.circular(50),
          border: border == null ? null : Border.all(color: border, width: 1.5),
          boxShadow: onPressed == null ? null : shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 22 : 30, vertical: small ? 11 : 15),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Optional eyebrow + serif title + optional subtitle, used at the top of each section.
class SectionHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final bool light;
  final CrossAxisAlignment align;

  const SectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.light = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final center = align == CrossAxisAlignment.center;
    final textAlign = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        if (eyebrow != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 22, height: 1.5, color: light ? CColors.goldLight : CColors.rust),
              const SizedBox(width: 10),
              Text(eyebrow!.toUpperCase(), style: CText.eyebrow(color: light ? CColors.goldLight : CColors.rust)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: CText.display(30, color: light ? Colors.white : CColors.ink),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: CText.body(15, color: light ? CColors.mutedLight : CColors.muted, height: 1.6),
          ),
        ],
      ],
    );
  }
}

/// Small round icon badge with shadow — used for trust badges and contact rows.
class IconBadge extends StatelessWidget {
  final AppIcon icon;
  final double size;
  final Color background;
  final Color color;

  const IconBadge(this.icon, {super.key, this.size = 38, this.background = CColors.paper, this.color = CColors.rust});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle, boxShadow: CShadows.soft),
      alignment: Alignment.center,
      child: SvgIcon(icon, size: size * 0.44, color: color),
    );
  }
}

/// Loading spinner / error-with-retry / empty message for the live menu.
class MenuStatus extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final String emptyText;

  const MenuStatus.loading({super.key}) : loading = true, error = null, onRetry = null, emptyText = '';

  const MenuStatus.error({super.key, required String this.error, required VoidCallback this.onRetry})
    : loading = false,
      emptyText = '';

  const MenuStatus.empty(this.emptyText, {super.key}) : loading = false, error = null, onRetry = null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: CColors.rust),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(
                    error != null ? AppIcons.warningRounded : AppIcons.restaurantRounded,
                    size: 38,
                    color: CColors.mutedLight,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error != null ? 'Couldn\'t load the menu. Check your internet connection.' : emptyText,
                    textAlign: TextAlign.center,
                    style: CText.body(14.5, color: CColors.muted),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    PillButton(label: 'Try again', small: true, style: PillStyle.outlineDark, onPressed: onRetry),
                  ],
                ],
              ),
      ),
    );
  }
}

void copyToClipboard(BuildContext context, String value, String what) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what copied: $value')));
}
