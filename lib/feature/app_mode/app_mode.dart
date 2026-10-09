import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Which app the phone build shows: the customer website UI or the Rider app.
enum AppMode { customer, rider }

/// Remembers the choice made on the first screen so it's only asked once.
/// Customers and riders share one Supabase session on the phone, so every
/// switch makes sure the signed-in account matches the chosen side.
class AppModeController {
  AppModeController._();

  static const _key = 'app_mode';

  /// null = not chosen yet (show the chooser).
  static final mode = ValueNotifier<AppMode?>(null);

  static Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      mode.value = AppMode.values.where((m) => m.name == saved).firstOrNull;
    } catch (_) {
      mode.value = null;
    }
  }

  static Future<void> choose(AppMode m) async {
    // Keep a session only if it belongs to this side; otherwise start signed out.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !_belongsTo(user, m)) await Supabase.instance.client.auth.signOut();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, m.name);
    } catch (_) {}
    mode.value = m;
  }

  /// Back to the chooser, signed out.
  static Future<void> reset() async {
    await Supabase.instance.client.auth.signOut();
    try {
      await (await SharedPreferences.getInstance()).remove(_key);
    } catch (_) {}
    mode.value = null;
  }

  static bool _belongsTo(User user, AppMode m) => switch (m) {
    // Rider logins are <phone>@rider.pos (see manage-rider-login).
    AppMode.rider => (user.email ?? '').endsWith('@rider.pos'),
    AppMode.customer => user.userMetadata?['account_type'] == 'customer',
  };
}
