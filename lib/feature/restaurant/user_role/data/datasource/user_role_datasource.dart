import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user_model.dart';

/// Edge Function the admin panel still uses to create a branch's first Supabase Auth admin.
const String kManageBranchUserFn = 'manage-branch-user';

/// Staff accounts live in the `app_users` table. Password hashes never leave
/// the database, so every read and write goes through an RPC.
class BranchUserDatasource {
  final SupabaseClient _supabase;
  BranchUserDatasource(this._supabase);

  Future<List<BranchUserModel>> fetchUsers(String branchId) async {
    final res = await _rpc('app_list_users', {});
    return (res as List)
        .map(
          (e) => BranchUserModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<BranchUserModel> addUser(BranchUserModel user, String branchId) =>
      _save(user, branchId, null);

  Future<BranchUserModel> updateUser(BranchUserModel user) =>
      _save(user, user.branchId, user.id);

  Future<void> toggleStatus(String userId, BranchUserStatus status) => _rpc(
    'app_set_user_status',
    {'p_id': userId, 'p_status': status.toJson()},
  );

  Future<void> deleteUser(String userId) =>
      _rpc('app_delete_user', {'p_id': userId});

  /// An empty password keeps the existing one when updating.
  Future<BranchUserModel> _save(
    BranchUserModel user,
    String branchId,
    String? id,
  ) async {
    final res = await _rpc('app_save_user', {
      'p_id': id,
      'p_name': user.name,
      'p_username': user.username,
      'p_password': user.password,
      'p_role': user.role.toJson(),
      'p_status': user.status.toJson(),
    });
    return BranchUserModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) async {
    try {
      return await _supabase.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
