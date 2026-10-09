import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/constants/supabase_config.dart';
import 'package:resturent_application/feature/customer_app/customer_app.dart';

/// Runs the customer website on any platform (handy for previewing on desktop):
/// flutter run -t lib/main_customer.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: CustomerApp()));
}
