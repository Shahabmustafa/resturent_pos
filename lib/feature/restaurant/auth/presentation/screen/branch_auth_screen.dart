import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widget/drawer.dart';
import '../provider/branch_auth_provider.dart';

class BranchLoginScreen extends ConsumerStatefulWidget {
  const BranchLoginScreen({super.key});

  @override
  ConsumerState<BranchLoginScreen> createState() => _BranchLoginScreenState();
}

class _BranchLoginScreenState extends ConsumerState<BranchLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email and Password are required'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    await ref.read(branchAuthProvider.notifier).login(
      email: email,
      password: password,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(branchAuthProvider);
    ref.listen<BranchAuthState>(branchAuthProvider, (prev, next) {
      if (next.isLoggedIn) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MainScreen()));
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── Left Panel (Branding) ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.sidebar,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _DotPatternPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const SvgIcon(AppIcons.storefrontRounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'RestoPOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Branch Portal',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sign in to manage your branch\norders, tables, and staff.',
                          style: TextStyle(
                            color: AppColors.sidebarText,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ...[
                          (AppIcons.tableRestaurantOutlined, 'Table Management'),
                          (AppIcons.receiptLongOutlined, 'Order Tracking'),
                          (AppIcons.peopleOutlineRounded, 'Staff Control'),
                        ].map(
                              (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: SvgIcon(item.$1,
                                      color: AppColors.primary, size: 15),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  item.$2,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right Panel (Login Form) ────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.white,
              child: Center(
                child: SizedBox(
                  width: 380,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Branch Login',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in with your branch credentials',
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 13.5),
                        ),
                        const SizedBox(height: 36),

                        const _FieldLabel(label: 'Email'),
                        const SizedBox(height: 6),
                        _LoginField(
                          controller: _emailController,
                          hint: 'you@example.com',
                          icon: AppIcons.alternateEmailRounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        const _FieldLabel(label: 'Password'),
                        const SizedBox(height: 6),
                        _LoginField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: AppIcons.lockOutlineRounded,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('Login',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Expanded(
                                child:
                                Divider(color: AppColors.border, height: 1)),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Branch Portal',
                                  style: const TextStyle(
                                      color: AppColors.textGrey, fontSize: 11)),
                            ),
                            const Expanded(
                                child:
                                Divider(color: AppColors.border, height: 1)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgIcon(AppIcons.infoOutlineRounded,
                                  color: AppColors.primary, size: 16),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your branch credentials are provided by your company administrator.',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12.5,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets (same as before) ─────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600));
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppIcon icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword ? obscure : false,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        prefixIcon: SvgIcon(icon, color: AppColors.textGrey, size: 18),
        suffixIcon: isPassword
            ? IconButton(
          icon: SvgIcon(
              obscure
                  ? AppIcons.visibilityOffOutlined
                  : AppIcons.visibilityOutlined,
              color: AppColors.textGrey,
              size: 18),
          onPressed: onToggleObscure,
        )
            : null,
        filled: true,
        fillColor: AppColors.bg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}