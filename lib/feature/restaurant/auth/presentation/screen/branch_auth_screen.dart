import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:resturent_application/core/constants/app_info.dart';
import 'package:resturent_application/core/desktop_window.dart';
import '../../../../../core/widget/drawer.dart';
import '../provider/branch_auth_provider.dart';

const _bg = Color(0xFFD4D4D2);
const _header = Color(0xFF2A75E6);
const _panel = Color(0xFFEBEBEB);
const _key = Color(0xFF5BC0DE);
const _green = Color(0xFF5CB85C);
const _orange = Color(0xFFF0AD4E);
const _clock = Color(0xFF006064);
const _red = Color(0xFFB91C1C);

/// Staff sign in: username and password, with an on-screen keypad for touch tills.
class BranchLoginScreen extends ConsumerStatefulWidget {
  const BranchLoginScreen({super.key});

  @override
  ConsumerState<BranchLoginScreen> createState() => _BranchLoginScreenState();
}

class _BranchLoginScreenState extends ConsumerState<BranchLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  // The keypad types into whichever field was focused last.
  late TextEditingController _target = _usernameController;
  bool _stay = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() {
      if (_usernameFocus.hasFocus) _target = _usernameController;
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) _target = _passwordController;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _digit(String d) => _target.text += d;

  void _clear() => _target.clear();

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showError('Username and Password are required');
      return;
    }
    await ref
        .read(branchAuthProvider.notifier)
        .login(username: username, password: password, stay: _stay);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(branchAuthProvider.select((s) => s.isLoading));
    ref.listen<BranchAuthState>(branchAuthProvider, (prev, next) {
      if (next.isLoggedIn) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
      }
      if (next.errorMessage != null) _showError(next.errorMessage!);
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            height: 76,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: _header,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/branding/app_icon.svg',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 14),
                const Text(
                  kAppName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SingleChildScrollView(
                      child: Container(
                        width: 340,
                        color: _panel,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Login details',
                              style: TextStyle(
                                color: Color(0xFF2A6496),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Field(
                              controller: _usernameController,
                              focusNode: _usernameFocus,
                              hint: 'Username',
                              icon: Icons.person,
                              autofocus: true,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 10),
                            _Field(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hint: 'Password',
                              icon: Icons.password_rounded,
                              obscure: true,
                              onSubmitted: (_) => loading ? null : _login(),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _Key(
                                width: 62,
                                height: 56,
                                color: _green,
                                onTap: loading ? null : _login,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.login_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          Text(
                                            'Login',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: 30,
                              height: 28,
                              color: _orange,
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 22),
                            for (final row in const [
                              ['1', '2', '3'],
                              ['4', '5', '6'],
                              ['7', '8', '9'],
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [for (final d in row) _digitKey(d)],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Key(
                                  width: 62,
                                  height: 52,
                                  color: Colors.white,
                                  onTap: _clear,
                                  child: const Text(
                                    'C',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _digitKey('0'),
                                _Key(
                                  width: 62,
                                  height: 52,
                                  color: _green,
                                  onTap: loading ? null : _login,
                                  child: const Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Checkbox(
                                    value: _stay,
                                    onChanged: (v) =>
                                        setState(() => _stay = v ?? false),
                                    side: const BorderSide(
                                      color: Colors.black45,
                                    ),
                                    fillColor: WidgetStateProperty.resolveWith(
                                      (s) => s.contains(WidgetState.selected)
                                          ? _header
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Stay signed in',
                                  style: TextStyle(
                                    color: Color(0xFF1B7F8C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ClockBox(),
                        const SizedBox(width: 8),
                        _Key(
                          width: 56,
                          height: 44,
                          color: Colors.white,
                          onTap: closeApp,
                          child: const Icon(
                            Icons.power_settings_new_rounded,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _digitKey(String d) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: _Key(
      width: 62,
      height: 52,
      color: _key,
      onTap: () => _digit(d),
      child: Text(
        d,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

/// Flat coloured button with a hard bottom-right shadow, like the till keypad.
class _Key extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final VoidCallback? onTap;
  final Widget child;

  const _Key({
    required this.width,
    required this.height,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(2),
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, offset: Offset(2, 2)),
        ],
      ),
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: double.infinity,
            color: const Color(0xFFEEEEEE),
            child: Icon(icon, size: 18, color: Colors.black87),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              obscureText: obscure,
              onSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Day and time box in the bottom-left corner.
class _ClockBox extends StatefulWidget {
  const _ClockBox();

  @override
  State<_ClockBox> createState() => _ClockBoxState();
}

class _ClockBoxState extends State<_ClockBox> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _clock,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('EEE dd.MM.yy').format(now),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            DateFormat('h:mm a').format(now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
