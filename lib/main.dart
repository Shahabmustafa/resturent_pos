import 'package:resturent_application/core/widget/old_dialog_theme.dart';
import 'package:resturent_application/core/constants/app_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/supabase_config.dart';
import 'package:resturent_application/core/desktop_window.dart';
import 'package:resturent_application/feature/admin_panel/admin_panel_app.dart';
import 'package:resturent_application/feature/customer_app/customer_app.dart';
import 'package:resturent_application/feature/app_mode/app_mode.dart';
import 'package:resturent_application/feature/app_mode/mobile_app.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web build = customer website (or the owner's admin panel at /admin-panel);
  // phone build = customer or Rider app (asked once); desktop build = POS.
  final isDesktop =
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS;
  if (isDesktop) {
    // The splash screen connects to Supabase while its small window is showing.
    await showSplashWindow();
    runApp(const ProviderScope(child: RestaurantPOSApp()));
    return;
  }

  // The website also reads the menu from and writes orders to Supabase.
  await SupabaseConfig.init();

  if (kIsWeb && isAdminPanelUrl(Uri.base)) {
    runApp(const ProviderScope(child: AdminPanelApp()));
    return;
  }
  if (kIsWeb) {
    runApp(const ProviderScope(child: CustomerApp()));
    return;
  }
  await AppModeController.load();
  runApp(const ProviderScope(child: MobileApp()));
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB91C1C),
          secondary: Color(0xFFDC2626),
          surface: Color(0xFFFFFFFF),
        ),
        fontFamily: 'Roboto',
        dialogTheme: kOldStyleDialogTheme,
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}

// Pehla login Khan / lf9HIzitra se karein.
