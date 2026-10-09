import 'package:flutter/material.dart';

/// Sweeps a soft highlight across [child] to signal loading.
///
/// Paint the placeholders inside [child] with [ShimmerBox]; keep card
/// backgrounds and borders *outside* the [Shimmer] so only the placeholders
/// shimmer. Respects the platform "reduce motion" setting.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const Shimmer({super.key, required this.child, this.period = const Duration(milliseconds: 1400)});

  static const baseColor = Color(0xFFEBEDF3);
  static const highlightColor = Color(0xFFF8F9FC);

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (_, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: const Alignment(-1, -0.3),
            end: const Alignment(1, 0.3),
            colors: const [Shimmer.baseColor, Shimmer.highlightColor, Shimmer.baseColor],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(-1 + 2 * _controller.value),
          ).createShader(bounds),
          child: child,
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double slide;
  const _SlideGradient(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Solid placeholder block; only meaningful inside a [Shimmer].
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  const ShimmerBox({super.key, this.width, this.height, this.radius = 6, this.circle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Shimmer.baseColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
