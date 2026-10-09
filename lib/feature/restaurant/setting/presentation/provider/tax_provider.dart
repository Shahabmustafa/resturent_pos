import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/tax_datasource.dart';
import '../../data/model/branch_tax_model.dart';

// ── Datasource provider ───────────────────────────────────────────────────────
final _taxDsProvider = Provider<TaxDatasource>(
  (_) => TaxDatasource(Supabase.instance.client),
);

// ── State ─────────────────────────────────────────────────────────────────────
class TaxState {
  final BranchTaxSettings? settings;
  final bool    loading;
  final bool    saving;
  final bool    testingFbr;
  final bool?   fbrTestResult;  // null=untested, true=ok, false=fail
  final String? error;
  final bool    saved;

  const TaxState({
    this.settings,
    this.loading      = true,
    this.saving       = false,
    this.testingFbr   = false,
    this.fbrTestResult,
    this.error,
    this.saved        = false,
  });

  TaxState copyWith({
    BranchTaxSettings? settings,
    bool?   loading,
    bool?   saving,
    bool?   testingFbr,
    bool?   fbrTestResult,
    bool    clearFbrResult = false,
    String? error,
    bool    clearError     = false,
    bool?   saved,
  }) => TaxState(
    settings:      settings      ?? this.settings,
    loading:       loading       ?? this.loading,
    saving:        saving        ?? this.saving,
    testingFbr:    testingFbr    ?? this.testingFbr,
    fbrTestResult: clearFbrResult ? null : fbrTestResult ?? this.fbrTestResult,
    error:         clearError ? null : error ?? this.error,
    saved:         saved         ?? false,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class TaxNotifier extends StateNotifier<TaxState> {
  final TaxDatasource _ds;
  final String        _branchId;

  TaxNotifier(this._ds, this._branchId) : super(const TaxState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final s = await _ds.fetch(_branchId);
      state = state.copyWith(settings: s, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void update(BranchTaxSettings updated) =>
      state = state.copyWith(settings: updated);

  // ── Slab mutations ────────────────────────────────────────────────────────
  void addSlab() {
    final s = state.settings;
    if (s == null) return;
    final newSlab = TaxSlab(branchId: _branchId, name: '', rate: 0, isActive: false);
    state = state.copyWith(settings: s.copyWith(slabs: [...s.slabs, newSlab]));
  }

  void removeSlab(int index) {
    final s = state.settings;
    if (s == null) return;
    final slabs = [...s.slabs]..removeAt(index);
    state = state.copyWith(settings: s.copyWith(slabs: slabs));
  }

  void updateSlab(int index, TaxSlab updated) {
    final s = state.settings;
    if (s == null) return;
    final slabs = [...s.slabs];
    slabs[index] = updated;
    state = state.copyWith(settings: s.copyWith(slabs: slabs));
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    final s = state.settings;
    if (s == null) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _ds.saveSettings(s);
      final updatedSlabs = await _ds.saveSlabs(_branchId, s.slabs);
      final updated = s.copyWith(slabs: updatedSlabs);
      state = state.copyWith(saving: false, settings: updated, saved: true);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  // ── FBR Test ──────────────────────────────────────────────────────────────
  Future<void> testFbr() async {
    final s = state.settings;
    if (s == null) return;
    state = state.copyWith(testingFbr: true, clearFbrResult: true);
    try {
      final ok = await _ds.testFbrConnection(s.fbrUrl, s.fbrToken);
      state = state.copyWith(testingFbr: false, fbrTestResult: ok);
    } catch (_) {
      state = state.copyWith(testingFbr: false, fbrTestResult: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final taxProvider = StateNotifierProvider<TaxNotifier, TaxState>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  return TaxNotifier(ref.read(_taxDsProvider), branchId);
});

// ── Simple FutureProvider — fetches the tax rate for the POS ─────────────────
// watched by posProvider
final taxRateProvider = FutureProvider<double>((ref) async {
  final state = ref.watch(taxProvider);
  if (!state.loading && state.settings != null) {
    if (!state.settings!.enableTax) return 0.0;
    return state.settings!.activeTaxRate;
  }
  return 5.0; // default fallback
});
