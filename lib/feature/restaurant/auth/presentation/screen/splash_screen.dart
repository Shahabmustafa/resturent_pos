import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_info.dart';
import 'package:resturent_application/core/constants/supabase_config.dart';
import 'package:resturent_application/core/desktop_window.dart';
import 'branch_auth_screen.dart';

/// Shown in the small splash window while the POS starts up, then opens
/// the full-size window on the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minDuration = Duration(milliseconds: 2500);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _minDuration,
  )..forward();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.wait([SupabaseConfig.init(), Future.delayed(_minDuration)]);
    await showMainWindow();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BranchLoginScreen()),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SplashCard(progress: _progress));
}

/// Flat orange and bright blue footer, matching the reference splash design.
const _splashOrange = Color(0xFFFF5A00);
const _splashBlue = Color(0xFF2E9DFF);

/// The orange brand card that fills the splash window.
class SplashCard extends StatelessWidget {
  const SplashCard({super.key, required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(color: _splashOrange),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PakAfghan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'RESTAURANT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: _splashBlue,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.value,
                      minHeight: 4,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'v $kAppVersion',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
