import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../model/branch_auth_model.dart';

const String _kBranchUserKey = 'logged_in_branch_user';

class BranchAuthDatasource {
  final SupabaseClient _supabase;

  BranchAuthDatasource(this._supabase);

  Future<BranchAuthModel> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      throw Exception('Invalid email or password');
    }

    final user = await _fetchCurrentUser();
    if (user == null) {
      await _supabase.auth.signOut();
      throw Exception('This account is not linked to a branch or is inactive');
    }

    await _saveToPrefs(user);
    return user;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBranchUserKey);
  }

  /// On app start: restore the user if a Supabase session exists.
  /// Falls back to the cached user when offline.
  Future<BranchAuthModel?> getSavedBranch() async {
    if (_supabase.auth.currentSession == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBranchUserKey);
      return null;
    }

    try {
      final user = await _fetchCurrentUser();
      if (user == null) {
        await logout();
        return null;
      }
      await _saveToPrefs(user);
      return user;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kBranchUserKey);
      if (jsonString == null) return null;
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return BranchAuthModel.fromJson(map);
    }
  }

  Future<BranchAuthModel?> _fetchCurrentUser() async {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null) return null;

    final response = await _supabase
        .from('branch_users')
        .select()
        .eq('auth_user_id', authUserId)
        .eq('status', 'active')
        .maybeSingle();

    return response == null ? null : BranchAuthModel.fromJson(response);
  }

  Future<void> _saveToPrefs(BranchAuthModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBranchUserKey, jsonEncode(user.toJson()));
  }
}
