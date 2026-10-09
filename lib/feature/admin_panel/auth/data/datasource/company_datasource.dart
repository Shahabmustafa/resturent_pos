import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../model/company_model.dart';

const String _kCompanyKey = 'logged_in_company';

class CompanyAuthDatasource {
  final SupabaseClient _supabase;

  CompanyAuthDatasource(this._supabase);

  // ─── Login ───────────────────────────────────────────────────────────────
  Future<CompanyModel> login({
    required String email,
    required String password,
  }) async {
    // Step 1: sign in with Supabase Auth
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      throw Exception('Invalid email or password');
    }

    // Step 2: fetch this account's company
    final company = await _fetchCurrentCompany();
    if (company == null) {
      await _supabase.auth.signOut();
      throw Exception('This account is not linked to an active company');
    }

    // Step 3: save to SharedPreferences
    await _saveToPrefs(company);

    return company;
  }

  // ─── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompanyKey);
  }

  // ─── Get Saved Company (on app start) ────────────────────────────────────
  Future<CompanyModel?> getSavedCompany() async {
    if (_supabase.auth.currentSession == null) return null;

    try {
      final company = await _fetchCurrentCompany();
      if (company != null) await _saveToPrefs(company);
      return company;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kCompanyKey);
      if (jsonString == null) return null;
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return CompanyModel.fromJson(map);
    }
  }

  Future<CompanyModel?> _fetchCurrentCompany() async {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null) return null;

    final row = await _supabase
        .from('companys')
        .select()
        .eq('auth_user_id', authUserId)
        .eq('is_active', true)
        .maybeSingle();

    return row == null ? null : CompanyModel.fromJson(row);
  }

  // ─── Private: Save to SharedPreferences ──────────────────────────────────
  Future<void> _saveToPrefs(CompanyModel company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompanyKey, jsonEncode(company.toJson()));
  }
}
