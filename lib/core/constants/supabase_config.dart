import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared by the desktop POS and the customer website.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = 'https://nfreystcexoniutcbmwe.supabase.co';
  static const anonKey = 'sb_publishable_3bhQZhezwmOANw0QX1c8oQ_XsU0WYsT';

  static Future<void> init() => Supabase.initialize(url: url, anonKey: anonKey);
}
