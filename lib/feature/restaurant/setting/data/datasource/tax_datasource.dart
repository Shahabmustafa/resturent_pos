import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/branch_tax_model.dart';

class TaxDatasource {
  final SupabaseClient _db;
  const TaxDatasource(this._db);

  static const _settings = 'branch_tax_settings';
  static const _slabs    = 'branch_tax_slabs';

  // ── Fetch settings + slabs ─────────────────────────────────────────────────
  Future<BranchTaxSettings> fetch(String branchId) async {
    // Settings
    final settingsRes = await _db
        .from(_settings)
        .select()
        .eq('branch_id', branchId)
        .maybeSingle();

    // Slabs
    final slabsRes = await _db
        .from(_slabs)
        .select()
        .eq('branch_id', branchId)
        .order('sort_order');

    final slabs = (slabsRes as List)
        .map((e) => TaxSlab.fromMap(e))
        .toList();

    if (settingsRes == null) {
      // Insert default settings
      final inserted = await _db
          .from(_settings)
          .insert({'branch_id': branchId})
          .select()
          .single();
      return BranchTaxSettings.fromMap(inserted, slabs: slabs);
    }

    return BranchTaxSettings.fromMap(settingsRes, slabs: slabs);
  }

  // ── Save settings ──────────────────────────────────────────────────────────
  Future<void> saveSettings(BranchTaxSettings settings) async {
    await _db
        .from(_settings)
        .upsert(settings.toMap(), onConflict: 'branch_id');
  }

  // ── Save slabs (delete old, insert new) ───────────────────────────────────
  Future<List<TaxSlab>> saveSlabs(String branchId, List<TaxSlab> slabs) async {
    // Delete the old slabs
    await _db.from(_slabs).delete().eq('branch_id', branchId);

    if (slabs.isEmpty) return [];

    // Insert the new ones
    final inserted = await _db
        .from(_slabs)
        .insert(slabs
            .asMap()
            .entries
            .map((e) => e.value.toInsertMap(branchId, e.key))
            .toList())
        .select();

    return (inserted as List).map((e) => TaxSlab.fromMap(e)).toList();
  }

  // ── FBR connection test ────────────────────────────────────────────────────
  Future<bool> testFbrConnection(String fbrUrl, String fbrToken) async {
    // Placeholder — the actual FBR API call goes here
    await Future.delayed(const Duration(seconds: 1));
    return fbrUrl.isNotEmpty && fbrToken.isNotEmpty;
  }
}
