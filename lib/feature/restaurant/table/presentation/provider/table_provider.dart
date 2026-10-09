import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/table_datasource.dart';
import '../../data/model/table_model.dart';

// ── Datasource provider ────────────────────────────────────────────────────
final tableDatasourceProvider = Provider<TableDatasource>((ref) {
  return TableDatasource(Supabase.instance.client);
});

final tablesRefreshProvider = StateProvider<int>((ref) => 0);


// ── State ──────────────────────────────────────────────────────────────────
class TableState {
  final List<TableModel> tables;
  final bool isLoading;
  final String? errorMessage;

  const TableState({
    this.tables = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TableState copyWith({
    List<TableModel>? tables,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TableState(
      tables:       tables       ?? this.tables,
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────
class TableNotifier extends StateNotifier<TableState> {
  final TableDatasource _datasource;
  final String _branchId;
  final Ref _ref; // 👈 added

  TableNotifier(this._datasource, this._branchId, this._ref) : super(const TableState()) {
    fetchTables();
  }

  Future<void> fetchTables() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tables = await _datasource.fetchTables(_branchId);
      state = state.copyWith(tables: tables, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> addTable(TableModel table) async {
    try {
      final added = await _datasource.addTable(table, _branchId);
      state = state.copyWith(tables: [...state.tables, added]);
      _ref.read(tablesRefreshProvider.notifier).state++; // 👈 notify POS
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateStatus(String tableId, TableStatus newStatus) async {
    try {
      await _datasource.updateStatus(tableId, newStatus);
      final updated = state.tables.map((t) {
        if (t.id == tableId) t.status = newStatus;
        return t;
      }).toList();
      state = state.copyWith(tables: updated);
      _ref.read(tablesRefreshProvider.notifier).state++; // 👈 notify POS
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      await _datasource.deleteTable(tableId);
      state = state.copyWith(
        tables: state.tables.where((t) => t.id != tableId).toList(),
      );
      _ref.read(tablesRefreshProvider.notifier).state++; // 👈 notify POS
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────
final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  final datasource = ref.watch(tableDatasourceProvider);
  final branch = ref.watch(branchAuthProvider).branch!;
  return TableNotifier(datasource, branch.branchId, ref); // 👈 ref passed
});