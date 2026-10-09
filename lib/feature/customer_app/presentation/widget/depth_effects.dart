import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 3D depth effects for the customer website: mouse parallax, card tilt and
/// scroll-linked motion. Every effect sits at its resting pose when idle, so
/// the layout looks exactly as designed until the visitor interacts.
/// Mouse effects only react to a hovering pointer, so touch screens are unaffected.

const _deg = math.pi / 180;

/// Perspective matrix shared by every effect (smaller = flatter).
Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.0011);

/// A 2D value that eases toward a target every frame, so motion stays smooth
/// and returns gently to rest when the pointer leaves.
class _Follower extends ChangeNotifier {
  final double speed;
  late final Ticker _ticker;
  Offset value = Offset.zero;
  Offset _target = Offset.zero;
  Duration _last = Duration.zero;

  _Follower(TickerProvider vsync, {this.speed = 9}) {
    _ticker = vsync.createTicker(_tick);
  }

  set target(Offset t) {
    _target = t;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final k = 1 - math.exp(-speed * dt);
    value = Offset.lerp(value, _target, k)!;
    if ((value - _target).distance < 0.001) {
      value = _target;
      _ticker.stop();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ── Mouse parallax ────────────────────────────────────────────────────────────

/// Tracks the pointer over [child] as a -1..1 offset from its center.
/// [ParallaxLayer]s inside move by that offset scaled by their own depth.
class PointerParallax extends StatefulWidget {
  final Widget child;

  const PointerParallax({super.key, required this.child});

  @override
  State<PointerParallax> createState() => _PointerParallaxState();
}

class _PointerParallaxState extends State<PointerParallax> with SingleTickerProviderStateMixin {
  late final _follower = _Follower(this, speed: 5);

  @override
  void dispose() {
    _follower.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final s = box.size;
    _follower.target = Offset(
      (e.localPosition.dx / s.width * 2 - 1).clamp(-1.0, 1.0),
      (e.localPosition.dy / s.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _follower.target = Offset.zero,
      child: _ParallaxScope(notifier: _follower, child: widget.child),
    );
  }
}

class _ParallaxScope extends InheritedNotifier<_Follower> {
  const _ParallaxScope({required super.notifier, required super.child});

  static _Follower? of(BuildContext context) => context.getInheritedWidgetOfExactType<_ParallaxScope>()?.notifier;
}

/// One depth layer of a [PointerParallax].
/// [depth] is the max shift in px (small = background, large = foreground);
/// [tilt] is the max X/Y rotation in degrees, turning toward the pointer.
/// [builder] can restyle the child (e.g. move its shadow) from the current offset.
class ParallaxLayer extends StatelessWidget {
  final double depth;
  final double tilt;
  final Widget child;
  final Widget Function(BuildContext context, Offset pointer, Widget child)? builder;

  const ParallaxLayer({super.key, required this.depth, this.tilt = 0, required this.child, this.builder});

  @override
  Widget build(BuildContext context) {
    final follower = _ParallaxScope.of(context);
    if (follower == null) return builder == null ? child : builder!(context, Offset.zero, child);
    return ListenableBuilder(
      listenable: follower,
      child: child,
      builder: (context, child) {
        final p = follower.value;
        final m = _perspective()
          ..translateByDouble(p.dx * depth, p.dy * depth, 0, 1)
          ..rotateX(-p.dy * tilt * _deg)
          ..rotateY(p.dx * tilt * _deg);
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: builder == null ? child : builder!(context, p, child!),
        );
      },
    );
  }
}

/// Slow endless float with a gentle sway on both axes — for the hero image.
class FloatSway extends StatefulWidget {
  final Widget child;
  final double distance;
  final double sway; // degrees

  const FloatSway({super.key, required this.child, this.distance = 10, this.sway = 2});

  @override
  State<FloatSway> createState() => _FloatSwayState();
}

class _FloatSwayState extends State<FloatSway> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

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
      builder: (context, child) {
        final a = _ctrl.value * 2 * math.pi;
        // Bob twice per loop; sway on X and Y at different rates so it never looks mechanical.
        final m = _perspective()
          ..translateByDouble(0, -widget.distance * (0.5 - 0.5 * math.cos(a * 2)), 0, 1)
          ..rotateX(math.sin(a) * widget.sway * _deg)
          ..rotateY(math.sin(a * 3 + 1) * widget.sway * 0.7 * _deg);
        return Transform(alignment: Alignment.center, transform: m, child: child);
      },
    );
  }
}

// ── 3D card tilt ──────────────────────────────────────────────────────────────

/// Tilts [child] toward the pointer on hover, scales it up a touch and casts a
/// shadow that falls away from the raised edge. Use [TiltDepth] inside the card
/// to push an element (the image) forward on the Z axis.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final double maxTilt; // degrees
  final BorderRadius borderRadius;

  const Tilt3D({
    super.key,
    required this.child,
    this.maxTilt = 7,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with TickerProviderStateMixin {
  late final _tilt = _Follower(this, speed: 11);
  // dx = hover intensity 0..1 (dy unused) so lift and shadow fade in and out.
  late final _hover = _Follower(this, speed: 9);

  @override
  void dispose() {
    _tilt.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final s = box.size;
    _tilt.target = Offset(
      (e.localPosition.dx / s.width * 2 - 1).clamp(-1.0, 1.0),
      (e.localPosition.dy / s.height * 2 - 1).clamp(-1.0, 1.0),
    );
    _hover.target = const Offset(1, 0);
  }

  void _onExit(PointerExitEvent _) {
    _tilt.target = Offset.zero;
    _hover.target = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final listenable = Listenable.merge([_tilt, _hover]);
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: _TiltScope(
        notifier: _tilt,
        child: ListenableBuilder(
          listenable: listenable,
          child: widget.child,
          builder: (context, child) {
            final p = _tilt.value;
            final h = _hover.value.dx;
            final m = _perspective()
              ..rotateX(-p.dy * widget.maxTilt * _deg)
              ..rotateY(p.dx * widget.maxTilt * _deg)
              ..scaleByDouble(1 + 0.025 * h, 1 + 0.025 * h, 1, 1);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  boxShadow: h < 0.01
                      ? null
                      : [
                          BoxShadow(
                            color: Color.fromRGBO(35, 25, 10, 0.22 * h),
                            blurRadius: 18 + 22 * h,
                            spreadRadius: -4,
                            // The raised side faces the pointer, so the shadow falls the other way.
                            offset: Offset(-p.dx * 14 * h, 10 + 12 * h - p.dy * 8 * h),
                          ),
                        ],
                ),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TiltScope extends InheritedNotifier<_Follower> {
  const _TiltScope({required super.notifier, required super.child});

  static _Follower? of(BuildContext context) => context.getInheritedWidgetOfExactType<_TiltScope>()?.notifier;
}

/// Shifts [child] with the enclosing [Tilt3D] so it reads as sitting closer to
/// the viewer. Keep [depth] within the child's zoom margin when it is clipped.
class TiltDepth extends StatelessWidget {
  final double depth;
  final Widget child;

  const TiltDepth({super.key, this.depth = 6, required this.child});

  @override
  Widget build(BuildContext context) {
    final tilt = _TiltScope.of(context);
    if (tilt == null) return child;
    return ListenableBuilder(
      listenable: tilt,
      child: child,
      builder: (context, child) =>
          Transform.translate(offset: Offset(tilt.value.dx * depth, tilt.value.dy * depth), child: child),
    );
  }
}

// ── Scroll-linked depth ───────────────────────────────────────────────────────

/// Moves [child] with the page scroll for a layered parallax feel.
/// Progress runs from -1 (child centered at the bottom edge of the screen)
/// to 1 (centered at the top edge); 0 means centered on screen, i.e. at rest.
class ScrollDepth extends StatefulWidget {
  final Widget child;
  final double shiftY; // px of vertical drift at the screen edges
  final double rotateX; // degrees of tilt at the screen edges
  final double spin; // degrees of Z rotation at the screen edges

  const ScrollDepth({super.key, required this.child, this.shiftY = 0, this.rotateX = 0, this.spin = 0});

  @override
  State<ScrollDepth> createState() => _ScrollDepthState();
}

class _ScrollDepthState extends State<ScrollDepth> {
  final _progress = ValueNotifier<double>(0);
  List<ScrollPosition> _positions = const [];
  bool _disabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disabled = MediaQuery.disableAnimationsOf(context);
    _detach();
    if (_disabled) return;
    // Listen to every enclosing scrollable — see Reveal for why.
    final positions = <ScrollPosition>[];
    for (var s = Scrollable.maybeOf(context); s != null; s = Scrollable.maybeOf(s.context)) {
      positions.add(s.position);
    }
    _positions = positions;
    for (final p in _positions) {
      p.addListener(_update);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _detach() {
    for (final p in _positions) {
      p.removeListener(_update);
    }
    _positions = const [];
  }

  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final center = box.localToGlobal(box.size.center(Offset.zero)).dy;
    final screen = MediaQuery.sizeOf(context).height;
    _progress.value = ((screen / 2 - center) / (screen / 2)).clamp(-1.0, 1.0);
  }

  @override
  void dispose() {
    _detach();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disabled) return widget.child;
    return ValueListenableBuilder<double>(
      valueListenable: _progress,
      child: widget.child,
      builder: (context, t, child) {
        final m = _perspective()
          ..translateByDouble(0, t * widget.shiftY, 0, 1)
          ..rotateX(t * widget.rotateX * _deg)
          ..rotateZ(t * widget.spin * _deg);
        return Transform(alignment: Alignment.center, transform: m, child: child);
      },
    );
  }
}
