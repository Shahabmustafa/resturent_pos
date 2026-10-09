import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../delivery/data/model/delivery_model.dart';
import '../../rider_app.dart';
import '../provider/rider_provider.dart';
import 'package:resturent_application/core/constants/currency.dart';

/// Rider actions shared by the deliveries list and the delivery detail screen.

void riderToast(BuildContext context, String msg, Color color) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

Future<void> startTrip(BuildContext context, WidgetRef ref, DeliveryOrder o) async {
  final error = await ref.read(riderProvider.notifier).startTrip(o.id);
  if (!context.mounted) return;
  if (error == null) HapticFeedback.mediumImpact();
  riderToast(context, error ?? 'Trip started — drive safe!', error == null ? kGreen : kRed);
}

Future<void> markDelivered(BuildContext context, WidgetRef ref, DeliveryOrder o) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DeliveredSheet(order: o),
  );
  if (ok != true || !context.mounted) return;
  final error = await ref.read(riderProvider.notifier).markDelivered(o.id);
  if (!context.mounted) return;
  if (error == null) HapticFeedback.mediumImpact();
  riderToast(context, error ?? 'Delivered! Great job.', error == null ? kGreen : kRed);
}

Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You will stop seeing new deliveries until you sign in again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
      ],
    ),
  );
  if (ok == true) await ref.read(riderDsProvider).signOut();
}

/// Confirms the hand-over and reminds the rider how much cash to collect.
class DeliveredSheet extends StatelessWidget {
  final DeliveryOrder order;
  const DeliveredSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mark as delivered?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText),
            ),
            const SizedBox(height: 6),
            Text('${order.orderNum} • ${order.customerName}', style: const TextStyle(fontSize: 14, color: kSub)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SvgIcon(AppIcons.paymentsRounded, size: 26, color: kGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collect from customer', style: TextStyle(fontSize: 12.5, color: kSub)),
                        Text(
                          formatMoney(order.amount),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Yes, delivered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Not yet',
                style: TextStyle(color: kSub, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
