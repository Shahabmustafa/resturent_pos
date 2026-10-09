import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user_model.dart';

/// Supabase Auth accounts for users can only be created server-side,
/// so create/update/delete go through an Edge Function.
const String kManageBranchUserFn = 'manage-branch-user';

class BranchUserDatasource {
  final SupabaseClient _supabase;
  BranchUserDatasource(this._supabase);

  Future<List<BranchUserModel>> fetchUsers(String branchId) async {
    final res = await _supabase
        .from('branch_users')
        .select()
        .eq('branch_id', branchId)
        .order('created_at');
    return (res as List).map((e) => BranchUserModel.fromJson(e)).toList();
  }

  Future<BranchUserModel> addUser(BranchUserModel user, String branchId) async {
    final res = await _invoke(user.toCreateBody(branchId));
    return BranchUserModel.fromJson(res);
  }

  Future<BranchUserModel> updateUser(BranchUserModel user) async {
    final res = await _invoke(user.toUpdateBody());
    return BranchUserModel.fromJson(res);
  }

  Future<void> toggleStatus(String userId, BranchUserStatus status) async {
    await _supabase
        .from('branch_users')
        .update({'status': status.toJson()})
        .eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    await _invoke({'action': 'delete', 'user_id': userId});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await _supabase.functions.invoke(kManageBranchUserFn, body: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Request failed (${e.status})';
      throw Exception(message);
    }
  }
}
