import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../provider/customer_providers.dart';
import '../theme/customer_theme.dart';
import 'customer_widgets.dart';

/// Login / register dialog. Resolves to true once the customer is signed in.
Future<bool> showCustomerAuthDialog(BuildContext context, {String? reason}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: CColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _AuthForm(reason: reason),
      ),
    ),
  );
  return ok ?? false;
}

class _AuthForm extends StatefulWidget {
  final String? reason;

  const _AuthForm({this.reason});

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_register) {
        final result = await CustomerAuth.signUp(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
        );
        if (result == SignUpResult.confirmEmail) {
          setState(() {
            _register = false;
            _info =
                'Account created! We sent a confirmation email to ${_email.text.trim()} — '
                'click the link in it, then log in here.';
          });
          return;
        }
      } else {
        await CustomerAuth.signIn(_email.text, _password.text);
      }
      if (mounted) Navigator.pop(context, true);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(_register ? 'Create your account' : 'Welcome back', style: CText.display(26))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
                  icon: const SvgIcon(AppIcons.closeRounded, size: 22, color: CColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.reason ?? (_register ? 'Create an account to place your order.' : 'Log in to place your order.'),
              style: CText.body(14, color: CColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            _ModeSwitch(
              register: _register,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _register = v;
                      _error = null;
                      _info = null;
                    }),
            ),
            if (_register) ...[
              label('Full name'),
              TextFormField(
                controller: _name,
                validator: _required,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              label('Phone'),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter a valid phone number' : null,
                decoration: const InputDecoration(hintText: '03xx xxxxxxx'),
              ),
            ],
            label('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
            label('Password'),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
              decoration: InputDecoration(
                hintText: '••••••',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: SvgIcon(
                    _showPassword ? AppIcons.visibilityOffRounded : AppIcons.visibilityRounded,
                    size: 20,
                    color: CColors.muted,
                  ),
                ),
              ),
            ),
            if (_error != null) _Notice(_error!, error: true),
            if (_info != null) _Notice(_info!),
            const SizedBox(height: 22),
            PillButton(
              label: _busy ? 'Please wait…' : (_register ? 'Create Account' : 'Login'),
              icon: _busy ? null : AppIcons.arrowForwardRounded,
              expand: true,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool register;
  final ValueChanged<bool>? onChanged;

  const _ModeSwitch({required this.register, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) {
      final active = register == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onChanged == null ? null : () => onChanged!(value),
          child: AnimatedContainer(
            duration: Duration.zero,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? CColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: CText.body(13.5, color: active ? Colors.white : CColors.muted, weight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CColors.cream,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: CColors.line),
      ),
      child: Row(children: [tab('Login', false), tab('Register', true)]),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final bool error;

  const _Notice(this.text, {this.error = false});

  @override
  Widget build(BuildContext context) {
    final color = error ? CColors.rust : CColors.olive;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgIcon(error ? AppIcons.warningRounded : AppIcons.checkCircleRounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: CText.body(13, color: color, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
