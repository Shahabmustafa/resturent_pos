import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/supabase_config.dart';
import 'package:resturent_application/feature/customer_app/customer_app.dart';
import 'package:resturent_application/feature/app_mode/app_mode.dart';
import 'package:resturent_application/feature/app_mode/mobile_app.dart';
import 'package:resturent_application/feature/restaurant/auth/presentation/screen/branch_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The website also reads the menu from and writes orders to Supabase.
  await SupabaseConfig.init();

  // Web build = customer website; phone build = customer or Rider app (asked once); desktop build = POS.
  if (kIsWeb) {
    runApp(const ProviderScope(child: CustomerApp()));
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    await AppModeController.load();
    runApp(const ProviderScope(child: MobileApp()));
    return;
  }

  runApp(ProviderScope(child: const RestaurantPOSApp()));
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS',
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
        useMaterial3: true,
      ),

      home: BranchLoginScreen(),
    );
  }
}
