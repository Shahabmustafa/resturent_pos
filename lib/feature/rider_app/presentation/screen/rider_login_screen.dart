import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../app_mode/app_mode.dart';
import '../../rider_app.dart';

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _hidePass = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter your phone number and password');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the auth gate swaps to the home screen.
      await ref.read(riderDsProvider).signIn(_phone.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, AppIcon icon, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kMuted, fontSize: 15),
    prefixIcon: Padding(
      padding: const EdgeInsets.all(14),
      child: SvgIcon(icon, size: 20, color: kSub),
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: kLight,
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPrimary,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                // IntrinsicHeight lets the white sheet stretch to the bottom on tall phones.
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Brand header ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: const SvgIcon(AppIcons.deliveryDiningRounded, size: 42, color: Colors.white),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Rider App',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to see your deliveries',
                              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),

                      // ── Form sheet ──
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          decoration: const BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          // AutofillGroup lets password managers fill and save phone + password together.
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Phone number',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kSub),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  style: const TextStyle(fontSize: 16, color: kText, fontWeight: FontWeight.w600),
                                  decoration: _dec('0300 1234567', AppIcons.phoneRounded),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Password',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kSub),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pass,
                                  obscureText: _hidePass,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _submit(),
                                  style: const TextStyle(fontSize: 16, color: kText, fontWeight: FontWeight.w600),
                                  decoration: _dec(
                                    'Your password',
                                    AppIcons.lockOutlineRounded,
                                    suffix: IconButton(
                                      onPressed: () => setState(() => _hidePass = !_hidePass),
                                      icon: SvgIcon(
                                        _hidePass ? AppIcons.visibilityRounded : AppIcons.visibilityOffRounded,
                                        size: 20,
                                        color: kMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kRed.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const SvgIcon(AppIcons.errorOutlineRounded, size: 18, color: kRed),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: kRed,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 26),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _busy ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: kPrimary.withValues(alpha: 0.6),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _busy
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'No password yet? Ask the restaurant manager to set one for you in the POS.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.5),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: AppModeController.reset,
                                  icon: const SvgIcon(AppIcons.arrowBackRounded, size: 18, color: kSub),
                                  label: const Text(
                                    'Not a rider? Order food instead',
                                    style: TextStyle(fontSize: 13.5, color: kSub, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
