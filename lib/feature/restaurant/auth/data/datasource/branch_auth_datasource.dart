import 'package:resturent_application/core/constants/device_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../model/branch_auth_model.dart';

const String _kBranchUserKey = 'logged_in_branch_user';
const String _kStaySignedInKey = 'stay_signed_in';

class BranchAuthDatasource {
  final SupabaseClient _supabase;

  BranchAuthDatasource(this._supabase);

  /// Keeps the hidden device account signed in; staff never see this step.
  Future<void> _ensureDeviceSession() async {
    if (_supabase.auth.currentSession != null) return;
    try {
      await _supabase.auth.signInWithPassword(
        email: DeviceAccount.email,
        password: DeviceAccount.password,
      );
    } on AuthException {
      throw Exception('Could not connect to the server');
    }
  }

  Future<BranchAuthModel> login({
    required String username,
    required String password,
    required bool stay,
  }) async {
    await _ensureDeviceSession();
    try {
      final res = await _supabase.rpc(
        'app_login',
        params: {'p_username': username, 'p_password': password},
      );
      if (res == null) throw Exception('Invalid username or password');
      final user = BranchAuthModel.fromJson(
        Map<String, dynamic>.from(res as Map),
      );
      await _saveToPrefs(user);
      await (await SharedPreferences.getInstance()).setBool(
        _kStaySignedInKey,
        stay,
      );
      return user;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBranchUserKey);
  }

  /// On app start: reconnect the device account and restore the last user.
  Future<BranchAuthModel?> getSavedBranch() async {
    try {
      await _ensureDeviceSession();
    } catch (_) {
      // Offline: the cached user below is still enough to open the till.
    }
    final prefs = await SharedPreferences.getInstance();
    // Without "Stay signed in" the next start asks for the login again.
    if (prefs.getBool(_kStaySignedInKey) != true) return null;
    final jsonString = prefs.getString(_kBranchUserKey);
    if (jsonString == null) return null;
    return BranchAuthModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  Future<void> _saveToPrefs(BranchAuthModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBranchUserKey, jsonEncode(user.toJson()));
  }
}
