import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/branch_auth_datasource.dart';
import '../../data/model/branch_auth_model.dart';


final branchAuthDatasourceProvider = Provider<BranchAuthDatasource>((ref) {
  return BranchAuthDatasource(Supabase.instance.client);
});

class BranchAuthState {
  final BranchAuthModel? branch;
  final bool isLoading;
  final String? errorMessage;

  const BranchAuthState({
    this.branch,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => branch != null;

  BranchAuthState copyWith({
    BranchAuthModel? branch,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearBranch = false,
  }) {
    return BranchAuthState(
      branch: clearBranch ? null : branch ?? this.branch,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class BranchAuthNotifier extends StateNotifier<BranchAuthState> {
  final BranchAuthDatasource _datasource;

  BranchAuthNotifier(this._datasource) : super(const BranchAuthState()) {
    _loadSavedBranch();
  }

  Future<void> _loadSavedBranch() async {
    state = state.copyWith(isLoading: true);
    try {
      final branch = await _datasource.getSavedBranch();
      state = state.copyWith(branch: branch, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final branch = await _datasource.login(
        email: email,
        password: password,
      );
      state = state.copyWith(branch: branch, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _datasource.logout();
    state = state.copyWith(clearBranch: true, clearError: true);
  }
}

final branchAuthProvider =
StateNotifierProvider<BranchAuthNotifier, BranchAuthState>((ref) {
  final datasource = ref.watch(branchAuthDatasourceProvider);
  return BranchAuthNotifier(datasource);
});