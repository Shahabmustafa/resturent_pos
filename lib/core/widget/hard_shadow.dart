import 'package:flutter/material.dart';

/// Solid, un-blurred drop shadow (down and to the right) used on POS buttons.
class HardShadow extends StatelessWidget {
  final Widget child;
  final double offset;
  final bool enabled;
  const HardShadow({
    super.key,
    required this.child,
    this.offset = 3,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: enabled
          ? [BoxShadow(color: Colors.black87, offset: Offset(offset, offset))]
          : null,
    ),
    child: child,
  );
}
