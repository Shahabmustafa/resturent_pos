import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_setting_model.dart';

class BranchSettingsDatasource {
  final SupabaseClient _db;
  const BranchSettingsDatasource(this._db);

  Future<BranchModel> fetch(String branchId) async {
    final res = await _db
        .from('branches')
        .select()
        .eq('id', branchId)
        .single();
    return BranchModel.fromJson(res);
  }

  Future<BranchModel> update(String branchId, Map<String, dynamic> data) async {
    final res = await _db
        .from('branches')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', branchId)
        .select()
        .single();
    return BranchModel.fromJson(res);
  }
}