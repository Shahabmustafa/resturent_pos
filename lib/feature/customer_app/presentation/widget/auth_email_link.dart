import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../provider/customer_providers.dart';
import '../theme/customer_theme.dart';
import 'auth_dialog.dart';
import 'customer_widgets.dart';

/// Links in auth emails open the website at `?auth=confirm|reset&code=...`
/// (see CustomerAuth._emailLink). Supabase signs the customer in from the code
/// while the app starts; a bad or expired link comes back with `error_description`.
final _authLink = kIsWeb ? Uri.base.queryParameters['auth'] : null;
final _authError = kIsWeb ? _errorDescription(Uri.base) : null;

/// Supabase puts link errors in the query or, for older flows, the fragment.
String? _errorDescription(Uri uri) {
  final fromQuery = uri.queryParameters['error_description'];
  if (fromQuery != null) return fromQuery;
  try {
    return Uri.splitQueryString(uri.fragment)['error_description'];
  } catch (_) {
    return null;
  }
}

/// Shows the result of an email link once, when the site loads: "email
/// confirmed", or a dialog to choose a new password after "Forgot password?".
class AuthEmailLink extends StatefulWidget {
  final Widget child;

  const AuthEmailLink({super.key, required this.child});

  @override
  State<AuthEmailLink> createState() => _AuthEmailLinkState();
}

class _AuthEmailLinkState extends State<AuthEmailLink> {
  // The link stays in the address bar, so don't repeat it on a page refresh.
  static const _handledKey = 'auth_link_handled';

  @override
  void initState() {
    super.initState();
    if (_authLink == null && _authError == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<void> _handle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_handledKey) == Uri.base.toString()) return;
      await prefs.setString(_handledKey, Uri.base.toString());
    } catch (_) {}
    if (!mounted) return;

    if (_authError != null) {
      _snack(
        _authLink == 'reset'
            ? 'This password reset link has expired. Please ask for a new one from the login window.'
            : 'This email link has expired or was already used. Please log in, or register again.',
      );
      showCustomerAuthDialog(context);
      return;
    }

    final session = await _waitForSession();
    if (!mounted) return;

    if (_authLink == 'reset') {
      if (session == null) {
        _snack(
          'This reset link didn\'t work — it may have expired or been opened in a different browser. '
          'Please ask for a new one.',
        );
        showCustomerAuthDialog(context);
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _NewPasswordDialog(),
      );
    } else {
      // The email is confirmed by the time the link opens the site, even when
      // the sign-in itself didn't carry over (e.g. a different browser).
      if (session != null) {
        _snack('Email confirmed — you\'re logged in. Welcome!');
      } else {
        _snack('Email confirmed! Please log in.');
        showCustomerAuthDialog(context);
      }
    }
  }

  /// Signing in from the link's code can finish just after the first frame.
  Future<Session?> _waitForSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return auth.currentSession;
    try {
      final state = await auth.onAuthStateChange
          .firstWhere((s) => s.session != null)
          .timeout(const Duration(seconds: 5));
      return state.session;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(duration: const Duration(seconds: 6), content: Text(message)),
  );

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opened from a password reset link: the customer is signed in by the link
/// and picks a new password.
class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog();

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CustomerAuth.changePassword(_password.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated — you\'re logged in.')),
      );
    } catch (e) {
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Text(
        t,
        style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
      ),
    );
    final eye = IconButton(
      onPressed: () => setState(() => _show = !_show),
      icon: SvgIcon(
        _show ? AppIcons.visibilityOffRounded : AppIcons.visibilityRounded,
        size: 20,
        color: CColors.muted,
      ),
    );

    return Dialog(
      backgroundColor: CColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: IconBadge(
                    AppIcons.lockOutlineRounded,
                    size: 56,
                    background: CColors.cream,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Choose a new password',
                  textAlign: TextAlign.center,
                  style: CText.display(24),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter a new password for your account.',
                  textAlign: TextAlign.center,
                  style: CText.body(14, color: CColors.muted, height: 1.5),
                ),
                label('New password'),
                TextFormField(
                  controller: _password,
                  obscureText: !_show,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'At least 6 characters' : null,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    suffixIcon: eye,
                  ),
                ),
                label('Confirm new password'),
                TextFormField(
                  controller: _confirm,
                  obscureText: !_show,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _save(),
                  validator: (v) =>
                      v != _password.text ? 'Passwords don\'t match' : null,
                  decoration: const InputDecoration(hintText: '••••••'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _error!,
                      style: CText.body(13, color: CColors.rust, height: 1.45),
                    ),
                  ),
                const SizedBox(height: 22),
                PillButton(
                  label: _busy ? 'Please wait…' : 'Save Password',
                  icon: _busy ? null : AppIcons.arrowForwardRounded,
                  expand: true,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
