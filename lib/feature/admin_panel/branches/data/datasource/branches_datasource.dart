import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../restaurant/user_role/data/datasource/user_role_datasource.dart'
    show kManageBranchUserFn;
import '../model/branches_model.dart';

class BranchDatasource {
  final SupabaseClient _supabase;

  BranchDatasource(this._supabase);

  Color _colorForIndex(int index) =>
      AppColors.branchColors[index % AppColors.branchColors.length];

  // ─── Fetch all branches + their admin user ──────────────────────────────
  Future<List<Branch>> fetchBranches(String companyId) async {
    final branchRows = await _supabase
        .from('branches')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: true) as List;

    if (branchRows.isEmpty) return [];

    final branchIds = branchRows.map((b) => b['id'] as String).toList();
    final userRows = await _supabase
        .from('branch_users')
        .select()
        .inFilter('branch_id', branchIds)
        .eq('role', 'admin')
        .eq('status', 'active') as List;

    final adminMap = <String, BranchUser>{};
    for (final row in userRows) {
      final user = BranchUser.fromJson(row as Map<String, dynamic>);
      adminMap.putIfAbsent(user.branchId, () => user);
    }

    return branchRows.asMap().entries.map((entry) {
      final json = entry.value as Map<String, dynamic>;
      return Branch.fromJson(
        json,
        color: _colorForIndex(entry.key),
        adminUser: adminMap[json['id'] as String],
      );
    }).toList();
  }

  // ─── Add branch + create admin in branch_users ──────────────────────────
  Future<Branch> addBranch({
    required String companyId,
    required String name,
    required String city,
    required String address,
    required String phone,
    required String ntn,
    required int tables,
    required int colorIndex,
    // Admin credentials (goes to branch_users, NOT branches)
    required String adminName,
    required String adminUsername,
    required String adminEmail,
    required String adminPhone,
    required String adminPassword,
    required String adminRole,
  }) async {
    // 1. Insert branch — only columns that exist in branches table
    final branchRow = await _supabase
        .from('branches')
        .insert({
      'company_id': companyId,
      'name': name,
      'city': city,
      'address': address,
      'phone': phone,
      'ntn': ntn,
      'tables': tables,
      'is_open': true,
      'is_active': true,
    })
        .select()
        .single() as Map<String, dynamic>;

    final branchId = branchRow['id'] as String;

    // 2. Admin's Supabase Auth account + branch_users row (Edge Function)
    final Map<String, dynamic> userRow;
    try {
      userRow = await _invokeUserFn({
        'action': 'create',
        'branch_id': branchId,
        'email': adminEmail,
        'password': adminPassword,
        'name': adminName,
        'username': adminUsername,
        'phone': adminPhone,
        'role': adminRole,
        'status': 'active',
      });
    } catch (_) {
      // If the admin couldn't be created, don't leave a half-made branch
      await _supabase.from('branches').delete().eq('id', branchId);
      rethrow;
    }

    return Branch.fromJson(
      branchRow,
      color: _colorForIndex(colorIndex),
      adminUser: BranchUser.fromJson(userRow),
    );
  }

  // ─── Update branch + optionally update admin user ───────────────────────
  Future<Branch> updateBranch({
    required String branchId,
    required String name,
    required String city,
    required String address,
    required String phone,
    required String ntn,
    required int tables,
    required bool isOpen,
    required Color color,
    // Admin user updates (branch_users table)
    String? adminUserId,
    String? adminName,
    String? adminUsername,
    String? adminEmail,
    String? adminPhone,
    String? adminRole,
    String? newPassword,
  }) async {
    // 1. Update branch — only columns that exist in branches table
    final branchRow = await _supabase
        .from('branches')
        .update({
      'name': name,
      'city': city,
      'address': address,
      'phone': phone,
      'ntn': ntn,
      'tables': tables,
      'is_open': isOpen,
    })
        .eq('id', branchId)
        .select()
        .single() as Map<String, dynamic>;

    // 2. Update admin user in branch_users (if provided)
    BranchUser? adminUser;
    if (adminUserId != null) {
      final userData = <String, dynamic>{};
      if (adminName != null) userData['name'] = adminName;
      if (adminUsername != null) userData['username'] = adminUsername;
      if (adminEmail != null && adminEmail.isNotEmpty) userData['email'] = adminEmail;
      if (adminPhone != null) userData['phone'] = adminPhone;
      if (adminRole != null) userData['role'] = adminRole;
      if (newPassword != null && newPassword.isNotEmpty) {
        userData['password'] = newPassword;
      }
      if (userData.isNotEmpty) {
        final userRow = await _invokeUserFn({
          'action': 'update',
          'user_id': adminUserId,
          ...userData,
        });
        adminUser = BranchUser.fromJson(userRow);
      }
    }

    return Branch.fromJson(branchRow, color: color, adminUser: adminUser);
  }

  Future<Map<String, dynamic>> _invokeUserFn(Map<String, dynamic> body) async {
    try {
      final res = await _supabase.functions.invoke(kManageBranchUserFn, body: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      throw Exception(details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Request failed (${e.status})');
    }
  }

  // ─── Toggle open/close ───────────────────────────────────────────────────
  Future<void> toggleBranchStatus(String branchId, bool isOpen) async {
    await _supabase
        .from('branches')
        .update({'is_open': isOpen}).eq('id', branchId);
  }

  // ─── Delete branch ───────────────────────────────────────────────────────
  Future<void> deleteBranch(String branchId) async {
    await _supabase.from('branches').delete().eq('id', branchId);
  }

  // ─── Fetch all users of a branch ────────────────────────────────────────
  Future<List<BranchUser>> fetchBranchUsers(String branchId) async {
    final rows = await _supabase
        .from('branch_users')
        .select()
        .eq('branch_id', branchId)
        .order('created_at', ascending: true) as List;
    return rows
        .map((r) => BranchUser.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}