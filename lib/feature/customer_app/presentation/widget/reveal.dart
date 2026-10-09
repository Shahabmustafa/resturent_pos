import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fades and slides [child] up the first time it scrolls into view, rising
/// from slight depth with a small backward tilt that settles flat.
/// Shows immediately when the platform asks for reduced motion.
class Reveal extends StatefulWidget {
  final Widget child;

  /// Extra wait before animating — use increasing values to stagger a row.
  final Duration delay;
  final double offsetY;

  /// Starting tilt in degrees around the X axis (top edge leaning away).
  final double rotateX;

  /// Starting scale — below 1 makes the child come up from further back.
  final double fromScale;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 28,
    this.rotateX = 5,
    this.fromScale = 0.94,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  List<ScrollPosition> _positions = const [];
  bool _started = false;
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
      _started = true;
      return;
    }
    // Listen to every enclosing scrollable, not just the nearest: a shrink-wrapped
    // grid is a Scrollable that never scrolls, while the page around it does.
    final positions = <ScrollPosition>[];
    for (var s = Scrollable.maybeOf(context); s != null; s = Scrollable.maybeOf(s.context)) {
      positions.add(s.position);
    }
    _detach();
    _positions = positions;
    for (final p in _positions) {
      p.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _detach() {
    for (final p in _positions) {
      p.removeListener(_check);
    }
    _positions = const [];
  }

  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    // Start once the top edge is a little way into the screen.
    if (top < screen - math.min(80.0, screen * 0.1)) {
      _started = true;
      _detach();
      // A Timer (unlike Future.delayed) can be cancelled if the widget goes away first.
      _delay = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _detach();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final rest = 1 - _curve.value;
        final scale = widget.fromScale + (1 - widget.fromScale) * _curve.value;
        return Opacity(
          opacity: _curve.value,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..translateByDouble(0, rest * widget.offsetY, 0, 1)
              ..rotateX(rest * widget.rotateX * math.pi / 180)
              ..scaleByDouble(scale, scale, 1, 1),
            child: child,
          ),
        );
      },
    );
  }
}

/// Plays a one-off fade + slide when first built (page loads, hero content).
class EntranceFade extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;
  final double fromScale;

  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 22,
    this.fromScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    const run = Duration(milliseconds: 700);
    final total = run + delay;
    // Map the delay onto the start of one tween so no timers are needed.
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offsetY),
          child: fromScale == 1 ? child : Transform.scale(scale: fromScale + (1 - fromScale) * t, child: child),
        ),
      ),
    );
  }
}

/// Gentle endless up-and-down bob, e.g. for a floating badge.
class Floating extends StatefulWidget {
  final Widget child;
  final double distance;

  const Floating({super.key, required this.child, this.distance = 8});

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.distance * Curves.easeInOut.transform(_ctrl.value)),
        child: child,
      ),
    );
  }
}
