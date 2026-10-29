/// Hidden Supabase account the POS app signs in with on this device so the
/// database security rules and branch functions keep working. Staff never see
/// it: they log in with a username and password from the `app_users` table.
class DeviceAccount {
  DeviceAccount._();

  static const email = 'rkhan4t9@gmail.com';
  static const password = 'd52f92108dc00932425b77db';
}
