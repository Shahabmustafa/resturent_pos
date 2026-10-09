import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/model/dish_model.dart';
import '../provider/cart_provider.dart';
import '../theme/customer_theme.dart';
import 'customer_widgets.dart';
import 'depth_effects.dart';

/// Grid card for a dish: image, name, price and a quick-add button.
class DishCard extends ConsumerWidget {
  final Dish dish;

  const DishCard({super.key, required this.dish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tilt3D owns the hover shadow so it can follow the tilt direction.
    return Tilt3D(
      child: Hoverable(
        builder: (context, hovered) => Material(
          color: CColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: hovered ? CColors.gold.withValues(alpha: .6) : CColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDishDialog(context, dish),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TiltDepth(depth: 5, child: ZoomImage(dish.image, zoomed: hovered)),
                      if (dish.isSignature)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
                            decoration: BoxDecoration(color: CColors.rust, borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SvgIcon(AppIcons.starRounded, size: 11, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  'SIGNATURE',
                                  style: CText.body(
                                    10,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                  ).copyWith(letterSpacing: .6),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        // Reserve two lines so prices line up across a row.
                        height: 36,
                        child: Text(
                          dish.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description, or the sizes when the POS item has none.
                      SizedBox(
                        height: 35,
                        child: dish.description.isNotEmpty
                            ? Text(
                                dish.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CText.body(12, color: CColors.muted, height: 1.45),
                              )
                            : dish.hasOptions
                            ? _SizeTags(options: dish.options)
                            : Text('Cooked fresh to order', style: CText.body(12, color: CColors.muted, height: 1.45)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _Price(dish: dish)),
                          _AddButton(
                            onTap: () {
                              if (dish.hasOptions) {
                                showDishDialog(context, dish);
                              } else {
                                ref.read(cartProvider.notifier).add(dish, dish.options.first);
                                showAddedSnack(context, dish.name);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small size tags ("Small", "Large", …) on one line; extra sizes collapse to "+N".
class _SizeTags extends StatelessWidget {
  final List<DishOption> options;

  const _SizeTags({required this.options});

  static double _tagWidth(String text, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: CText.body(11, weight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    // padding + border + gap, plus a small allowance: the web font can render a
    // fraction of a pixel wider than measured once it finishes loading.
    return painter.width + 16 + 2 + 5 + 3;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        var used = 0.0;
        var fit = 0;
        for (var i = 0; i < options.length; i++) {
          final reserve = i == options.length - 1 ? 0.0 : _tagWidth('+${options.length - i - 1}', scaler);
          final w = _tagWidth(options[i].label, scaler);
          if (used + w + reserve > c.maxWidth) break;
          used += w;
          fit++;
        }
        final extra = options.length - fit;
        Widget tag(String text) => Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CColors.line),
          ),
          child: Text(
            text,
            style: CText.body(11, color: CColors.olive, weight: FontWeight.w600),
          ),
        );
        // A non-scrolling horizontal view clips the row, so a rounding difference
        // can never paint an overflow stripe.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final o in options.take(fit)) tag(o.label), if (extra > 0) tag('+$extra')],
          ),
        );
      },
    );
  }
}

/// "from £11.00" for dishes with sizes; a full range doesn't fit narrow cards.
class _Price extends StatelessWidget {
  final Dish dish;

  const _Price({required this.dish});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (dish.hasOptions)
            TextSpan(
              text: 'from ',
              style: CText.body(11.5, color: CColors.muted),
            ),
          TextSpan(text: formatPrice(dish.fromPrice)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CText.body(15, color: CColors.rust, weight: FontWeight.w700),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add to cart',
      child: Material(
        color: CColors.rust,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(9),
            child: SvgIcon(AppIcons.addRounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

void showAddedSnack(BuildContext context, String name) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(duration: const Duration(milliseconds: 1600), content: Text('$name added to cart')));
}

Future<void> showDishDialog(BuildContext context, Dish dish) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: CColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _DishDialog(dish: dish),
      ),
    ),
  );
}

class _DishDialog extends ConsumerStatefulWidget {
  final Dish dish;

  const _DishDialog({required this.dish});

  @override
  ConsumerState<_DishDialog> createState() => _DishDialogState();
}

class _DishDialogState extends ConsumerState<_DishDialog> {
  late DishOption _option = widget.dish.options.first;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(height: 240, width: double.infinity, child: FoodImage(dish.image)),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: SvgIcon(AppIcons.closeRounded, size: 20, color: CColors.ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name, style: CText.display(24)),
                  const SizedBox(height: 8),
                  Text(dish.description, style: CText.body(14.5, color: CColors.muted, height: 1.6)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: const [_Tag('100% Halal'), _Tag('Cooked fresh to order')]),
                  if (dish.hasOptions) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Choose size',
                      style: CText.body(14, color: CColors.ink, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    for (final o in dish.options)
                      _OptionTile(option: o, selected: o == _option, onTap: () => setState(() => _option = o)),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      QtyStepper(qty: _qty, onChanged: (v) => setState(() => _qty = v.clamp(1, 99))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: PillButton(
                          label: 'Add  •  ${formatPrice(_option.price * _qty)}',
                          expand: true,
                          onPressed: () {
                            ref.read(cartProvider.notifier).add(dish, _option, qty: _qty);
                            Navigator.pop(context);
                            showAddedSnack(context, dish.name);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: CColors.cream, borderRadius: BorderRadius.circular(30)),
      child: Text(
        label,
        style: CText.body(12, color: CColors.olive, weight: FontWeight.w600),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final DishOption option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? CColors.goldPale.withValues(alpha: 0.45) : CColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? CColors.gold : CColors.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              SvgIcon(
                selected ? AppIcons.checkCircleRounded : AppIcons.radioButtonUncheckedRounded,
                size: 20,
                color: selected ? CColors.rust : CColors.mutedLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(option.label, style: CText.body(14.5, weight: FontWeight.w500)),
              ),
              Text(
                formatPrice(option.price),
                style: CText.body(14.5, color: CColors.ink, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final bool compact;

  const QtyStepper({super.key, required this.qty, required this.onChanged, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 6.0 : 11.0;
    Widget btn(AppIcon icon, int delta) => InkWell(
      customBorder: const CircleBorder(),
      onTap: () => onChanged(qty + delta),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: SvgIcon(icon, size: compact ? 16 : 18, color: CColors.ink),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: CColors.cream,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: CColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(AppIcons.removeRounded, -1),
          SizedBox(
            width: compact ? 22 : 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: CText.body(compact ? 13.5 : 15, color: CColors.ink, weight: FontWeight.w600),
            ),
          ),
          btn(AppIcons.addRounded, 1),
        ],
      ),
    );
  }
}
