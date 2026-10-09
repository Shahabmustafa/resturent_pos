import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/branch_setting_datsource.dart';
import '../../data/model/branch_setting_model.dart';

// ── Datasource ────────────────────────────────────────────────────────────────
final _dsProvider = Provider<BranchSettingsDatasource>(
      (ref) => BranchSettingsDatasource(Supabase.instance.client),
);

// ── State ─────────────────────────────────────────────────────────────────────
class BranchSettingsState {
  final BranchModel? branch;
  final bool loading;
  final bool saving;
  final String? error;
  final bool saved;

  const BranchSettingsState({
    this.branch,
    this.loading = false,
    this.saving  = false,
    this.error,
    this.saved   = false,
  });

  BranchSettingsState copyWith({
    BranchModel? branch,
    bool? loading,
    bool? saving,
    String? error,
    bool? saved,
  }) => BranchSettingsState(
    branch:  branch  ?? this.branch,
    loading: loading ?? this.loading,
    saving:  saving  ?? this.saving,
    error:   error,
    saved:   saved   ?? false,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class BranchSettingsNotifier extends StateNotifier<BranchSettingsState> {
  final BranchSettingsDatasource _ds;
  final String _branchId;

  BranchSettingsNotifier(this._ds, this._branchId)
      : super(const BranchSettingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final branch = await _ds.fetch(_branchId);
      state = state.copyWith(loading: false, branch: branch);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> save(BranchModel updated) async {
    state = state.copyWith(saving: true);
    try {
      final saved = await _ds.update(_branchId, updated.toJson());
      state = state.copyWith(saving: false, branch: saved, saved: true);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final branchSettingsProvider =
StateNotifierProvider<BranchSettingsNotifier, BranchSettingsState>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  return BranchSettingsNotifier(ref.read(_dsProvider), branchId);
});
