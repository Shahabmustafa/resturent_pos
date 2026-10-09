import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/branch_setting_datsource.dart';
import '../../data/datasource/receipt_settings_datasource.dart';
import '../../data/model/branch_setting_model.dart';
import '../../data/model/receipt_settings_model.dart';


// ── State ────────────────────────────────────────────────────────────────────

class ReceiptSettingsState {
  final ReceiptSettings? settings;
  final bool loading;
  final bool saving;
  final String? error;

  const ReceiptSettingsState({
    this.settings,
    this.loading = true,
    this.saving = false,
    this.error,
  });

  ReceiptSettingsState copyWith({
    ReceiptSettings? settings,
    bool? loading,
    bool? saving,
    String? error,
  }) =>
      ReceiptSettingsState(
        settings: settings ?? this.settings,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ReceiptSettingsNotifier extends StateNotifier<ReceiptSettingsState> {
  final ReceiptSettingsDataSource _ds;
  final String _branchId;

  ReceiptSettingsNotifier(this._ds, this._branchId)
      : super(const ReceiptSettingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final s = await _ds.fetch(_branchId);
      state = state.copyWith(settings: s, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void update(ReceiptSettings updated) =>
      state = state.copyWith(settings: updated);

  Future<bool> save() async {
    final s = state.settings;
    if (s == null) return false;
    state = state.copyWith(saving: true, error: null);
    try {
      await _ds.upsert(s);
      state = state.copyWith(saving: false);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  Future<String?> uploadLogo(File file) async {
    final s = state.settings;
    if (s == null) return null;
    state = state.copyWith(saving: true, error: null);
    try {
      final url = await _ds.uploadLogo(s.branchId, file);
      final updated = s.copyWith(logoUrl: url);
      await _ds.upsert(updated);
      state = state.copyWith(settings: updated, saving: false);
      return url;
    } catch (e) {
      print('Logo upload error: $e');
      state = state.copyWith(saving: false, error: e.toString());
      return null;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _receiptDsProvider = Provider(
      (ref) => ReceiptSettingsDataSource(Supabase.instance.client),
);

final _branchSettingsDsProvider = Provider(
      (ref) => BranchSettingsDatasource(Supabase.instance.client),
);

final receiptSettingsProvider =
StateNotifierProvider<ReceiptSettingsNotifier, ReceiptSettingsState>((ref) {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  return ReceiptSettingsNotifier(
    ref.read(_receiptDsProvider),
    branchId,
  );
});

// ── Branch info provider (restaurant_name, address, phone) ───────────────────

final receiptBranchProvider = FutureProvider<BranchModel?>((ref) async {
  final branchId = ref.watch(branchAuthProvider).branch?.branchId ?? '';
  if (branchId.isEmpty) return null;
  final ds = ref.read(_branchSettingsDsProvider);
  return ds.fetch(branchId);
});