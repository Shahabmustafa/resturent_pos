import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/customer_providers.dart';
import '../theme/customer_theme.dart';

/// The customer's profile photo, or their initial on a gold circle when there
/// is no photo (or it fails to load).
class CustomerAvatar extends StatelessWidget {
  final User user;
  final double size;

  const CustomerAvatar({super.key, required this.user, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName;
    final initial = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: CColors.goldGradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: CText.body(size * 0.42, color: CColors.ink, weight: FontWeight.w700),
      ),
    );
    if (user.avatarUrl.isEmpty) return initial;
    return ClipOval(
      child: Image.network(
        user.avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initial,
        loadingBuilder: (_, child, progress) => progress == null ? child : initial,
      ),
    );
  }
}
