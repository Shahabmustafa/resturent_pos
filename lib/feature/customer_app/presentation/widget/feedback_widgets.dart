import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/customer_datasource.dart';
import '../provider/customer_providers.dart';
import '../theme/customer_theme.dart';
import 'customer_widgets.dart';

/// Read-only row of 5 stars.
class StarRow extends StatelessWidget {
  final int rating;
  final double size;

  const StarRow({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        SvgIcon(AppIcons.starRounded, size: size, color: i <= rating ? CColors.gold : CColors.line),
    ],
  );
}

/// Asks the customer to rate a completed order. Resolves to true once saved.
Future<bool> showFeedbackDialog(BuildContext context, CustomerOrder order) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: CColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _FeedbackForm(order: order),
      ),
    ),
  );
  return ok ?? false;
}

class _FeedbackForm extends ConsumerStatefulWidget {
  final CustomerOrder order;

  const _FeedbackForm({required this.order});

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _error;

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(customerDatasourceProvider)
          .submitFeedback(orderId: widget.order.id, rating: _rating, comment: _comment.text);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(publicFeedbackProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is PostgrestException ? e.message : 'Couldn\'t send your feedback. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('How was your order?', style: CText.display(26))),
              IconButton(
                tooltip: 'Close',
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                icon: const SvgIcon(AppIcons.closeRounded, size: 22, color: CColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Order ${widget.order.number} — your review appears on our home page.',
            style: CText.body(14, color: CColors.muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  Tooltip(
                    message: _labels[i],
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : () => setState(() => _rating = i),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedScale(
                          duration: Duration.zero,
                          scale: i == _rating ? 1.15 : 1,
                          child: SvgIcon(
                            AppIcons.starRounded,
                            size: 40,
                            color: i <= _rating ? CColors.gold : CColors.line,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _rating == 0 ? 'Tap a star to rate' : _labels[_rating],
              style: CText.body(13.5, color: _rating == 0 ? CColors.mutedLight : CColors.rust, weight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 18),
            child: Text(
              'Tell us more (optional)',
              style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
            ),
          ),
          TextField(
            controller: _comment,
            enabled: !_busy,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'What did you like? What could be better?'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: CText.body(13, color: CColors.rust, height: 1.45)),
            ),
          const SizedBox(height: 16),
          PillButton(
            label: _busy ? 'Please wait…' : 'Submit Feedback',
            expand: true,
            onPressed: _busy || _rating == 0 ? null : _submit,
          ),
        ],
      ),
    );
  }
}
